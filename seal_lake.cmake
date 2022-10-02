cmake_minimum_required(VERSION 3.18)

set(SEAL_LAKE_LIB_TYPE "")
set(SEAL_LAKE_DEFAULT_SCOPE "")

include(FetchContent)

macro(_SealLakeImpl_Library LIBRARY_TYPE LIBRARY_SCOPE INSTALL_BUILD_RESULT)
    set(SEAL_LAKE_LIB_TYPE ${LIBRARY_TYPE})
    set(SEAL_LAKE_DEFAULT_SCOPE ${LIBRARY_SCOPE})
    set(SEAL_LAKE_LIB_TYPE ${LIBRARY_TYPE} PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE ${LIBRARY_SCOPE} PARENT_SCOPE)


    if ("Threads::Threads" IN_LIST ARG_LIBRARIES)
        find_package(Threads REQUIRED)
        set(THREADS_PREFER_PTHREAD_FLAG ON)
    endif()

    add_library(${PROJECT_NAME} ${LIBRARY_TYPE} ${ARG_SOURCES})
    if (ARG_NAMESPACE)
        add_library("${ARG_NAMESPACE}::${PROJECT_NAME}" ALIAS ${PROJECT_NAME})
    else()
        add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS ${PROJECT_NAME})
    endif()
    target_include_directories(
            ${PROJECT_NAME}
            ${LIBRARY_SCOPE}
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    SealLake_Properties(${ARG_PROPERTIES})
    if (ARG_PUBLIC_HEADERS)
        set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${ARG_PUBLIC_HEADERS}")
    endif()
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})

    if (ARG_INCLUDES)
        SealLake_Includes(${ARG_INCLUDES})
    endif()
    if (ARG_BUILD_STAGE_INCLUDES)
        SealLake_BuildStageIncludes(${ARG_BUILD_STAGE_INCLUDES})
    endif()
    if (ARG_INTERFACE_INCLUDES)
        SealLake_InterfaceIncludes(${ARG_INTERFACE_INCLUDES})
    endif()

    if (ARG_LIBRARIES)
        SealLake_Libraries(${ARG_LIBRARIES})
    endif()
    if (ARG_BUILD_STAGE_LIBRARIES)
        SealLake_BuildStageLibraries(${ARG_BUILD_STAGE_LIBRARIES})
    endif()
    if (ARG_INTERFACE_LIBRARIES)
        SealLake_InterfaceLibraries(${ARG_INTERFACE_LIBRARIES})
    endif()

    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${PROJECT_NAME} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${PROJECT_NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        if(${INSTALL_BUILD_RESULT})
            install(TARGETS ${PROJECT_NAME}
                    ${INSTALL_BUILD_RESULT} DESTINATION "${CMAKE_INSTALL_LIBDIR}"
                    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}"
            )
            if (NOT ARG_PUBLIC_HEADERS)
                install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
            endif()
        else()
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endmacro()

function(SealLake_HeaderOnlyLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;PUBLIC_HEADERS;SOURCES;BUILD_STAGE_LIBRARIES"
        ${ARGN}
    )
    if (ARG_PUBLIC_HEADERS)
        message(FATAL_ERROR "Header only libraries can't use PUBLIC_HEADERS argument")
    endif()
    if (ARG_SOURCES)
        message(FATAL_ERROR "Header only libraries can't use SOURCES argument")
    endif()
    if (ARG_BUILD_STAGE_LIBRARIES)
        message(FATAL_ERROR "Header only libraries can't use BUILD_STAGE_LIBRARIES argument")
    endif()
    _SealLakeImpl_Library(INTERFACE INTERFACE "")
endfunction()

function(SealLake_StaticLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;BUILD_STAGE_LIBRARIES;"
        ${ARGN}
    )
    string(TOUPPER ${PROJECT_NAME} VARNAME)
    set(${${VARNAME}_OBJECT_LIB} "Build ${PROJECT_NAME} as object library" OFF PARENT_SCOPE)

    if (${VARNAME}_OBJECT_LIB)
        _SealLakeImpl_Library(OBJECT PUBLIC ARCHIVE)
    else()
        _SealLakeImpl_Library(STATIC PUBLIC ARCHIVE)
    endif()
    message("TEST_SEAL_LAKE_LIB_TYPE2: ${SEAL_LAKE_LIB_TYPE}")
endfunction()

function(SealLake_SharedLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;BUILD_STAGE_LIBRARIES"
        ${ARGN}
    )
    _SealLakeImpl_Library(SHARED PUBLIC LIBRARY)
endfunction()

