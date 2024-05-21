//
//  PlanetKitAudioMixer.h
//  PlanetKit
//
//  Created by LINER on 2020/03/16.
//  Copyright © 2020 LINE Corp. All rights reserved.
//

#ifndef PlanetKitAudioMixer_h
#define PlanetKitAudioMixer_h
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>


@class PlanetKitAudioMixerNode;


@protocol PlanetKitAudioMixerNodeDelegate <NSObject>

- (void)audioMixerNodeDidResetUnit:(PlanetKitAudioMixerNode *)aNode;

@end


@interface PlanetKitAudioMixerNode : NSObject

@property(nonatomic, weak)     id<PlanetKitAudioMixerNodeDelegate>  delegate;
@property(nonatomic, readonly) AudioUnit                            unit;

@end


@interface PlanetKitAudioMixer : NSObject


@property(nonatomic, readonly) AUNode    node;
@property(nonatomic, readonly) AudioUnit unit;


- (OSStatus)setupWithGraph:(AUGraph)aGraph busCount:(UInt32)aBusCount;
- (void)dispose;
- (void)start;


- (PlanetKitAudioMixerNode *)dequeueNodeWithType:(OSType)aType subType:(OSType)aSubType;
- (void)reclaimNode:(PlanetKitAudioMixerNode *)aNode;


- (void)setVolume:(float)aVolume forNode:(PlanetKitAudioMixerNode *)aNode;


@end


#endif /* PlanetKitAudioMixer_h */
