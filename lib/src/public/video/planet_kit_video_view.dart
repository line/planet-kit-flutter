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

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A builder class for creating [PlanetKitVideoView] instances.
class PlanetKitVideoViewBuilder {
  PlanetKitVideoViewBuilder._privateConstructor();

  /// The single instance of [PlanetKitVideoViewBuilder].
  static final PlanetKitVideoViewBuilder instance =
      PlanetKitVideoViewBuilder._privateConstructor();

  /// Creates a [PlanetKitVideoView] with the specified [scaleType].
  PlanetKitVideoView create(PlanetKitViewScaleType scaleType) {
    return PlanetKitVideoView(scaleType: scaleType);
  }
}

/// Enum representing the scale type for the video view.
enum PlanetKitViewScaleType {
  /// Scale the video to fill the view, cropping if necessary.
  centerCrop,

  /// Scale the video to fit within the view, maintaining aspect ratio.
  fitCenter
}

/// A widget that displays a video view within the PlanetKit framework.
class PlanetKitVideoView extends StatefulWidget {
  /// The scale type for the video view.
  final PlanetKitViewScaleType scaleType;

  /// Constructs a [PlanetKitVideoView] with the specified [scaleType].
  PlanetKitVideoView({super.key, required this.scaleType});

  /// The unique identifier for the video view.
  String? id;

  /// A stream that emits the view ID when the platform view is created.
  Stream<String> get onCreate => _onCreateController.stream;

  /// A stream that emits the view ID when the platform view is disposed.
  Stream<String> get onDispose => _onDisposeController.stream;

  final StreamController<String> _onCreateController =
      StreamController<String>.broadcast();
  final StreamController<String> _onDisposeController =
      StreamController<String>.broadcast();

  @override
  PlanetKitVideoViewState createState() => PlanetKitVideoViewState();
}

/// The state for the [PlanetKitVideoView] widget.
class PlanetKitVideoViewState extends State<PlanetKitVideoView> {
  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{
      'scaleType': widget.scaleType
          .toString()
          .split('.')
          .last, // Pass the scaleType as a string
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'planet_kit_video_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'planet_kit_video_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return const Text('Unsupported Platform');
    }
  }

  @override
  void dispose() {
    if (widget.id != null) {
      widget._onDisposeController.add(widget.id!);
    }

    widget._onCreateController.close();
    widget._onDisposeController.close();
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final stringId = id.toString();
    widget.id = stringId;
    widget._onCreateController.add(stringId);
  }
}