function(SealLake_Executable)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;INCLUDES;LIBRARIES"
        ${ARGN}
    )
    set(SEAL_LAKE_LIB_TYPE "")
    set(SEAL_LAKE_LIB_TYPE "" PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE)

    if ("Threads::Threads" IN_LIST ARG_LIBRARIES)
        find_package(Threads REQUIRED)
        set(THREADS_PREFER_PTHREAD_FLAG ON)
    endif()

    add_executable(${PROJECT_NAME} ${ARG_SOURCES})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ARG_INCLUDES})
    SealLake_Properties(${ARG_PROPERTIES})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})
    SealLake_Libraries(${ARG_LIBRARIES})
    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${PROJECT_NAME} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${PROJECT_NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()
endfunction()

function (SealLake_GoogleTest)
    cmake_parse_arguments(
        ARG
        "SKIP_FETCHING"
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;INCLUDES;LIBRARIES"
        ${ARGN}
    )
    set(SEAL_LAKE_LIB_TYPE "")
    set(SEAL_LAKE_LIB_TYPE "" PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE)

    if (NOT ARG_SKIP_FETCHING)
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        set(INSTALL_GTEST OFF)
        SealLake_Import(googletest 1.12.1
          GIT_REPOSITORY https://github.com/google/googletest.git
          GIT_TAG release-1.12.1
        )
    endif()
    enable_testing()
    find_package(Threads REQUIRED)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    include(GoogleTest)
    add_executable(${PROJECT_NAME} ${ARG_SOURCES})
    add_test(NAME ${PROJECT_NAME} COMMAND ${PROJECT_NAME})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ARG_INCLUDES})
    SealLake_Properties(${ARG_PROPERTIES})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})
    SealLake_Libraries(${ARG_LIBRARIES} Threads::Threads GTest::gtest_main GTest::gmock_main)
    gtest_discover_tests(${PROJECT_NAME})
endfunction()

function (SealLake_Properties)
    if (ARGN)
        set_target_properties(${PROJECT_NAME} PROPERTIES ${ARGN})
    endif()
endfunction()

function (SealLake_CompileFeatures)
    foreach(FEATURE IN ITEMS ${ARGN})
    target_compile_features(${PROJECT_NAME} ${SEAL_LAKE_DEFAULT_SCOPE} ${FEATURE})
    endforeach()
endfunction()

function (SealLake_Includes)
  if (SEAL_LAKE_LIB_TYPE STREQUAL INTERFACE)
        SealLake_InterfaceIncludes(${ARGN})
    else()
        SealLake_BuildStageIncludes(${ARGN})
    endif()
endfunction()

function(SealLake_BuildStageIncludes)
     foreach (PATH IN ITEMS ${ARGN})
        if (IS_ABSOLUTE ${PATH})
            set(RESULT_PATH ${PATH})
        else()
            set(RESULT_PATH ${PROJECT_SOURCE_DIR}/include/${PATH})
        endif()
        target_include_directories(
               ${PROJECT_NAME}
               ${SEAL_LAKE_DEFAULT_SCOPE}
               $<BUILD_INTERFACE:${RESULT_PATH}>
        )
    endforeach()
endfunction()

function (SealLake_InterfaceIncludes)
    foreach (PATH IN ITEMS ${ARGN})
        if (IS_ABSOLUTE ${PATH})
            set(RESULT_PATH ${PATH})
        else()
            set(RESULT_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${PATH})
        endif()
        target_include_directories(
               ${PROJECT_NAME}
               ${SEAL_LAKE_DEFAULT_SCOPE}
               $<INSTALL_INTERFACE:${RESULT_PATH}>
        )
    endforeach()
endfunction()

function (SealLake_Libraries)
    if (SEAL_LAKE_LIB_TYPE STREQUAL INTERFACE)
        SealLake_InterfaceLibraries(${ARGN})
    else()
        SealLake_BuildStageLibraries(${ARGN})
    endif()
endfunction()

function (SealLake_InterfaceLibraries)
    foreach (LIB IN ITEMS ${ARGN})
        message("Link ${LIB}")
        target_link_libraries(${PROJECT_NAME} ${SEAL_LAKE_DEFAULT_SCOPE} ${LIB})
    endforeach()
endfunction()

function (SealLake_BuildStageLibraries)
    if (SEAL_LAKE_LIB_TYPE STREQUAL INTERFACE)
        message(WARNING "Header only libraries don't have a build stage to establish a build link dependency")
        return()
    endif()

    foreach (LIB IN ITEMS ${ARGN})
        message("Link ${LIB}")
        if (SEAL_LAKE_LIB_TYPE STREQUAL STATIC)
            target_link_libraries(${PROJECT_NAME} PRIVATE "$<BUILD_INTERFACE:${LIB}>")
        else()
            target_link_libraries(${PROJECT_NAME} PRIVATE ${LIB})
        endif()
    endforeach()
endfunction()

