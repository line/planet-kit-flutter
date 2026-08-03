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

/// Detailed version information about the running PlanetKit stack.
///
/// Obtain it via [PlanetKitManager.getVersionInfo]. This is intended to be
/// surfaced in a debug/about screen so testers and developers can confirm
/// exactly which versions are in use.
class PlanetKitVersionInfo {
  /// The version of the native PlanetKit SDK
  /// (`PlanetKitManager.shared.version` on iOS, `PlanetKit.version` on Android).
  final String sdkVersion;

  /// The version of the PlanetKit Flutter plugin wrapper.
  final String pluginVersion;

  /// The SDK user agent string.
  ///
  /// Only available after [PlanetKitManager.initializePlanetKit] has been
  /// called; `null` before initialization (and on platforms that do not expose
  /// it).
  final String? userAgent;

  /// Creates a [PlanetKitVersionInfo].
  const PlanetKitVersionInfo({
    required this.sdkVersion,
    required this.pluginVersion,
    this.userAgent,
  });

  /// Creates a [PlanetKitVersionInfo] from the platform JSON map.
  factory PlanetKitVersionInfo.fromJson(Map<String, dynamic> json) {
    final userAgent = json['userAgent'] as String?;
    return PlanetKitVersionInfo(
      sdkVersion: json['sdkVersion'] as String? ?? '',
      pluginVersion: json['pluginVersion'] as String? ?? '',
      userAgent: (userAgent != null && userAgent.isNotEmpty) ? userAgent : null,
    );
  }

  @override
  String toString() =>
      'PlanetKitVersionInfo(sdkVersion: $sdkVersion, pluginVersion: $pluginVersion, userAgent: $userAgent)';
}
