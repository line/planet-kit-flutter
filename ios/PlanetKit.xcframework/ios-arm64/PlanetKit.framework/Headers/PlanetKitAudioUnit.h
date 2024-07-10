//
//  PlanetAudioUnit.h
//  Planet
//
//  Created by LINER on 2019/12/17.
//  Copyright © 2019 LINE Plus Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import "PlanetKitAudioMixer.h"


#if !TARGET_OS_IPHONE
CF_ENUM(AudioObjectPropertySelector)
{
    kAudioDevicePropertyTabEnabled = 'tapd',
};
#endif


#if TARGET_OS_IPHONE
#define kPlanetAudioMediaSampleRate        32000
#else
#define kPlanetAudioMediaSampleRate        44100
#endif
#define kMaxFramesPerSlice 4096


#define kPlanetAudioMediaBitsPerChannel    16
#define kPlanetAudioMediaChannelsPerFrame  1

#define kNumMixerInputs    2


@protocol PlanetAudioUnitTargetDelegate <NSObject>

- (int)onFrames:(unsigned int)unitId frameNum:(unsigned int)frameNums format:(AudioStreamBasicDescription *)format timestamp:(const AudioTimeStamp *)timestamp buffer:(void *)aBuffer size:(unsigned int)aBufferSize ;


@end

@protocol PlanetAudioUnitSourceDelegate <NSObject>

- (int)getFrame:(unsigned int)unitId frameNum:(unsigned int)frameNums format:(AudioStreamBasicDescription *)format timestamp:(const AudioTimeStamp *)timestamp buffer:(void *)aBuffer size:(unsigned int)aBufferSize;


@end



@interface PlanetKitAudioUnit: NSObject

@property(nonatomic, assign)   id<PlanetAudioUnitTargetDelegate>    targetOfMic;
@property(nonatomic, assign)   id<PlanetAudioUnitSourceDelegate>    sourceOfSpk;

@property(nonatomic, readonly) NSTimeInterval               inputLatency;
@property(nonatomic, readonly) NSTimeInterval               outputLatency;

@property(nonatomic, readonly)                       AudioUnit audioUnit;
@property(nonatomic, readonly, getter=isInitialized) BOOL      initialized;
@property(nonatomic, readonly, getter=isStarted)     BOOL      started;

@property(nonatomic, assign)   AudioStreamBasicDescription  inputStreamFormat;
@property(nonatomic, assign)   AudioStreamBasicDescription  outputStreamFormat;

#if !TARGET_OS_IPHONE
@property(nonatomic, assign)    AudioDeviceID   inputDeviceId;
@property(nonatomic, assign)    AudioDeviceID   outputDeviceId;
#endif

@property(nonatomic, assign)    Float64         preferredMicSampleRate;
@property(nonatomic, assign)    Float64         preferredSpkSampleRate;

//@property(nonatomic, assign)    UInt32          preferredChannelBits;
//@property(nonatomic, assign)    UInt32          preferredChannels;
@property(nonatomic, assign)    BOOL            voiceProcessingIOEnabled;
@property(nonatomic, assign)    BOOL            micEnabled;
@property(nonatomic, assign)    BOOL            spkEnabled;

@property(nonatomic, assign)    OSStatus        initStatus;

//@property(nonatomic, readonly, getter=isEnableMic) BOOL enableMic;
//@property(nonatomic, readonly, getter=isEnableSpk) BOOL enableSpk;

//- (BOOL)setup:(unsigned int)unitId enableMic:(BOOL)enableMic enableSpk:(BOOL)enableSpk;
- (BOOL)setup;
- (void)dispose;

- (SInt32)start;
- (void)stop;

- (PlanetKitAudioMixer *)outputMixer;

+ (BOOL)isVoiceProcessingAvailable;

#if !TARGET_OS_IPHONE
+ (unsigned int)preferredBufferFrameSizeWithSampleRate:(Float64)aSampleRate;
#endif

@end


@interface PlanetKitAudioVpioInputUnit: PlanetKitAudioUnit

@end


@interface PlanetKitAudioVpioOutputUnit: PlanetKitAudioUnit

@end


@interface PlanetKitAudioInputUnit: PlanetKitAudioUnit

@end


@interface PlanetKitAudioOutputUnit: PlanetKitAudioUnit

@end
