cmake_minimum_required(VERSION 3.18)

set(SEAL_LAKE_LIB_TYPE "")
set(SEAL_LAKE_DEFAULT_SCOPE "")
set(SEAL_LAKE_DEPENDENCIES "")

include(FetchContent)

function(SealLake_HeaderOnlyLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;DEPENDENCIES;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
    _SealLakeImpl_Library(INTERFACE INTERFACE "")
endfunction()

function(SealLake_ObjectLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;DEPENDENCIES;SOURCES;PUBLIC_HEADERS;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;BUILD_STAGE_LIBRARIES;"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
    _SealLakeImpl_Library(OBJECT PUBLIC ARCHIVE)
endfunction()

function(SealLake_StaticLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;DEPENDENCIES;SOURCES;PUBLIC_HEADERS;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;BUILD_STAGE_LIBRARIES;"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
    string(TOUPPER ${SEAL_LAKE_TARGET} VARNAME)
    set(${${VARNAME}_OBJECT_LIB} "Build ${SEAL_LAKE_TARGET} as object library" OFF PARENT_SCOPE)

    if (${VARNAME}_OBJECT_LIB)
        _SealLakeImpl_Library(OBJECT PUBLIC ARCHIVE)
    else()
        _SealLakeImpl_Library(STATIC PUBLIC ARCHIVE)
    endif()
endfunction()

function(SealLake_SharedLibrary)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;NAMESPACE"
        "PROPERTIES;COMPILE_FEATURES;DEPENDENCIES;SOURCES;PUBLIC_HEADERS;INCLUDES;INTERFACE_INCLUDES;BUILD_STAGE_INCLUDES;LIBRARIES;INTERFACE_LIBRARIES;BUILD_STAGE_LIBRARIES"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
    _SealLakeImpl_Library(SHARED PUBLIC LIBRARY)
endfunction()

function(SealLake_Executable)
    cmake_parse_arguments(
        ARG
        ""
        "NAME"
        "PROPERTIES;COMPILE_FEATURES;SOURCES;INCLUDES;LIBRARIES"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
    set(SEAL_LAKE_LIB_TYPE "")
    set(SEAL_LAKE_LIB_TYPE "" PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE)

    if ("Threads::Threads" IN_LIST ARG_LIBRARIES)
        find_package(Threads REQUIRED)
        set(THREADS_PREFER_PTHREAD_FLAG ON)
    endif()

    add_executable(${SEAL_LAKE_TARGET} ${ARG_SOURCES})
    target_include_directories(${SEAL_LAKE_TARGET} PRIVATE ${ARG_INCLUDES})
    SealLake_Properties(${ARG_PROPERTIES})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})
    SealLake_Libraries(${ARG_LIBRARIES})
    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${SEAL_LAKE_TARGET} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${SEAL_LAKE_TARGET}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(TARGETS ${SEAL_LAKE_TARGET} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
    endif()
endfunction()

function (SealLake_GoogleTest)
    cmake_parse_arguments(
        ARG
        "SKIP_FETCHING"
        "NAME"
        "PROPERTIES;COMPILE_FEATURES;SOURCES;INCLUDES;LIBRARIES"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    _SealLakeImpl_UpdateTarget("${ARG_NAME}")
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
    add_executable(${SEAL_LAKE_TARGET} ${ARG_SOURCES})
    add_test(NAME ${SEAL_LAKE_TARGET} COMMAND ${SEAL_LAKE_TARGET})
    target_include_directories(${SEAL_LAKE_TARGET} PRIVATE ${ARG_INCLUDES})
    SealLake_Properties(${ARG_PROPERTIES})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})
    SealLake_Libraries(${ARG_LIBRARIES} Threads::Threads GTest::gtest_main GTest::gmock_main)
    gtest_discover_tests(${SEAL_LAKE_TARGET})
endfunction()

function (SealLake_Properties)
    if (ARGN)
        set_target_properties(${SEAL_LAKE_TARGET} PROPERTIES ${ARGN})
    endif()
endfunction()

function (SealLake_CompileFeatures)
    foreach(FEATURE IN ITEMS ${ARGN})
        target_compile_features(${SEAL_LAKE_TARGET} ${SEAL_LAKE_DEFAULT_SCOPE} ${FEATURE})
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
        SealLake_Info("Add build stage include path: ${RESULT_PATH}")
        target_include_directories(
               ${SEAL_LAKE_TARGET}
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
        SealLake_Info("Add interface include path: ${RESULT_PATH}")
        target_include_directories(
               ${SEAL_LAKE_TARGET}
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
        SealLake_Info("Link library ${LIB}")
        target_link_libraries(${SEAL_LAKE_TARGET} ${SEAL_LAKE_DEFAULT_SCOPE} ${LIB})
    endforeach()
endfunction()

function (SealLake_BuildStageLibraries)
    if (SEAL_LAKE_LIB_TYPE STREQUAL INTERFACE)
        SealLake_Warning("Header only libraries don't have a build stage to establish a build link dependency")
        return()
    endif()

    foreach (LIB IN ITEMS ${ARGN})
        SealLake_Info("Link library ${LIB}")
        if (SEAL_LAKE_LIB_TYPE STREQUAL STATIC OR SEAL_LAKE_LIB_TYPE STREQUAL OBJECT)
            target_link_libraries(${SEAL_LAKE_TARGET} PRIVATE "$<BUILD_INTERFACE:${LIB}>")
        else()
            target_link_libraries(${SEAL_LAKE_TARGET} PRIVATE ${LIB})
        endif()
    endforeach()
endfunction()

function (SealLake_Dependencies)
    list(APPEND DEPENDENCIES ${SEAL_LAKE_DEPENDENCIES})
    list(APPEND DEPENDENCIES ${ARGN})
    set(SEAL_LAKE_DEPENDENCIES ${DEPENDENCIES} PARENT_SCOPE)
    _SealLakeImpl_CreatePackageConfig(DEPENDENCIES ${DEPENDENCIES})
endfunction()

function (SealLake_OptionalBuildSteps)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "IF_ENABLED;IF_ENABLED_AND_STANDALONE;IF_ENABLED_OR_STANDALONE"
        ${ARGN}
    )
    macro(AddDirectory)
        SealLake_Info("Add build step ${DIR}")
        set(CURRENT_TARGET ${SEAL_LAKE_TARGET})
        set(SEAL_LAKE_TARGET "")
        add_subdirectory(${DIR})
        set(SEAL_LAKE_TARGET "${CURRENT_TARGET}")
        set(SEAL_LAKE_TARGET "${CURRENT_TARGET}" PARENT_SCOPE)
    endmacro()
    macro (_Impl SUB_PROJECTS MODE)
        SealLake_CheckStandalone(IS_STANDALONE)
        foreach (DIR IN ITEMS ${SUB_PROJECTS})
            SealLake_StringAfterLast(${DIR} / DIRNAME)
            string(TOUPPER ${DIRNAME} VAR_DIRNAME)
            set(ENABLE_${VAR_DIRNAME} "Enable ${DIRNAME}" OFF PARENT_SCOPE)
            if (${MODE} STREQUAL IF_ENABLED)
                if (ENABLE_${VAR_DIRNAME})
                    AddDirectory()
                endif()
            elseif(${MODE} STREQUAL IF_ENABLED_AND_STANDALONE)
                if (ENABLE_${VAR_DIRNAME} AND IS_STANDALONE)
                    AddDirectory()
                endif()
            elseif(${MODE} STREQUAL IF_ENABLED_OR_STANDALONE)
                if (ENABLE_${VAR_DIRNAME} OR IS_STANDALONE)
                    AddDirectory()
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
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    if(ARG_DESTINATION)
        if (IS_ABSOLUTE ${ARG_DESTINATION})
            set(DESTINATION_PATH ${ARG_DESTINATION})
        else()
            set(DESTINATION_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${SEAL_LAKE_TARGET}/${ARG_DESTINATION})
        endif()
    else()
        set(DESTINATION_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${SEAL_LAKE_TARGET})
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
        "COMPATIBILITY;NAMESPACE"
        "DEPENDENCIES"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    set(PACK_PATH "${CMAKE_INSTALL_LIBDIR}/cmake/${SEAL_LAKE_TARGET}")

    install(TARGETS "${SEAL_LAKE_TARGET}"
            EXPORT "${SEAL_LAKE_TARGET}-targets"
    )

    if (ARG_NAMESPACE)
        set(NAMESPACE ${ARG_NAMESPACE})
    else()
        set(NAMESPACE ${SEAL_LAKE_TARGET})
    endif()

    install(EXPORT "${SEAL_LAKE_TARGET}-targets"
            FILE "${SEAL_LAKE_TARGET}Targets.cmake"
            NAMESPACE "${NAMESPACE}::"
            DESTINATION "${PACK_PATH}"
    )

    include(CMakePackageConfigHelpers)
    _SealLakeImpl_CreatePackageConfig(DEPENDENCIES ${ARG_DEPENDENCIES})

    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}ConfigVersion.cmake"
            COMPATIBILITY "${ARG_COMPATIBILITY}"
            ARCH_INDEPENDENT
    )
    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}ConfigVersion.cmake"
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
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

