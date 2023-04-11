import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:senior_project_0822/sensor.dart';

import '../my_sensor_card.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({Key? key, required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  double? indicatorValue;
  Timer? timer;
  DateTime now = DateTime.now();
  var weekday = [" ","星期一","星期二","星期三","星期四","星期五","星期六","星期日"];

  String time() {
    return "${DateTime.now().hour < 10 ?
    "0${DateTime.now().hour}" : DateTime.now().hour} : ${DateTime.now().minute < 10 ?
    "0${DateTime.now().minute}" : DateTime.now().minute} : ${DateTime.now().second < 10 ?
    "0${DateTime.now().second}" : DateTime.now().second} ";
  }

  updateSeconds() {
    timer = Timer.periodic(
      Duration(seconds: 1),
        (Timer timer) => setState(() {
          indicatorValue = DateTime.now().second / 60;
        })
    );
  }

  final user = FirebaseFirestore.instance.collection('users').doc('data');
  final record = FirebaseFirestore.instance.collection('record');
  BluetoothConnection? connection;
  final sensorRef =
      FirebaseFirestore.instance.collection('users').withConverter<Sensor>(
            fromFirestore: (snapshots, _) => Sensor.fromJson(snapshots.data()!),
            toFirestore: (movie, _) => movie.toJson(),
          );

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    indicatorValue = DateTime.now().second / 60;
    updateSeconds();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    timer!.cancel();
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = widget.server.name ?? "Unknown";
    String timestamp = "${now.year.toString()}-"
        "${now.month.toString().padLeft(2,'0')}-"
        "${now.day.toString().padLeft(2,'0')} ${weekday[now.weekday]}";

    return Scaffold(
      appBar: AppBar(
        title: (isConnecting
            ? Text('連線中 ' + serverName + '...')
            : Text('已連線 ' + serverName)),
        backgroundColor: Color(0xFFEAC100),
      ),
      body: StreamBuilder<QuerySnapshot<Sensor>>(
        stream: sensorRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.requireData;

          return Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 30),
            child: CustomScrollView(slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            child: Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          Container(
                            child: Text(
                              time(),
                              style: TextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h,),
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MySensorCard(
                                  value: data.docs.first.data().humidity,
                                  unit: '%',
                                  name: '濕度',
                                  assetImage: AssetImage(
                                    'assets/images/humidity_icon.png',
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                MySensorCard(
                                  value: data.docs.first.data().temperature,
                                  unit: '\'C',
                                  name: '溫度',
                                  assetImage: AssetImage(
                                    'assets/images/temperature_icon.png',
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    String timestamp = "${now.year.toString()}-"
        "${now.month.toString().padLeft(2,'0')}-"
        "${now.day.toString().padLeft(2,'0')} ${weekday[now.weekday]} ";
    user.update({
      'temperature': double.parse(dataString.substring(0, 5)),
      'humidity': double.parse(dataString.substring(5, 12))
    }).then((value) => print('update data successful'));

    record.doc(timestamp + time()).set({
      'temperature': double.parse(dataString.substring(0, 5)),
      'humidity': double.parse(dataString.substring(5, 12))
    }).then((value) => print('add data successful'));
  }
}
