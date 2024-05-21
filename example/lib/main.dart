// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:planet_kit_flutter/planet_kit_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _planetKitManager = PlanetKitManager.instance;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _planetKitManager.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    await initializePlanetKit();
    await requestPermissions();

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initializePlanetKit() async {
    const logLevel = PlanetKitLogLevel.simple;
    const logSizeLimit = PlanetKitLogSizeLimit.medium;
    final logSetting = PlanetKitLogSetting(
        enabled: true, logLevel: logLevel, logSizeLimit: logSizeLimit);
    const serverUrl = "";
    final initParam =
        PlanetKitInitParam(serverUrl: serverUrl, logSetting: logSetting);
    final result = await _planetKitManager.initializePlanetKit(initParam);
    print("planetkit initialize result $result");
  }

  Future<void> requestPermissions() async {
    final status = await [Permission.microphone, Permission.phone].request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
