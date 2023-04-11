import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({
    required BluetoothDevice device,
    GestureTapCallback? onTap,
    bool enabled = true,
  }) : super(
    onTap: onTap,
    enabled: enabled,
    leading: Icon(Icons.devices),
    title: Text(device.name ?? ""),
    subtitle: Text(device.address.toString()),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        device.isConnected
            ? Icon(Icons.import_export)
            : Container(width: 0, height: 0),
        device.isBonded
            ? Icon(Icons.link)
            : Container(width: 0, height: 0),
      ],
    ),
  );
}