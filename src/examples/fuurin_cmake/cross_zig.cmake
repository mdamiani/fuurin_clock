#set(CMAKE_SYSTEM_NAME Linux)

set(ZIG zig)
#set(ZIG_FLAGS "-mcpu=x86_64_v2")
#set(ZIG_FLAGS "-target x86_64-linux-musl")
#set(ZIG_FLAGS "-target x86_64-linux-gnu")
#set(ZIG_FLAGS "-target x86_64-macos-gnu")
#set(ZIG_FLAGS "-target x86_64-windows-gnu")
#set(ZIG_FLAGS "-target i386-windows-gnu")
#set(ZIG_FLAGS "-target arm-linux-musleabihf")

set(CMAKE_C_COMPILER    ${ZIG} cc)
set(CMAKE_CXX_COMPILER  ${ZIG} c++)
set(CMAKE_AR            ${ZIG} ar)
set(CMAKE_RANLIB        ${ZIG} ranlib)

set(CMAKE_C_FLAGS   "${ZIG_FLAGS}")
set(CMAKE_CXX_FLAGS "${ZIG_FLAGS}")

###
# zig toolchain might fix the spaces problem in CMAKE_AR and CMAKE_RANLIB
#
# set(CMAKE_AR     zig ar)
# set(CMAKE_RANLIB zig ranlib)

# Source: https://github.com/Kitware/CMake/blob/v3.20.3/Modules/CMakeCXXInformation.cmake
set(CMAKE_CXX_ARCHIVE_CREATE "${ZIG} ar qc  <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_APPEND "${ZIG} ar q   <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_FINISH "${ZIG} ranlib <TARGET>")
