//
//  planetkit_clog.h
//  PlanetKit
//
//  Created by LINER on 2022/04/11.
//  Copyright © 2022 LINE Corp. All rights reserved.
//

#ifndef __planetkit_clog_h
#define __planetkit_clog_h

#if defined(__cplusplus)
extern "C" {
#endif


enum planetkit_clog_level: int32_t {
    PLANETKIT_CLOG_INFO = 5,
    PLANETKIT_CLOG_VITAL = 4,
    PLANETKIT_CLOG_ERROR = 2,
    PLANETKIT_CLOG_CRITICAL = 1,
    PLANETKIT_CLOG_NONE = 0,
};

struct planetkit_clog {
    enum planetkit_clog_level level;
};

extern struct planetkit_clog kitCLog;


#if defined(__cplusplus)
}
#endif
#endif /* __planetkit_clog_h */
