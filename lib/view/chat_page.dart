import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mqtt_im_demo/utils/platform.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mqtt_im_demo/mqtt/mqtt_app_state.dart';
import 'package:flutter_mqtt_im_demo/mqtt/mqtt_manager.dart';

class ChatModel {
  late bool isMineMessage;
  late String user;
  late String message;
}

class ChatPage extends StatefulWidget {
  final String? community;
  final String? userName;
  final MQTTManager? mqttManager;

  const ChatPage({super.key, this.community, this.mqttManager, this.userName});

  @override
  ChatPageState createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  List<ChatModel> chatHistoryList = [];

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
    // TODO: implement build
    return Scaffold(
      backgroundColor: const Color.fromRGBO(240, 240, 240, 1),
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.white38,
        title: Text(
          widget.community!,
          style: const TextStyle(color: Colors.black),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Consumer<MQTTAppState>(
        builder: (context, appState, widget) {
          debugPrint("此时appState:${appState.getAppConnectionState}");
          return ListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            children: <Widget>[
              _buildScrollableTextWith(appState.getReceivedText),
              _bottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
        margin: EdgeInsets.only(left: 25.w),
        width: 700.w,
        child: Stack(
          children: <Widget>[
            TextField(
              style: TextStyle(fontSize: 35.sp),
              controller: _messageController,
              decoration: const InputDecoration(focusColor: Colors.cyan),
            ),
            Container(
              margin: EdgeInsets.only(left: 600.w),
              child: IconButton(
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusScopeNode());
                  _publishMessage(_messageController.text);
                  debugPrint("发送消息");
                },
                icon: const Icon(
                  Icons.send,
                  color: Colors.cyan,
                ),
              ),
            )
          ],
        ));
  }

  Widget _buildScrollableTextWith(String text) {
    debugPrint("收到的消息是：${text.toString()}");
    List chatMainMessage = text.split("@:");
    if (chatMainMessage.length > 1) {
      if (chatMainMessage[0] == widget.userName) {
        ChatModel chatModel = ChatModel();
        chatModel.isMineMessage = true;
        chatModel.user = chatMainMessage[0].toString();
        chatModel.message = chatMainMessage[1].toString();
        chatHistoryList.add(chatModel);
      } else {
        ChatModel chatModel = ChatModel();
        chatModel.isMineMessage = false;
        chatModel.message = chatMainMessage[1].toString();
        chatHistoryList.add(chatModel);
      }
    }
    return SizedBox(
      width: 800.w,
      height: 1000.h,
      child: ListView.builder(
        itemCount: chatHistoryList.length,
        itemBuilder: (context, index) {
          return chatMainMessage.length > 1 ? _messageLine(index) : const SizedBox();
        },
      ),
    );
  }

  Widget _messageLine(int i) {
    return chatHistoryList[i].isMineMessage
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 20.w, right: 20.w),
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(169, 232, 122, 1), borderRadius: BorderRadius.all(Radius.circular(5.0))),
                height: 70.h,
                margin: EdgeInsets.only(top: 20.h),
                child: Center(
                  child: Text(
                    chatHistoryList[i].message,
                    style: TextStyle(fontSize: 32.sp),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20.h, left: 40.w, right: 40.w),
                decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                height: 70.h,
                width: 70.h,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Image.asset(
                      PlatformUtils.isIOS ? "assets/image/icon_2.JPG" : "assets/image/icon_1.JPG",
                      fit: BoxFit.contain,
                    )),
              )
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 20.h, left: 40.w, right: 40.w),
                decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                height: 70.h,
                width: 70.h,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Image.asset(
                      Platform.isIOS ? "assets/image/icon_1.JPG" : "assets/image/icon_2.JPG",
                      fit: BoxFit.contain,
                    )),
              ),
              Container(
                padding: EdgeInsets.only(left: 20.w, right: 20.w),
                decoration:
                    const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(5.0))),
                height: 70.h,
                margin: EdgeInsets.only(top: 20.h),
                child: Center(
                  child: Text(
                    chatHistoryList[i].message,
                    style: TextStyle(fontSize: 32.sp),
                  ),
                ),
              ),
            ],
          );
  }

  void _publishMessage(String text) {
    String? osPrefix = widget.userName;
    final String message = '${osPrefix!}@:$text';
    widget.mqttManager?.publish(message);
    _messageController.clear();
  }
}
