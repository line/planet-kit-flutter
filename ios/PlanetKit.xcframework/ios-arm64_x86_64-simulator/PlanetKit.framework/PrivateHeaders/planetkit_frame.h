/**
 * @file planetkit_frame.h
 * @brief write some brief information here.
 *
 * @date 2022-06-14
 *
 *
 */

#ifndef __PLANETKIT_FRAME_H__
#define __PLANETKIT_FRAME_H__


/*************************************************************************
* INCLUDE
*************************************************************************/
#include "planetkit_common_type.h"

#if defined(__cplusplus)
extern "C" {
#endif
/*************************************************************************
* DATA STRUCTURE
*************************************************************************/

/*************************************************************************
* API DEFINITION
*************************************************************************/

kit_bool_t          planetkit_frame_retain(planetkit_frame_t *NONNULL frame);
void                planetkit_frame_release(planetkit_frame_t *NONNULL frame);

uint8_t * NONNULL   planetkit_frame_get_data(planetkit_frame_t *NONNULL frame);
uint64_t            planetkit_frame_get_data_size(planetkit_frame_t *NONNULL frame);

#if defined(__cplusplus)
}
#endif
#endif /* __PLANETKIT_FRAME_H__ */
