## 🦭seal_lake

**seal_lake** - is a collection of CMake functions helping to hide boilerplate and centralize maintenance of build configurations.

### Installation

Download and link the library from your project's CMakeLists.txt:
```
cmake_minimum_required(VERSION 3.20)

include(FetchContent)
FetchContent_Declare(seal_lake
    GIT_REPOSITORY "https://github.com/kamchatka-volcano/seal_lake.git"
    GIT_TAG "origin/master"
)
FetchContent_MakeAvailable(seal_lake)
include(${seal_lake_SOURCE_DIR}/seal_lake.cmake)
```

### License
**seal_lake** is licensed under the [MS-PL license](/LICENSE.md)  