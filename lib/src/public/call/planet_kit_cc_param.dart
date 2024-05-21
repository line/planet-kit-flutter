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

import 'package:json_annotation/json_annotation.dart';
import '../../internal/planet_kit_platform_interface.dart';
import '../../internal/planet_kit_platform_resource_manager.dart';
part 'planet_kit_cc_param.g.dart';

@JsonSerializable(explicitToJson: true, constructor: "_PlanetKitCcParam")
class PlanetKitCcParam {
  static Future<PlanetKitCcParam?> createCcParam(String ccParam) async {
    final result = await Platform.instance.createCcParam(ccParam);
    if (result == null) {
      print("#cc_param failed to create cc_param");
      return null;
    }
    return PlanetKitCcParam._PlanetKitCcParam(id: result);
  }

  final String id;

  PlanetKitCcParam._PlanetKitCcParam({required this.id}) {
    NativeResourceManager.instance.add(this, id);
  }

  Map<String, dynamic> toJson() => _$PlanetKitCcParamToJson(this);
  factory PlanetKitCcParam.fromJson(Map<String, dynamic> json) =>
      _$PlanetKitCcParamFromJson(json);
}
