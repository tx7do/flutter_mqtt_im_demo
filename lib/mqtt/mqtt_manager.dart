import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_mqtt_im_demo/utils/platform.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

import 'package:flutter_mqtt_im_demo/mqtt/mqtt_app_state.dart';

class MQTTManager {
  final MQTTAppState _currentState;

  late final MqttClient? _client;

  final String _identifier;
  final String _host;
  final String _topic;

  // 构造函数
  MQTTManager({required String host, required String topic, required String identifier, required MQTTAppState state})
      : _identifier = identifier,
        _host = host,
        _topic = topic,
        _currentState = state;

  void initializeMQTTClient() {
    if (kDebugMode) {
      print('$_host, $_identifier');
    }

    if (PlatformUtils.isWeb) {
      createBrowserClient();
    } else {
      createServerClient();
    }

    initClient();

    if (kDebugMode) {
      print('****************************');
    }
  }

  void initClient() {
    /// 断开连接回调
    _client?.onDisconnected = onDisconnected;

    /// 连接成功回调
    _client?.onConnected = onConnected;

    ///
    _client?.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    if (kDebugMode) {
      print('MQTT 服务器连接中...');
    }
    _client?.connectionMessage = connMess;
  }

  /// 创建浏览器客户端
  void createBrowserClient() {
    final client = MqttBrowserClient("wss://$_host", _identifier);
    _client = client;

    /// 记录日志
    client.logging(on: true);

    /// 设置端口
    client.port = 8081;

    /// Set the correct MQTT protocol
    client.setProtocolV311();

    client.keepAlivePeriod = 20;

    client.connectTimeoutPeriod = 2000; // milliseconds

    client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
  }

  /// 创建客户端
  void createServerClient() {
    final client = MqttServerClient(_host, _identifier);
    _client = client;

    /// 记录日志
    client.logging(on: true);

    client.secure = false;

    /// 设置端口
    client.port = 1883;

    client.keepAlivePeriod = 20;

    client.connectTimeoutPeriod = 2000; // milliseconds
  }

  // Connect to the host
  void connect() async {
    assert(_client != null);
    try {
      if (kDebugMode) {
        print('MQTT 服务器连接中...');
      }
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      await _client?.connect();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('MQTT 服务器报错 - $e');
      }
      disconnect();
    }
  }

  void disconnect() {
    if (kDebugMode) {
      print('Disconnected');
    }
    _client?.disconnect();
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client?.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    if (kDebugMode) {
      print('正在订阅主题： $topic');
    }
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    if (kDebugMode) {
      print('MQTT 服务器断开');
    }
    if (_client?.connectionStatus?.returnCode == MqttConnectReturnCode.noneSpecified) {
      if (kDebugMode) {
        print("MQTT服务器断开回调");
      }
    }
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
  }

  /// 连接成功回调
  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    if (kDebugMode) {
      print('MQTT 服务器连接成功！');
    }
    _client?.subscribe(_topic, MqttQos.atLeastOnce);
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _currentState.setReceivedText(pt);
      if (kDebugMode) {
        print('订阅主题是：<${c[0].topic}>,消息是： <-- $pt -->');
        print('');
      }
    });
  }
}
