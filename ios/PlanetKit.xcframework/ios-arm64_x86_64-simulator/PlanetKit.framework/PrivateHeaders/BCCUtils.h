// Copyright 2015 LINE Plus Corporation
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

static NSString *const BCCUtilsKeyWWANSent = @"WWANSent";
static NSString *const BCCUtilsKeyWWANReceived = @"WWANReceived";
static NSString *const BCCUtilsKeyWiFiSent = @"WiFiSent";
static NSString *const BCCUtilsKeyWiFiReceived = @"WiFiReceived";

@interface BCCHardware: NSObject
@property (strong, nonatomic) NSString* name;
@property (assign, nonatomic) NSInteger major;
@property (assign, nonatomic) NSInteger minor;
@end


@interface BCCUtils: NSObject

+ (BCCUtils *)sharedInstance NS_SWIFT_NAME(shared());

- (Float32)getCpuUsage;
- (uint64_t)getMemoryUsage;
- (NSDictionary*)getNetworkUsage;

// Get device model name
+ (NSString*)platform;
+ (BCCHardware*)platformInfo;

+ (uint64_t)getTickCount;

@end
