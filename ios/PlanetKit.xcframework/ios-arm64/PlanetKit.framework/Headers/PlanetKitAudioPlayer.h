//
//  PlanetKitAudioPlayer.h
//  PlanetKit
//
//  Created by LINER on 2020/03/16.
//  Copyright © 2020 LINE Corp. All rights reserved.
//

#ifndef PlanetKitAudioPlayer_h
#define PlanetKitAudioPlayer_h

#import <Foundation/Foundation.h>


@class    PlanetKitAudioMixer;
@protocol PlanetKitAudioMixHandle;

@protocol PlanetAudioPlayerDelegate <NSObject>

- (void)playDidFinish:(NSString *)type userData:(int)aUserData;

@end

@interface PlanetKitAudioPlayer : NSObject


@property(nonatomic, retain)                       PlanetKitAudioMixer *mixer;
@property(nonatomic, assign, getter=isInterrupted) BOOL           interrupted;
@property(nonatomic, assign)   id<PlanetAudioPlayerDelegate>        playerDelegate;

- (BOOL)playWithRequest:(NSURLRequest *)aRequest loopCount:(int)aLoopCount type:(NSString *)aType enabled:(BOOL)aEnabled userData:(int)aUserData;

- (void)stopPlayingWithType:(NSString *)aType;
- (void)stopAllWithCompletion:(void (^)(void))aCompletion;

- (void)setMixer:(PlanetKitAudioMixer *)mixer;
- (void)setVolume:(float)volume;
@end

#endif /* PlanetKitAudioPlayer_h */
