//
//  PlanetKitVideoFormatConverter.h
//  PlanetKit+iOS
//
//  Created by LINER on 2020/08/24.
//  Copyright © 2020 LINE Plus Corp. All rights reserved.
//

#ifndef PlanetKitVideoFormatConverter_h
#define PlanetKitVideoFormatConverter_h
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface PlanetKitVideoFormatConverter : NSObject

+ (BOOL)convert:(CVPixelBufferRef)src to:(CVPixelBufferRef)dst;
+ (BOOL)convert:(void *)srcI420 withWidth:(int)width withHeight:(int)height to:(CVPixelBufferRef)dst;
+ (BOOL)convert:(CVPixelBufferRef)src to:(void *)srcI420 withWidth:(int)width withHeight:(int)height;
//+ (BOOL)scale:(CVPixelBufferRef)src to:(CVPixelBufferRef)dst;
@end
#endif /* PlanetKitVideoFormatConverter_h */
