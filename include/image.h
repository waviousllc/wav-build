/**
 * Copyright (c) 2019 Memfault, Inc.
 *
 * Significant portions of this code has been copied from:
 * https://github.com/memfault/interrupt/tree/master/example/fwup-architecture
 *
 * Some modifications have been made by Wavious, LLC.
 *
 * SPDX-License-Identifier: MIT
 */

#ifndef _IMAGE_H_
#define _IMAGE_H_

#include <stdint.h>

#define IMAGE_MAGIC (0xC0FE)

/**
 * @brief   Image Type Enumeration
 *
 * @details Supported types of images.
 *
 * BOOTLOADER   bootloader image. Loads application(s).
 * APP          standard application image.
 */
typedef enum
{
    IMAGE_TYPE_BOOTLOADER,
    IMAGE_TYPE_APP,
} image_type_t;

/**
 * @brief   Image Header Version Enumeration
 *
 * @details Types of image headers that are currently supported.
 *
 * IMAGE_VERSION_1          The first version of the image header.
 * IMAGE_VERSION_CURRENT    The current version that is supported.
 */
typedef enum
{
    IMAGE_VERSION_1 = 1,
    IMAGE_VERSION_CURRENT = IMAGE_VERSION_1,
} image_version_t;

/**
 * @brief   Image Device Identifier Enumeration
 *
 * @details Indicates the device that can execute the image.
 *
 * HOST     Host identifier.
 * WDDR     Wavious LPDDR identifier.
 * WLP      Wavious LPDDR Chiplet identifier.
 * WTM      Wavious Template Module identifier.
 */
typedef enum
{
    IMAGE_DEVICE_ID_HOST = 1,
    IMAGE_DEVICE_ID_WDDR,
    IMAGE_DEVICE_ID_WLP,
    IMAGE_DEVICE_ID_WTM,
} image_device_id_t;

/**
 * @brief   Wavious Image Header Structure
 *
 * @details Header used at beginning of all Wavious Softwre Images.
 *          This header contains metadata information about the image
 *          that can be used to validate and identify images that are
 *          in use.
 *
 * image_magic          Magic header that indicates that the image is valid.
 * image_hdr_version    The version of this header. Used for identifying
 *                      different image header formats.
 * crc                  Cyclic redundancy check for validating integrity of
 *                      the image. The CRC is computed over the image, not
 *                      including the header.
 * data_size            The size of the image (not including this header).
 * image_type           The type of this image. Used for indentifying different
 *                      image types.
 * version_major        Major version of the image.
 * version_minor        Minor version of the image.
 * version_patch        Patch version of the image.
 * vector_addr          Start address of where image expects to begin execution.
 * device_id            The identifier of the device that can execute this
 *                      image.
 * git_dirty            Flag to indicate if commit that generated this build
 *                      is dirty.
 * git_ahead            Distance (in commits) that commit that generated this
 *                      image is from semantic version tag.
 * git_sha              SHA of Git commit that generated this image.
 */

typedef struct image_header_t
{
    uint16_t image_magic;
    uint16_t image_hdr_version;
    uint32_t crc;
    uint32_t data_size;
    uint8_t image_type;
    uint8_t version_major;
    uint8_t version_minor;
    uint8_t version_patch;
    uint32_t vector_addr;
    uint16_t device_id;
    uint8_t git_dirty;
    uint8_t git_ahead;
    char git_sha[8];
} __attribute__((packed)) img_hdr_t;

#endif /* _IMAGE_H_ */
