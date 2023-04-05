###
 # Copyright (c) Contributors as noted in the AUTHORS file.
 #
 # This Source Code Form is part of *fuurin* library.
 #
 # This Source Code Form is subject to the terms of the Mozilla Public
 # License, v. 2.0. If a copy of the MPL was not distributed with this
 # file, You can obtain one at http://mozilla.org/MPL/2.0/.
 ##

cmake_minimum_required(VERSION 3.16.3)

project(fuurin_lib)

include(ExternalProject)


ExternalProject_Add(fuurin
    GIT_REPOSITORY    https://github.com/mdamiani/fuurin.git
    GIT_TAG           master
    INSTALL_DIR       "${CMAKE_BINARY_DIR}/install"

    CMAKE_ARGS
        -D USE_GNUINSTALLDIRS=OFF
        -D BUILD_SHARED=OFF
        -D CMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -D CMAKE_BUILD_TYPE=RelWithDebInfo
        -D CMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cross_zig.cmake
)