function (SealLake_OptionalBuildSteps)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "IF_ENABLED;IF_ENABLED_AND_STANDALONE;IF_ENABLED_OR_STANDALONE"
        ${ARGN}
    )
    macro (_Impl SUB_PROJECTS MODE)
        SealLake_CheckStandalone(IS_STANDALONE)
        foreach (DIR IN ITEMS ${SUB_PROJECTS})
            SealLake_StringAfterLast(${DIR} / DIRNAME)
            string(TOUPPER ${DIRNAME} VAR_DIRNAME)
            message("Add build step '${DIRNAME}'")
            set(ENABLE_${VAR_DIRNAME} "Enable ${DIRNAME}" OFF PARENT_SCOPE)
            if (${MODE} STREQUAL IF_ENABLED)
                if (ENABLE_${VAR_DIRNAME})
                    add_subdirectory(${DIR})
                endif()
            elseif(${MODE} STREQUAL IF_ENABLED_AND_STANDALONE)
                if (ENABLE_${VAR_DIRNAME} AND IS_STANDALONE)
                    add_subdirectory(${DIR})
                endif()
            elseif(${MODE} STREQUAL IF_ENABLED_OR_STANDALONE)
                if (ENABLE_${VAR_DIRNAME} OR IS_STANDALONE)
                    add_subdirectory(${DIR})
                endif()
            endif()
        endforeach()
    endmacro()
    if (ARG_IF_ENABLED)
        _Impl("${ARG_IF_ENABLED}" IF_ENABLED)
    endif()
    if (ARG_IF_ENABLED_AND_STANDALONE)
        _Impl("${ARG_IF_ENABLED_AND_STANDALONE}" IF_ENABLED_AND_STANDALONE)
    endif()
    if(ARG_UNPARSED_ARGUMENTS)
        _Impl("${ARG_UNPARSED_ARGUMENTS}" IF_ENABLED_AND_STANDALONE)
    endif()
    if (ARG_IF_ENABLED_OR_STANDALONE)
        _Impl("${ARG_IF_ENABLED_OR_STANDALONE}" IF_ENABLED_OR_STANDALONE)
    endif()
endfunction()

function (SealLake_Install)
    cmake_parse_arguments(
            ARG
            ""
            "DESTINATION"
            "FILES;DIRECTORIES"
            ${ARGN}
    )
    if(ARG_DESTINATION)
        if (IS_ABSOLUTE ${ARG_DESTINATION})
            set(DESTINATION_PATH ${ARG_DESTINATION})
        else()
            set(DESTINATION_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}/${ARG_DESTINATION})
        endif()
    else()
        set(DESTINATION_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})
    endif()
    if(ARG_FILES)
        install(FILES ${ARG_FILES} DESTINATION ${DESTINATION_PATH})
    endif()
    if(ARG_DIRECTORIES)
        install(DIRECTORY ${ARG_DIRECTORIES} DESTINATION ${DESTINATION_PATH})
    endif()
endfunction()

function(SealLake_CheckStandalone IS_STANDALONE)
    if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        set(${IS_STANDALONE} ON PARENT_SCOPE)
    else()
        set(${IS_STANDALONE} OFF PARENT_SCOPE)
    endif()
endfunction()


function(SealLake_InstallPackage)
   cmake_parse_arguments(
        ARG
        ""
        "COMPATIBILITY"
        ""
        ${ARGN}
    )
    set(PACK_PATH "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

    install(TARGETS "${PROJECT_NAME}"
            EXPORT "${PROJECT_NAME}-targets"
    )
    install(EXPORT "${PROJECT_NAME}-targets"
            FILE "${PROJECT_NAME}Targets.cmake"
            NAMESPACE "${PROJECT_NAME}::"
            DESTINATION "${PACK_PATH}"
    )

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            COMPATIBILITY "${ARG_COMPATIBILITY}"
            ARCH_INDEPENDENT
    )
    configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/cmake/${PROJECT_NAME}Config.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION "${PACK_PATH}"
    )
    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION "${PACK_PATH}"
    )
endfunction()

