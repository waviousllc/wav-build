"""
* Copyright (c) 2019 Memfault, Inc.
*
* Significant portions of this code has been copied from:
* https://github.com/memfault/interrupt/tree/master/example/fwup-architecture
*
* Some modifications have been made by Wavious, LLC.
*
* SPDX-License-Identifier: MIT
"""

import argparse
import binascii
import os
import struct
import subprocess

def process_binary_payload(bin_filename):
    """
    Patch crc & data_size fields of image_hdr_t in place in binary

    Raise exception if binary is not a supported type
    """
    IMAGE_HDR_SIZE_FIXED_BYTES = 19 # Fixed starting 19 bytes
    IMAGE_HDR_SIZE_GIT_BYTES = 10   # Trailing 10 bytes
    IMAGE_HDR_MAGIC = 0xC0FE
    IMAGE_HDR_VERSION = 1

    with open(bin_filename, "rb") as f:
        image_hdr = f.read(IMAGE_HDR_SIZE_FIXED_BYTES)
        data = f.read()

    image_magic, image_hdr_version = struct.unpack("<HH", image_hdr[0:4])

    if image_magic != IMAGE_HDR_MAGIC:
        raise Exception(
            "Unsupported Binary Type. Expected 0x{:02x} Got 0x{:02x}".format(
                IMAGE_HDR_MAGIC, image_magic
            )
        )

    if image_hdr_version != IMAGE_HDR_VERSION:
        raise Exception(
            "Unsupported Image Header Version. Expected 0x{:02x} Got 0x{:02x}".format(
                IMAGE_HDR_VERSION, image_hdr_version
            )
        )

    # Determine full header size based on vector_size
    vector_size = struct.unpack("<B", image_hdr[-1])

    if (vector_size != 0x4 or vector_size != 0x8):
        raise Exception(
            "Vector Size is incorrect. Expected 0x4 or 0x8. Got 0x{:02x}".format(
                vector_size
            )
        )

    # Chop off data based on vector_size + fixed git header size
    data = data[vector_size + IMAGE_HDR_SIZE_GIT_BYTES::]
    data_size = len(data)
    crc32 = binascii.crc32(data) & 0xffffffff
    return data_size, crc32


def main(elf_filename, prefix):
    """
    1. Convert ELF to binary
    2. Determine size and CRC
    3. Patch ELF file
    """
    OBJCOPY = "objcopy"
    GDB = "gdb"
    TMP_FILENAME = elf_filename + ".tmp.bin"

    if prefix:
        OBJCOPY = "{}-{}".format(prefix, OBJCOPY)
        GDB = "{}-{}".format(prefix, GDB)

    with open(os.devnull, 'w') as devnull:

        # Create binary file
        subprocess.call([OBJCOPY, elf_filename, "-O", "binary", TMP_FILENAME],
                        shell=False,
                        stderr=devnull,
                        stdout=devnull)

        # Process file
        data_size, crc32 = process_binary_payload(TMP_FILENAME)

        # Delete file
        os.remove(TMP_FILENAME)

        # Patch elf file
        subprocess.call([
                            GDB,
                            "--write",
                            "-ex",
                            "set image_hdr.data_size={}".format(data_size),
                            "-ex",
                            "set image_hdr.crc={}".format(crc32),
                            "-ex",
                            "q",
                            elf_filename
                        ],
                        stderr=devnull,
                        stdout=devnull)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Patches Wavious Image Header in ELF file", formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("elf", action="store")
    parser.add_argument("--prefix", action="store")
    args = parser.parse_args()
    main(args.elf, args.prefix)
