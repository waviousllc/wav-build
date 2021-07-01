#
# This cmake module sets the project version and partial version
# variables by analysing the git tag and commit history. It expects git
# tags defined with semantic versioning 2.0.0 (http://semver.org/).
#
# The module expects the PROJECT_NAME variable to be set, and recognizes
# the GIT_FOUND, GIT_EXECUTABLE and VERSION_UPDATE_FROM_GIT variables.
# If Git is found and VERSION_UPDATE_FROM_GIT is set to boolean TRUE,
# the project version will be updated using information fetched from the
# most recent git tag and commit. Otherwise, the module will try to read
# a VERSION file containing the full and partial versions. The module
# will update this file each time the project version is updated.
#
# Once done, this module will define the following variables:
#
# VERSION_STRING - Version string without metadata
# such as "v2.0.0" or "v1.2.41-beta.1". This should correspond to the
# most recent git tag.
# VERSION_STRING_FULL - Version string with metadata
# such as "v2.0.0+3.a23fbc" or "v1.3.1-alpha.2+4.9c4fd1"
# VERSION - Same as VERSION_STRING,
# without the preceding 'v', e.g. "2.0.0" or "1.2.41-beta.1"
# VERSION_MAJOR - Major version integer (e.g. 2 in v2.3.1-RC.2+21.ef12c8)
# VERSION_MINOR - Minor version integer (e.g. 3 in v2.3.1-RC.2+21.ef12c8)
# VERSION_PATCH - Patch version integer (e.g. 1 in v2.3.1-RC.2+21.ef12c8)
# VERSION_TWEAK - Tweak version string (e.g. "RC.2" in v2.3.1-RC.2+21.ef12c8)
# VERSION_AHEAD - How many commits ahead of last tag (e.g. 21 in v2.3.1-RC.2+21.ef12c8)
# VERSION_GIT_SHA - The git sha1 of the most recent commit (e.g. the "ef12c8" in v2.3.1-RC.2+21.ef12c8)
#
# This module is public domain, use it as it fits you best.
#
# Author: Nuno Fachada

# Check if git is found...
find_package(Git)
if (GIT_FOUND AND VERSION_UPDATE_FROM_GIT)

    # Get a Human Readable name from Git blob
    execute_process(COMMAND ${GIT_EXECUTABLE} describe --long --dirty=+
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE RAW_GIT_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Extract SEM_VERSION, Commits ahead, and if dirty
    string(REPLACE "-" ";" GIT_INFO_LIST ${RAW_GIT_VERSION})
    list(LENGTH GIT_INFO_LIST GIT_INFO_LIST_LENGTH)

    # Extract Version from Tag
    list(GET GIT_INFO_LIST 0 VERSION_STRING)

    # If more than 3 then there's a tweak to parse
    if (${GIT_INFO_LIST_LENGTH} GREATER 3)
        list(GET GIT_INFO_LIST 1 VERSION_TWEAK)
        list(GET GIT_INFO_LIST 2 VERSION_AHEAD)
        list(GET GIT_INFO_LIST 3 SHA_DIRTY)
    # Else only parse commits ahead and if SHA is dirty
    else()
        list(GET GIT_INFO_LIST 1 VERSION_AHEAD)
        list(GET GIT_INFO_LIST 2 SHA_DIRTY)
    endif()

    # Dirty SHA will include "+" at the end of the string
    if (SHA_DIRTY MATCHES ".*\\+$")
        set(VERSION_DIRTY 1)
    else()
        set(VERSION_DIRTY 0)
    endif()

    # Unset variables
    unset(GIT_INFO_LIST)
    unset(GIT_INFO_LIST_LENGTH)
    unset(SHA_DIRTY)

    # Get current commit SHA from git
    execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE VERSION_GIT_SHA
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Get partial versions into a list
    string(REGEX MATCHALL "-.*$|[0-9]+" PARTIAL_VERSION_LIST
        ${VERSION_STRING})

    # Set the version numbers
    list(GET PARTIAL_VERSION_LIST
        0 VERSION_MAJOR)
    list(GET PARTIAL_VERSION_LIST
        1 VERSION_MINOR)
    list(GET PARTIAL_VERSION_LIST
        2 VERSION_PATCH)

    # Unset the list
    unset(PARTIAL_VERSION_LIST)

    # Set full project version string
    set(VERSION_STRING_FULL
        ${VERSION_STRING}+${VERSION_AHEAD}.${VERSION_GIT_SHA})

    # Save version to file (which will be used when Git is not available
    # or VERSION_UPDATE_FROM_GIT is disabled)
    file(WRITE ${CMAKE_SOURCE_DIR}/VERSION ${VERSION_STRING_FULL}
        "*" ${VERSION_STRING}
        "*" ${VERSION_MAJOR}
        "*" ${VERSION_MINOR}
        "*" ${VERSION_PATCH}
        "*" ${VERSION_TWEAK}
        "*" ${VERSION_AHEAD}
        "*" ${VERSION_GIT_SHA}
        "*" ${VERSION_DIRTY})

else()

    # Git not available, get version from file
    file(STRINGS ${CMAKE_SOURCE_DIR}/VERSION VERSION_LIST)
    string(REPLACE "*" ";" VERSION_LIST ${VERSION_LIST})
    # Set partial versions
    list(GET VERSION_LIST 0 VERSION_STRING_FULL)
    list(GET VERSION_LIST 1 VERSION_STRING)
    list(GET VERSION_LIST 2 VERSION_MAJOR)
    list(GET VERSION_LIST 3 VERSION_MINOR)
    list(GET VERSION_LIST 4 VERSION_PATCH)
    list(GET VERSION_LIST 5 VERSION_TWEAK)
    list(GET VERSION_LIST 6 VERSION_AHEAD)
    list(GET VERSION_LIST 7 VERSION_GIT_SHA)
    list(GET VERSION_LIST 8 VERSION_DIRTY)

endif()

# Set project version (without the preceding 'v')
set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})
if (VERSION_TWEAK)
    set(VERSION ${VERSION}-${VERSION_TWEAK})
endif()
