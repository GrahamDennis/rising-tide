/** @file
 *  @brief MAVLink comm protocol generated from example.xml
 *  @see http://mavlink.org
 */
#pragma once
#ifndef MAVLINK_EXAMPLE_H
#define MAVLINK_EXAMPLE_H

#ifndef MAVLINK_H
    #error Wrong include order: MAVLINK_EXAMPLE.H MUST NOT BE DIRECTLY USED. Include mavlink.h from the same directory instead or set ALL AND EVERY defines from MAVLINK.H manually accordingly, including the #define MAVLINK_H call.
#endif

#define MAVLINK_EXAMPLE_XML_HASH -3505334498056079899

#ifdef __cplusplus
extern "C" {
#endif

// MESSAGE LENGTHS AND CRCS

#ifndef MAVLINK_MESSAGE_LENGTHS
#define MAVLINK_MESSAGE_LENGTHS {}
#endif

#ifndef MAVLINK_MESSAGE_CRCS
#define MAVLINK_MESSAGE_CRCS {{176, 234, 3, 3, 3, 0, 1}}
#endif

#include "../protocol.h"

#define MAVLINK_ENABLED_EXAMPLE

// ENUM DEFINITIONS



// MAVLINK VERSION

#ifndef MAVLINK_VERSION
#define MAVLINK_VERSION 2
#endif

#if (MAVLINK_VERSION == 0)
#undef MAVLINK_VERSION
#define MAVLINK_VERSION 2
#endif

// MESSAGE DEFINITIONS
#include "./mavlink_msg_rally_fetch_point.h"

// base include



#if MAVLINK_EXAMPLE_XML_HASH == MAVLINK_PRIMARY_XML_HASH
# define MAVLINK_MESSAGE_INFO {MAVLINK_MESSAGE_INFO_RALLY_FETCH_POINT}
# define MAVLINK_MESSAGE_NAMES {{ "RALLY_FETCH_POINT", 176 }}
# if MAVLINK_COMMAND_24BIT
#  include "../mavlink_get_info.h"
# endif
#endif

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // MAVLINK_EXAMPLE_H
