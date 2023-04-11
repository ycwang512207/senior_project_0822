import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:senior_project_0822/screen/sign_in_screen.dart';
import 'package:senior_project_0822/screen/splash_page.dart';


void main() {
  runApp(MyApp());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 3)),
      builder: (context, AsyncSnapshot snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return MaterialApp(
            title: '倉鼠智能管家',
            debugShowCheckedModeBanner: false,
            home: SplashPage(),
          );
        }
        else{
          return ScreenUtilInit(
            designSize: const Size(414, 815),
            builder: (context, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: '倉鼠智能管家',
                theme: new ThemeData(
                    scaffoldBackgroundColor: Color(0xFFFFFAF4)
                ),
                home: SignInScreen(),
              );
            },
          );
        }
      },
    );
  }
}


