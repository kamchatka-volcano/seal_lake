cmake_minimum_required(VERSION 3.20)

set(SEAL_LAKE_LIB_TYPE "")
set(SEAL_LAKE_DEFAULT_SCOPE "")
include(FetchContent)

macro(_SealLakeImpl_Library LIBRARY_TYPE LIBRARY_SCOPE INSTALL_BUILD_RESULT)
    set(${SEAL_LAKE_LIB_TYPE} ${LIBRARY_TYPE} PARENT_SCOPE)
    set(SEAL_LAKE_LIB_TYPE ${LIBRARY_TYPE})
    set(${SEAL_LAKE_DEFAULT_SCOPE} ${LIBRARY_SCOPE} PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE ${LIBRARY_SCOPE})

    add_library(${PROJECT_NAME} ${LIBRARY_TYPE} ${ARG_SOURCES})
    add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS ${PROJECT_NAME})
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
    SealLake_Includes(
            INSTALL ${ARG_INCLUDES}
            BUILD ${ARG_BUILD_INCLUDES}
    )
    SealLake_Libraries(INSTALL ${ARG_INSTALL_LIBRARIES} BUILD ${ARG_LIBRARIES})
    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${PROJECT_NAME} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${PROJECT_NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
	if(${INSTALL_BUILD_RESULT})
		install(TARGETS ${PROJECT_NAME}
		        ${INSTALL_BUILD_RESULT} DESTINATION "${CMAKE_INSTALL_LIBDIR}"
		        PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}"
		)
	endif()
        if (NOT ARG_PUBLIC_HEADERS)
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endmacro()

function(SealLake_HeaderOnlyLibrary)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;INCLUDES;BUILD_INCLUDES;INSTALL_LIBRARIES"
        ${ARGN}
    )
    _SealLakeImpl_Library(INTERFACE INTERFACE "")
endfunction()

function(SealLake_StaticLibrary)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS;INCLUDES;BUILD_INCLUDES;LIBRARIES;INSTALL_LIBRARIES"
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
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS;INCLUDES;BUILD_INCLUDES;LIBRARIES;INSTALL_LIBRARIES"
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
    set(${SEAL_LAKE_DEFAULT_SCOPE} PRIVATE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE)

    add_executable(${PROJECT_NAME} ${ARG_SOURCES})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ARG_INCLUDES})
    SealLake_Properties(${ARG_PROPERTIES})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})
    SealLake_Libraries(BUILD ${ARG_LIBRARIES})
    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${PROJECT_NAME} VARNAME)
    set(${INSTALL_${VARNAME}} "Install ${PROJECT_NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        if(${INSTALL_BUILD_RESULT})
            install(TARGETS ${PROJECT_NAME}
                    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
            )
        endif()
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
    set(${SEAL_LAKE_DEFAULT_SCOPE} PRIVATE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PRIVATE)

    if (NOT ARG_SKIP_FETCHING)
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        set(INSTALL_GTEST OFF)
        SealLake_FindOrDownload(googletest 1.12.1
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
    SealLake_Libraries(
            BUILD
                ${ARG_LIBRARIES} Threads::Threads GTest::gtest_main GTest::gmock_main
    )
    gtest_discover_tests(${PROJECT_NAME})
endfunction()

function (SealLake_Properties)
    list(LENGTH ARGN PROPERTIES_LENGTH)
    MATH(EXPR PROPERTY_LAST_INDEX "${PROPERTIES_LENGTH} - 2")
    if (PROPERTIES_LENGTH GREATER 1)
        foreach(PROPERTY_INDEX RANGE 0 ${PROPERTY_LAST_INDEX} 2)
            list(GET ARGN ${PROPERTY_INDEX} PROPERTY_NAME)
            MATH(EXPR PROPERTY_INDEX "${PROPERTY_INDEX}+1")
            list(GET ARGN ${PROPERTY_INDEX} PROPERTY_VALUE)
            message("Set property ${PROPERTY_NAME} ${PROPERTY_VALUE}")
            if (PROPERTY_NAME AND PROPERTY_VALUE)
                set_target_properties(${PROJECT_NAME} PROPERTIES ${PROPERTY_NAME} "${PROPERTY_VALUE}")
            endif()
        endforeach()
    endif()
endfunction()

function (SealLake_CompileFeatures)
    foreach(FEATURE IN ITEMS ${ARGN})
    target_compile_features(${PROJECT_NAME} ${SEAL_LAKE_DEFAULT_SCOPE} ${FEATURE})
    endforeach()
endfunction()

function (SealLake_Includes)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "BUILD;INSTALL"
        ${ARGN}
    )
    macro(_AddIncludes INTERFACE_TYPE)
        foreach (PATH IN ITEMS ${ARGN})
            cmake_path(IS_RELATIVE PATH IS_PATH_RELATIVE)
            if (IS_PATH_RELATIVE)
                set(RESULT_PATH ${CMAKE_INSTALL_INCLUDEDIR}/${PATH})
            else()
                set(RESULT_PATH ${PATH})
            endif()
            target_include_directories(
                   ${PROJECT_NAME}
                   PUBLIC
                   $<${INTERFACE_TYPE}_INTERFACE:${RESULT_PATH}>
            )
        endforeach()
    endmacro()
    _AddIncludes(BUILD ${ARG_BUILD})
    _AddIncludes(INSTALL ${ARG_INSTALL})
endfunction()

function (SealLake_Libraries)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "BUILD;INSTALL"
        ${ARGN}
    )

    if (SEAL_LAKE_LIB_TYPE STREQUAL INTERFACE AND ARG_BUILD)
        message(WARNING "Header only library don't have a build stage to establish a build link dependency")
    endif()

    macro(_AddLibraries SCOPE)
        foreach (LIB IN ITEMS ${ARGN})
            message("Link ${LIB}")
            if (SEAL_LAKE_LIB_TYPE STREQUAL STATIC AND ${SCOPE} STREQUAL PRIVATE)
                target_link_libraries(${PROJECT_NAME} ${SCOPE} "$<BUILD_INTERFACE:${LIB}>")
            else()
                target_link_libraries(${PROJECT_NAME} ${SCOPE} ${LIB})
            endif()
        endforeach()
    endmacro()
    _AddLibraries(PRIVATE ${ARG_BUILD})
    _AddLibraries(PUBLIC ${ARG_INSTALL})
