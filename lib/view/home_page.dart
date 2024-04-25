import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mqtt_im_demo/mqtt/mqtt_app_state.dart';
import 'package:flutter_mqtt_im_demo/mqtt/mqtt_manager.dart';
import 'package:flutter_mqtt_im_demo/view/chat_page.dart';
import 'package:flutter_mqtt_im_demo/widget/argon_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  String _community = "";
  String _userName = "";

  late MQTTAppState currentAppState;
  late MQTTManager manager;

  final TextEditingController _communityController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MQTTAppState appState = Provider.of<MQTTAppState>(context);
    // Keep a reference to the app state.
    currentAppState = appState;
    ScreenUtil.init(context, designSize: const Size(751, 1334));

    _prepareStateMessageFrom(currentAppState.getAppConnectionState);
    // TODO: implement build
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              "assets/image/3.jpg",
              fit: BoxFit.cover,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.white.withOpacity(0.1),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Container(
              margin: EdgeInsets.only(top: 250.h),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 120.w,
                    child: Image.asset("assets/image/1.png"),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 100.h),
                    width: 600.w,
                    child: TextField(
                      controller: _communityController,
                      keyboardAppearance: Brightness.light,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
                        labelText: "Community Name",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 100.h),
                    width: 600.w,
                    child: TextField(
                      controller: _userNameController,
                      keyboardAppearance: Brightness.light,
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.only(left: 0, bottom: 0, top: 0, right: 0),
                        labelText: "User Name",
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 400.h),
                    child: ArgonButton(
                      height: 50,
                      roundLoadingShape: true,
                      width: MediaQuery.of(context).size.width * 0.45,
                      onTap: (startLoading, stopLoading, btnState) {
                        if (btnState == ButtonState.Idle) {
                          if (_checkInfo()) {
                            startLoading();
                            _connectMQTT();
                          }
                        } else {
                          stopLoading();
                        }
                      },
                      loader: Container(
                        padding: const EdgeInsets.all(10),
                        child: const CircularProgressIndicator(),
                      ),
                      borderRadius: 5.0,
                      color: Colors.white,
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  _prepareStateMessageFrom(MQTTAppConnectionState state) {
    switch (state) {
      case MQTTAppConnectionState.connected:
        debugPrint("MQTT Connected");
        Future.delayed(const Duration(milliseconds: 200)).then((e) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
            return ChangeNotifierProvider<MQTTAppState>.value(
              value: currentAppState,
              child: ChatPage(
                mqttManager: manager,
                community: _community,
                userName: _userName,
              ),
            );
          }));
        });
        break;
      case MQTTAppConnectionState.connecting:
        debugPrint("MQTT Connecting");
        break;
      case MQTTAppConnectionState.disconnected:
        debugPrint("MQTT Disconnected");
        break;
    }
  }

  bool _checkInfo() {
    _community = _communityController.text;
    _userName = _userNameController.text;

    if (_community != "" && _userName != "") {
      return true;
    } else {
      if (_community == "") {
        Fluttertoast.showToast(
            msg: "请输入社区名称", gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.white38);
      } else {
        Fluttertoast.showToast(
            msg: "请输入用户名", gravity: ToastGravity.TOP, toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.white38);
      }
      return false;
    }
  }

  _connectMQTT() {
    manager = MQTTManager(
        host: "test.mosquitto.org", topic: "flutter/amp/cool", identifier: _userName, state: currentAppState);
    manager.initializeMQTTClient();
    manager.connect();
  }
}
