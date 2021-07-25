# Generate Metadata from Git
find_package(GetVersionFromGitTag)

# Build Timestamp
string(TIMESTAMP BUILD_DATE "%d-%m-%Y, %H:%M" UTC )

# Build Machine
cmake_host_system_information(RESULT BUILD_MACHINE QUERY HOSTNAME)

# Ensure Python is installed
find_package(Python REQUIRED)

# Define the python binary
set(IMAGE_PATCH_SCRIPT_PATH ${WAV_BUILD_TOP_LEVEL}/scripts/patch_image_header.py)

# Create a macro that can patch image after its built
macro(patch_image_header TARGET PREFIX WORKING_DIRECTORY)
    add_custom_command(TARGET ${TARGET}
        POST_BUILD
        COMMAND ${Python_EXECUTABLE} ${IMAGE_PATCH_SCRIPT_PATH} ${TARGET} --prefix ${PREFIX}
        WORKING_DIRECTORY ${WORKING_DIRECTORY}
    )
endmacro()

# Build Info
message("BUILD DATE:    ${BUILD_DATE}")
message("BUILD MACHINE: ${BUILD_MACHINE}")
message("BUILD MAJOR:   ${VERSION_MAJOR}")
message("BUILD MINOR:   ${VERSION_MINOR}")
message("BUILD PATCH:   ${VERSION_PATCH}")
message("BUILD TWEAK:   ${VERSION_TWEAK}")
message("BUILD AHEAD:   ${VERSION_AHEAD}")
message("BUILD SHA:     ${VERSION_GIT_SHA}")
message("BUILD DIRTY:   ${VERSION_DIRTY}")
