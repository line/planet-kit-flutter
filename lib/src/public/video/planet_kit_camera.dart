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

import 'package:planet_kit_flutter/src/internal/planet_kit_platform_interface.dart';

/// A singleton class that manages camera operations within the PlanetKit framework.
class PlanetKitCamera {
  PlanetKitCamera._privateConstructor();

  /// The single instance of [PlanetKitCamera].
  static final PlanetKitCamera instance = PlanetKitCamera._privateConstructor();

  /// Starts the camera preview on the specified view.
  ///
  /// [viewId] is the identifier of the view where the camera preview will be displayed.
  /// Returns `true` if the preview starts successfully, otherwise `false`.
  Future<bool> startPreview(String viewId) async {
    return await Platform.instance.cameraInterface.startPreview(viewId);
  }

  /// Stops the camera preview on the specified view.
  ///
  /// [viewId] is the identifier of the view where the camera preview is currently displayed.
  /// Returns `true` if the preview stops successfully, otherwise `false`.
  Future<bool> stopPreview(String viewId) async {
    return await Platform.instance.cameraInterface.stopPreview(viewId);
  }

  /// Switches the camera position between front and back.
  ///
  /// Returns `true` if the camera position switches successfully, otherwise `false`.
  Future<bool> switchCameraPosition() async {
    return await Platform.instance.cameraInterface.switchPosition();
  }

  /// Clears the virtual background.
  ///
  /// Returns `true` if the virtual background is cleared successfully, otherwise `false`.
  Future<bool> clearVirtualBackground() async {
    return await Platform.instance.cameraInterface.clearVirtualBackground();
  }

  /// Sets a virtual background with a blur effect.
  ///
  /// [radius] is the radius of the blur effect.
  /// Returns `true` if the virtual background is set successfully, otherwise `false`.
  Future<bool> setVirtualBackgroundWithBlur(int radius) async {
    return await Platform.instance.cameraInterface
        .setVirtualBackgroundWithBlur(radius);
  }

  /// Sets a virtual background with an image.
  ///
  /// [fileUri] is the URI of the image file to be used as the virtual background.
  /// Returns `true` if the virtual background is set successfully, otherwise `false`.
  Future<bool> setVirtualBackgroundWithImage(String fileUri) async {
    return await Platform.instance.cameraInterface
        .setVirtualBackgroundWithImage(fileUri);
  }
}