function (SealLake_Import NAME VERSION)
    cmake_parse_arguments(
        ARG
        ""
        "CMAKE_FILE;URL;GIT_REPOSITORY;GIT_TAG"
        ""
        ${ARGN}
    )
    find_package(${NAME} ${VERSION} QUIET)
    if (NOT ${${NAME}_FOUND})
        if (ARG_CMAKE_FILE)
            message("${NAME} wasn't found on your system, proceeding to use instructions from config ${ARG_CMAKE_FILE}.")
            include("${ARG_CMAKE_FILE}")
            return()
        endif()
        message("${NAME} wasn't found on your system, proceeding to downloading it.")
        Set(FETCHCONTENT_QUIET FALSE)
        if (ARG_URL)
            FetchContent_Declare(
                    ${NAME}
                    URL ${ARG_URL}
            )
        else()
            FetchContent_Declare(
                    ${NAME}
                    GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
                    GIT_TAG        ${ARG_GIT_TAG}
                    GIT_SHALLOW    ON
                    GIT_PROGRESS TRUE
            )
        endif()
        FetchContent_MakeAvailable(${NAME})
        set(${NAME}_POPULATED "${${NAME}_POPULATED}" PARENT_SCOPE)
        set(${NAME}_SOURCE_DIR "${${NAME}_SOURCE_DIR}" PARENT_SCOPE)
        set(${NAME}_BINARY_DIR "${${NAME}_BINARY_DIR}" PARENT_SCOPE)
    endif()
endfunction()

function(SealLake_Download)
    cmake_parse_arguments(
        ARG
        ""
        "URL;GIT_REPOSITORY;GIT_TAG;DESTINATION"
        "FILES;DIRECTORIES"
        ${ARGN}
    )
    include(FetchContent)
    SealLake_StringAfterLast(${ARG_GIT_REPOSITORY} "/" GIT_REPOSITORY_NAME)
    string(TOLOWER ${GIT_REPOSITORY_NAME} GIT_REPOSITORY_NAME)
    set(DOWNLOAD_TARGET "${GIT_REPOSITORY_NAME}_${ARG_GIT_TAG}")

    if (ARG_URL)
    FetchContent_Declare(
            ${DOWNLOAD_TARGET}
            URL ${ARG_URL}
    )
    else()
    FetchContent_Declare(
            ${DOWNLOAD_TARGET}
            GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
            GIT_TAG        ${ARG_GIT_TAG}
            GIT_SHALLOW    ON
            GIT_PROGRESS TRUE
    )
    endif()
    FetchContent_GetProperties(${DOWNLOAD_TARGET})
    if(NOT "${DOWNLOAD_TARGET}_POPULATED")
        FetchContent_Populate(${DOWNLOAD_TARGET})
        foreach(FILE_MASK IN ITEMS ${ARG_FILES})
            file(GLOB SRC_FILES "${${DOWNLOAD_TARGET}_SOURCE_DIR}/${FILE_MASK}")
            foreach(SRC IN ITEMS ${SRC_FILES})
                message("Copy file: ${SRC} to ${PROJECT_SOURCE_DIR}/${ARG_DESTINATION}")
                file(COPY "${SRC}" DESTINATION "${PROJECT_SOURCE_DIR}/${ARG_DESTINATION}")
            endforeach()
        endforeach()
        foreach(DIR IN ITEMS ${ARG_DIRECTORIES})
            message("Copy directory ${${DOWNLOAD_TARGET}_SOURCE_DIR}/${DIR} to ${PROJECT_SOURCE_DIR}/${ARG_DESTINATION}")
            file(COPY "${${DOWNLOAD_TARGET}_SOURCE_DIR}/${DIR}" DESTINATION "${PROJECT_SOURCE_DIR}/${ARG_DESTINATION}")
        endforeach()
    endif()
endfunction()

function(_SealLakeImpl_StringBefore STR VALUE RESULT REVERSE)
        string(FIND ${STR} ${VALUE} VALUE_POS ${REVERSE})
        string(LENGTH ${STR} STR_LENGTH)
        string(SUBSTRING ${STR}  0 ${VALUE_POS} RESULT_VALUE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

function (_SealLakeImpl_StringAfter STR VALUE RESULT REVERSE)
        string(FIND ${STR} ${VALUE} VALUE_POS ${REVERSE})
        message("VALUE_POS:${VALUE_POS}")
        string(LENGTH ${STR} STR_LENGTH)
        MATH(EXPR VALUE_POS "${VALUE_POS} + 1")
        MATH(EXPR RESULT_LENGTH "${STR_LENGTH} - ${VALUE_POS}")
        string(SUBSTRING ${STR} ${VALUE_POS} ${RESULT_LENGTH} RESULT_VALUE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

function (SealLake_StringBeforeLast STR VALUE RESULT)
        _SealLakeImpl_StringBefore(${STR} ${VALUE} RESULT_VALUE REVERSE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

function (SealLake_StringBeforeFirst STR VALUE RESULT)
        _SealLakeImpl_StringBefore(${STR} ${VALUE} RESULT_VALUE "")
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

function (SealLake_StringAfterFirst STR VALUE RESULT)
        _SealLakeImpl_StringAfter(${STR} ${VALUE} RESULT_VALUE "")
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

function (SealLake_StringAfterLast STR VALUE RESULT)
        _SealLakeImpl_StringAfter(${STR} ${VALUE} RESULT_VALUE REVERSE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()