endfunction()

function (SealLake_OptionalBuildSteps)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "IF_ENABLED;IF_ENABLED_AND_STANDALONE;IF_ENABLED_OR_STANDALONE"
        ${ARGN}
    )
    function (getName NAME RESULT)
        string(FIND ${NAME} / SLASH_POS REVERSE)
        string(LENGTH ${NAME} NAME_LENGTH)
        message("${SLASH_POS} ${NAME_LENGTH}")
        MATH(EXPR SLASH_POS "${SLASH_POS} + 1")
        MATH(EXPR RESULT_LENGTH "${NAME_LENGTH} - ${SLASH_POS}")
        string(SUBSTRING ${NAME} ${SLASH_POS} ${RESULT_LENGTH} RESULT_VALUE)
        set(${RESULT} ${RESULT_VALUE} PARENT_SCOPE)
        message("RESULT_VALUE:${RESULT_VALUE}")
    endfunction()

    SealLake_CheckStandalone(IS_STANDALONE)
    foreach (DIR IN ITEMS ${ARG_IF_ENABLED})
        message("Add build step '${DIR}'")
        getName(${DIR} DIRNAME)
        string(TOUPPER ${DIRNAME} DIRNAME)
        set(${ENABLE_${DIRNAME}} "Enable ${DIR}" OFF PARENT_SCOPE)
        if (ENABLE_${DIRNAME})
            add_subdirectory(${DIR})
        endif()
    endforeach()
    foreach (DIR IN ITEMS ${ARG_IF_ENABLED_AND_STANDALONE})
        message("Add build step '${DIR}'")
        getName(${DIR} DIRNAME)
        string(TOUPPER ${DIRNAME} DIRNAME)
        set(${ENABLE_${DIRNAME}} "Enable ${DIR}" OFF PARENT_SCOPE)
        if (ENABLE_${DIRNAME} AND IS_STANDALONE)
            add_subdirectory(${DIR})
        endif()
    endforeach()
    foreach (DIR IN ITEMS ${ARG_IF_ENABLED_OR_STANDALONE})
        message("Add build step '${DIR}'")
        getName(${DIR} DIRNAME)
        string(TOUPPER ${DIRNAME} DIRNAME)
        set(${ENABLE_${DIRNAME}} "Enable ${DIR}" OFF PARENT_SCOPE)
        if (ENABLE_${DIRNAME} OR IS_STANDALONE)
            add_subdirectory(${DIR})
        endif()
    endforeach()
endfunction()

function (SealLake_Install)
    cmake_parse_arguments(
            ARG
            ""
            ""
            "FILES;DIRECTORIES"
            ${ARGN}
    )
    if(ARG_FILES)
        install(FILES ${ARG_FILES} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})
    endif()
    if(ARG_DIRECTORIES)
        install(DIRECTORY ${ARG_DIRECTORIES} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME})
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

function (SealLake_FindOrDownload NAME VERSION)
    cmake_parse_arguments(
        ARG
        ""
        "GIT_REPOSITORY;GIT_TAG"
        ""
        ${ARGN}
    )
    find_package(${NAME} ${VERSION} QUIET)
    if (NOT ${${NAME}_FOUND})
        message("Configuration info: ${NAME} wasn't found on your system, proceeding to downloading it.")
        Set(FETCHCONTENT_QUIET FALSE)
        FetchContent_Declare(
                ${NAME}
                GIT_REPOSITORY  ${ARG_GIT_REPOSITORY}
                GIT_TAG        ${ARG_GIT_TAG}
                GIT_SHALLOW    ON
                GIT_PROGRESS TRUE
        )
        FetchContent_MakeAvailable(${NAME})
    endif()
endfunction()

function (SealLake_FindOrInclude NAME VERSION MODULE)
    find_package(${NAME} ${VERSION} QUIET)
    if (NOT ${${NAME}_FOUND})
        include("${MODULE}")
    endif()
endfunction()

function(SealLake_ReplaceInFiles SRC_FILE_MASK DST_PATH FROM_STR TO_STR)
    file(GLOB SRC_FILES "${SRC_FILE_MASK}")
    foreach(SRC_FILE ${SRC_FILES})
        file(READ "${SRC_FILE}" SRC_FILE_CONTENTS)
        string(REPLACE "${FROM_STR}" "${TO_STR}" DST_FILE_CONTENTS "${SRC_FILE_CONTENTS}")
        get_filename_component(DST_FILE_NAME "${SRC_FILE}" NAME)
        file(WRITE "${DST_PATH}/${DST_FILE_NAME}" "${DST_FILE_CONTENTS}")
    endforeach()
endfunction()