find_package(${NAME} ${VERSION} QUIET)
    if (NOT ${${NAME}_FOUND})
        if (ARG_CMAKE_FILE)
            SealLake_Info("${NAME} wasn't found on your system, proceeding to use instructions from config ${ARG_CMAKE_FILE}.")
            include("${ARG_CMAKE_FILE}")
            return()
        endif()

        SealLake_Info("${NAME} wasn't found on your system, proceeding to downloading it.")
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
        set(${VARNAME}_POPULATED "${${VARNAME}_POPULATED}" PARENT_SCOPE)
        set(${VARNAME}_SOURCE_DIR "${${VARNAME}_SOURCE_DIR}" PARENT_SCOPE)
        set(${VARNAME}_BINARY_DIR "${${VARNAME}_BINARY_DIR}" PARENT_SCOPE)
    endif()
endfunction()

function(SealLake_Bundle)
    cmake_parse_arguments(
        ARG
        "SKIP_LOAD"
        "NAME;URL;GIT_REPOSITORY;GIT_TAG;DESTINATION"
        "FILES;DIRECTORIES;WILDCARDS;TEXT_REPLACEMENTS"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    SealLake_DownloadSource(
        NAME           "${ARG_NAME}"
        GIT_REPOSITORY "${ARG_GIT_REPOSITORY}"
        GIT_TAG        "${ARG_GIT_TAG}"
        URL            "${ARG_URL}"
    )
    set(SEAL_LAKE_SOURCE_${ARG_NAME} "${SEAL_LAKE_SOURCE_${ARG_NAME}}" PARENT_SCOPE)

    SealLake_ReplaceText(
        SOURCE             "${ARG_NAME}"
        DIRECTORIES        "."
        TEXT_REPLACEMENTS  ${ARG_TEXT_REPLACEMENTS}
    )
    if (NOT ARG_SKIP_LOAD)
        SealLake_Load("${ARG_NAME}" TARGET_NAME "${ARG_NAME}")
    endif()
    SealLake_Copy(
        SOURCE      "${ARG_NAME}"
        FILES        ${ARG_FILES}
        DIRECTORIES  ${ARG_DIRECTORIES}
        WILDCARDS    ${ARG_WILDCARDS}
        DESTINATION "${ARG_DESTINATION}"
    )
endfunction()

function(SealLake_Copy)
    cmake_parse_arguments(
        ARG
        ""
        "SOURCE;SOURCE_PATH;DESTINATION"
        "FILES;DIRECTORIES;WILDCARDS"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    if (ARG_SOURCE AND ARG_SOURCE_PATH)
        SealLake_Error("ARG_SOURCE and ARG_SOURCE_PATH arguments can't be specified simultaneously")
    endif()
    if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${ARG_SOURCE}")
        SealLake_Error("Project source '${ARG_SOURCE}' doesn't exist, use DownloadSource() function to create a project source.")
    endif()

    if (ARG_SOURCE)
        set(ARG_SOURCE_PATH "${CMAKE_CURRENT_BINARY_DIR}/${ARG_SOURCE}")
    endif()
    if (NOT IS_ABSOLUTE "${ARG_SOURCE_PATH}")
        set(ARG_SOURCE_PATH "${PROJECT_SOURCE_DIR}/${ARG_SOURCE_PATH}")
    endif()
    if (NOT IS_ABSOLUTE "${ARG_DESTINATION}")
        set(ARG_DESTINATION "${PROJECT_SOURCE_DIR}/${ARG_DESTINATION}")
    endif()

    foreach(FILE IN ITEMS ${ARG_FILES})
        if (NOT IS_ABSOLUTE "${FILE}")
            set(FILE "${ARG_SOURCE_PATH}/${FILE}")
        endif()
        get_filename_component(FILENAME "${FILE}" NAME)
        file(REMOVE "${ARG_DESTINATION}/${FILENAME}")
        file(COPY "${FILE}" DESTINATION "${ARG_DESTINATION}")
    endforeach()

    foreach(DIR IN ITEMS ${ARG_DIRECTORIES})
        if (NOT IS_ABSOLUTE "${DIR}")
            set(DIR "${ARG_SOURCE_PATH}/${DIR}")
        endif()
        file(GLOB_RECURSE FILES "${DIR}/*")
        foreach(FILE IN ITEMS ${FILES})
            SealLake_StringBeforeLast(${DIR} / DIR_PARENT)
            SealLake_StringAfterFirst(${FILE} "${DIR_PARENT}" FILEPATH)
            SealLake_StringBeforeLast(${FILEPATH} / FILEDIR)
            get_filename_component(FILENAME "${FILE}" NAME)
            file(REMOVE "${ARG_DESTINATION}/${FILEDIR}/${FILENAME}")
            file(COPY "${FILE}" DESTINATION "${ARG_DESTINATION}/${FILEDIR}")
        endforeach()
    endforeach()

    foreach(WILDCARD IN ITEMS ${ARG_WILDCARDS})
        if (NOT IS_ABSOLUTE "${WILDCARD}")
            set(WILDCARD "${ARG_SOURCE_PATH}/${WILDCARD}")
        endif()
        file(GLOB FILES "${WILDCARD}")
        foreach(FILE IN ITEMS ${FILES})
            get_filename_component(FILENAME "${FILE}" NAME)
            file(REMOVE "${ARG_DESTINATION}/${FILENAME}")
            file(COPY "${FILE}" DESTINATION "${ARG_DESTINATION}")
        endforeach()
    endforeach()
endfunction()

function(SealLake_ReplaceText)
     cmake_parse_arguments(
        ARG
        ""
        "SOURCE;SOURCE_PATH"
        "FILES;DIRECTORIES;WILDCARDS;TEXT_REPLACEMENTS"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    if (ARG_SOURCE AND ARG_SOURCE_PATH)
        SealLake_Error("ARG_SOURCE and ARG_SOURCE_PATH arguments can't be specified simultaneously")
    endif()
    if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${ARG_SOURCE}")
        SealLake_Error("Project source '${ARG_SOURCE}' doesn't exist, use DownloadSource() function to create a project source.")
    endif()

    if (ARG_SOURCE)
        set(ARG_SOURCE_PATH "${CMAKE_CURRENT_BINARY_DIR}/${ARG_SOURCE}")
    endif()
    if (NOT ARG_TEXT_REPLACEMENTS)
         return()
    endif()

    if (NOT IS_ABSOLUTE "${ARG_SOURCE_PATH}")
        set(ARG_SOURCE_PATH "${PROJECT_SOURCE_DIR}/${ARG_SOURCE_PATH}")
    endif()

    foreach (FILE IN ITEMS ${ARG_FILES})
        if (NOT IS_ABSOLUTE "${FILE}")
            set(FILE "${ARG_SOURCE_PATH}/${FILE}")
        endif()
        _SealLakeImpl_ReplaceText("${FILE}" ${ARG_TEXT_REPLACEMENTS})
    endforeach()

    foreach(DIR IN ITEMS ${ARG_DIRECTORIES})
        if (NOT IS_ABSOLUTE "${DIR}")
            set(DIR "${ARG_SOURCE_PATH}/${DIR}")
        endif()
        file(GLOB_RECURSE FILES "${DIR}/*")
        foreach(FILE IN ITEMS ${FILES})
            _SealLakeImpl_ReplaceText("${FILE}" ${ARG_TEXT_REPLACEMENTS})
        endforeach()
    endforeach()

    foreach(WILDCARD IN ITEMS ${ARG_WILDCARDS})
        if (NOT IS_ABSOLUTE "${WILDCARD}")
            set(WILDCARD "${ARG_SOURCE_PATH}/${WILDCARD}")
        endif()
        file(GLOB FILES "${WILDCARD}")
        foreach(FILE IN ITEMS ${FILES})
            _SealLakeImpl_ReplaceText("${FILE}" ${ARG_TEXT_REPLACEMENTS})
        endforeach()
    endforeach()
endfunction()

function(SealLake_DownloadSource)
    cmake_parse_arguments(
        ARG
        ""
        "NAME;URL;GIT_REPOSITORY;GIT_TAG"
        ""
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include(FetchContent)
    if (ARG_URL)
        SealLake_StringAfterLast(${ARG_URL} "/" URL_NAME)
        SealLake_Info("Download ${URL_NAME}")
        string(TOLOWER ${URL_NAME} URL_NAME)
        set(DOWNLOAD_TARGET "${URL_NAME}")
        FetchContent_Declare(
                ${DOWNLOAD_TARGET}
                URL ${ARG_URL}
        )
    else()
        SealLake_StringAfterLast(${ARG_GIT_REPOSITORY} "/" GIT_REPOSITORY_NAME)
        SealLake_Info("Download ${GIT_REPOSITORY_NAME}")
        string(TOLOWER ${GIT_REPOSITORY_NAME} GIT_REPOSITORY_NAME)
        set(DOWNLOAD_TARGET "${GIT_REPOSITORY_NAME}_${ARG_GIT_TAG}")
        FetchContent_Declare(
                ${DOWNLOAD_TARGET}
                GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
                GIT_TAG        ${ARG_GIT_TAG}
                GIT_SHALLOW    ON
                GIT_PROGRESS TRUE
        )
    endif()
    FetchContent_GetProperties(${DOWNLOAD_TARGET})
    if(NOT ${DOWNLOAD_TARGET}_POPULATED)
        FetchContent_Populate(${DOWNLOAD_TARGET})
    endif()

    SealLake_Copy(
        SOURCE_PATH ${${DOWNLOAD_TARGET}_SOURCE_DIR}
        DIRECTORIES .
        DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}"
    )
    set(SEAL_LAKE_SOURCE_${ARG_NAME} "${CMAKE_CURRENT_BINARY_DIR}/${ARG_NAME}" PARENT_SCOPE)
endfunction()

function(SealLake_Load SOURCE)
    cmake_parse_arguments(
        ARG
        ""
        "TARGET_NAME;"
        ""
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()
    if (NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${SOURCE}")
        SealLake_Error("Project source '${SOURCE}' doesn't exist, use DownloadSource() function to create a project source.")
    endif()

    if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${SOURCE}/CMakeLists.txt)
        set(CURRENT_TARGET ${SEAL_LAKE_TARGET})
        set(SEAL_LAKE_TARGET ${ARG_TARGET_NAME})
        add_subdirectory("${CMAKE_CURRENT_BINARY_DIR}/${SOURCE}" "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET_NAME}-build")
        set(SEAL_LAKE_TARGET ${CURRENT_TARGET})
        set(SEAL_LAKE_TARGET ${CURRENT_TARGET} PARENT_SCOPE)
    endif()

    set(${VARNAME}_POPULATED "${${VARNAME}_POPULATED}" PARENT_SCOPE)
    set(${VARNAME}_SOURCE_DIR "${${VARNAME}_SOURCE_DIR}" PARENT_SCOPE)
    set(${VARNAME}_BINARY_DIR "${${VARNAME}_BINARY_DIR}" PARENT_SCOPE)
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

macro (SealLake_Info MSG)
    _SealLakeImpl_TargetName(_SealLakeImpl_TARGET)
    message("[${_SealLakeImpl_TARGET}] ${MSG}")
endmacro()

macro (SealLake_Warning MSG)
    _SealLakeImpl_TargetName(_SealLakeImpl_TARGET)
    message(WARNING "[${_SealLakeImpl_TARGET}] ${CMAKE_CURRENT_FUNCTION}(): ${MSG}")
endmacro()

macro (SealLake_Error MSG)
    _SealLakeImpl_TargetName(_SealLakeImpl_TARGET)
    message(FATAL_ERROR "[${_SealLakeImpl_TARGET}] ${CMAKE_CURRENT_FUNCTION}(): ${MSG}")
endmacro()

########################################################################################################################
######################################## HERE BE IMPLEMENTATION DETAILS ################################################
########################################################################################################################

macro(_SealLakeImpl_Library LIBRARY_TYPE LIBRARY_SCOPE INSTALL_BUILD_RESULT)
    set(SEAL_LAKE_LIB_TYPE ${LIBRARY_TYPE})
    set(SEAL_LAKE_DEFAULT_SCOPE ${LIBRARY_SCOPE})
    set(SEAL_LAKE_LIB_TYPE ${LIBRARY_TYPE} PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE ${LIBRARY_SCOPE} PARENT_SCOPE)
    list(APPEND DEPENDENCIES ${SEAL_LAKE_DEPENDENCIES})
    list(APPEND DEPENDENCIES ${ARG_DEPENDENCIES})
    set(SEAL_LAKE_DEPENDENCIES ${DEPENDENCIES} PARENT_SCOPE)
    set(ARG_INSTALL_BUILD_RESULT "${INSTALL_BUILD_RESULT}")

    if ("Threads::Threads" IN_LIST ARG_LIBRARIES)
        find_package(Threads REQUIRED)
        set(THREADS_PREFER_PTHREAD_FLAG ON)
    endif()

    add_library(${SEAL_LAKE_TARGET} ${LIBRARY_TYPE} ${ARG_SOURCES})
    if (ARG_NAMESPACE)
        add_library("${ARG_NAMESPACE}::${SEAL_LAKE_TARGET}" ALIAS ${SEAL_LAKE_TARGET})
    else()
        add_library("${SEAL_LAKE_TARGET}::${SEAL_LAKE_TARGET}" ALIAS ${SEAL_LAKE_TARGET})
    endif()
    target_include_directories(
            ${SEAL_LAKE_TARGET}
            ${LIBRARY_SCOPE}
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    SealLake_Properties(${ARG_PROPERTIES})
    if (ARG_PUBLIC_HEADERS)
        set_target_properties(${SEAL_LAKE_TARGET} PROPERTIES PUBLIC_HEADER "${ARG_PUBLIC_HEADERS}")
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
    string(TOUPPER ${SEAL_LAKE_TARGET} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${SEAL_LAKE_TARGET}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        if(ARG_INSTALL_BUILD_RESULT)
            install(TARGETS ${SEAL_LAKE_TARGET}
                    ${ARG_INSTALL_BUILD_RESULT} DESTINATION "${CMAKE_INSTALL_LIBDIR}"
                    PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${SEAL_LAKE_TARGET}"
            )
            if (NOT ARG_PUBLIC_HEADERS)
                if (EXISTS "${PROJECT_SOURCE_DIR}/include/${SEAL_LAKE_TARGET}")
                    install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${SEAL_LAKE_TARGET} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
                endif()
            endif()
        else()
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${SEAL_LAKE_TARGET} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(
                COMPATIBILITY SameMajorVersion
                NAMESPACE ${ARG_NAMESPACE}
                DEPENDENCIES ${DEPENDENCIES}
        )
    endif()
endmacro()

function (_SealLakeImpl_CreatePackageConfig)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "DEPENDENCIES"
        ${ARGN}
    )
    if (ARG_UNPARSED_ARGUMENTS)
        SealLake_Error("Unsupported argument: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    include(CMakePackageConfigHelpers)
    set(RESULT "@PACKAGE_INIT@
    include(CMakeFindDependencyMacro)
    ")

    list(LENGTH ARG_DEPENDENCIES DEPS_LENGTH)
    MATH(EXPR DEP_LAST_INDEX "${DEPS_LENGTH} - 2")
    if (DEPS_LENGTH GREATER 1)
        foreach(DEP_INDEX RANGE 0 ${DEP_LAST_INDEX} 2)
            list(GET ARG_DEPENDENCIES ${DEP_INDEX} DEP_NAME)
            MATH(EXPR DEP_INDEX "${DEP_INDEX}+1")
            list(GET ARG_DEPENDENCIES ${DEP_INDEX} DEP_VERSION)
            if (DEP_NAME)
                if (DEP_VERSION)
                    string(APPEND RESULT "find_dependency(${DEP_NAME} ${DEP_VERSION})
    ")
                else()
                    string(APPEND RESULT "find_dependency(${DEP_NAME})
    ")
                endif()
            endif()
        endforeach()
    endif()
    string(APPEND RESULT "include(\"$")
    string(APPEND RESULT "{CMAKE_CURRENT_LIST_DIR}/${SEAL_LAKE_TARGET}Targets.cmake\")")

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}Config.cmake.in" ${RESULT})
    configure_package_config_file("${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}Config.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_TARGET}Config.cmake"
            INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${SEAL_LAKE_TARGET}"
    )
endfunction()

function(_SealLakeImpl_ReplaceText FILE)
    string(FIND "${FILE}" ".git/" IS_GIT_FILE)
    if (NOT "${IS_GIT_FILE}" EQUAL -1)
        return()
    endif()
    list(LENGTH ARGN TEXT_REPLACEMENTS_LENGTH)
    MATH(EXPR REPLACEMENT_LAST_INDEX "${TEXT_REPLACEMENTS_LENGTH} - 2")
    if (TEXT_REPLACEMENTS_LENGTH GREATER 1)
        file(READ "${FILE}" CONTENT)
        foreach(REPLACEMENT_INDEX RANGE 0 ${REPLACEMENT_LAST_INDEX} 2)
            list(GET ARGN ${REPLACEMENT_INDEX} FROM_STR)
            MATH(EXPR REPLACEMENT_INDEX "${REPLACEMENT_INDEX}+1")
            list(GET ARGN ${REPLACEMENT_INDEX} TO_STR)
            if (FROM_STR)
                string(REPLACE "${FROM_STR}" "${TO_STR}" CONTENT "${CONTENT}")
                file(WRITE "${FILE}" "${CONTENT}")
            endif()
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
        string(LENGTH ${STR} STR_LENGTH)
        string(LENGTH ${VALUE} VALUE_LENGTH)
        MATH(EXPR RESULT_LENGTH "${STR_LENGTH} - ${VALUE_POS} - ${VALUE_LENGTH}")
        MATH(EXPR RESULT_POS "${VALUE_POS} + ${VALUE_LENGTH}")
        string(SUBSTRING ${STR} ${RESULT_POS} ${RESULT_LENGTH} RESULT_VALUE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
endfunction()

macro(_SealLakeImpl_UpdateTarget NAME)
    set(ARG_NAME "${NAME}")
    if (ARG_NAME)
        set(SEAL_LAKE_TARGET ${ARG_NAME})
        set(SEAL_LAKE_TARGET ${ARG_NAME} PARENT_SCOPE)
        message("DEBUG TARGET CUSTOM NAME: ${SEAL_LAKE_TARGET}")
    else()
        message("DEBUG TARGET_NAME_BEFORE: ${SEAL_LAKE_TARGET}")
        if (NOT SEAL_LAKE_TARGET)
            set(SEAL_LAKE_TARGET ${PROJECT_NAME})
            set(SEAL_LAKE_TARGET ${PROJECT_NAME} PARENT_SCOPE)
        endif()
        message("DEBUG TARGET_NAME_AFTER: ${SEAL_LAKE_TARGET}")
    endif()
endmacro()

function(_SealLakeImpl_TargetName OUT_NAME)
    if (NOT SEAL_LAKE_TARGET)
        set(${OUT_NAME} ${PROJECT_NAME} PARENT_SCOPE)
    else()
        set(${OUT_NAME} ${SEAL_LAKE_TARGET} PARENT_SCOPE)
    endif()
endfunction()