set(SEAL_LAKE_LIB "")
set(SEAL_LAKE_DEFAULT_SCOPE "")
include(FetchContent)

function(SealLake_HeaderOnlyLibrary NAME)
    set(SEAL_LAKE_LIB ${NAME} PARENT_SCOPE)
    set(SEAL_LAKE_LIB ${NAME})
    set(SEAL_LAKE_DEFAULT_SCOPE INTERFACE PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE INTERFACE)

    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES"
        ${ARGN}
    )

    add_library(${NAME} INTERFACE)
    add_library("${NAME}::${NAME}" ALIAS ${NAME})
    target_include_directories(
            ${NAME}
            INTERFACE
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
    SealLake_Properties(${ARG_PROPERTIES})
    if (ARG_PROPERTIES)
        set_target_properties(${NAME} PROPERTIES PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS})
    endif()
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})

    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${NAME} VARNAME)
    set(INSTALL_${VARNAME} "Install ${NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endfunction()

function(SealLake_StaticLibrary NAME)
    set(SEAL_LAKE_LIB ${NAME} PARENT_SCOPE)
    set(SEAL_LAKE_LIB ${NAME})
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC)

    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS"
        ${ARGN}
    )

    add_library(${NAME} STATIC ${ARG_SOURCES})
    add_library("${NAME}::${NAME}" ALIAS ${NAME})
    target_include_directories(
            ${NAME}
            PUBLIC
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
    SealLake_Properties(${ARG_PROPERTIES})
    if (ARG_PROPERTIES)
        set_target_properties(${NAME} PROPERTIES PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS})
    endif()
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})

    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${NAME} VARNAME)
    set(INSTALL_${VARNAME} "Install ${NAME}" OFF PARENT_SCOPE)
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(TARGETS ${NAME}
                ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
                PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${NAME}"
        )
        if (NOT ARG_PUBLIC_HEADERS)
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endfunction()

function(SealLake_ObjectLibrary NAME)
    set(SEAL_LAKE_LIB ${NAME} PARENT_SCOPE)
    set(SEAL_LAKE_LIB ${NAME})
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC)

    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS"
        ${ARGN}
    )

    add_library(${NAME} OBJECT ${ARG_SOURCES})
    add_library("${NAME}::${NAME}" ALIAS ${NAME})
    target_include_directories(
            ${NAME}
            PUBLIC
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    SealLake_Properties(${ARG_PROPERTIES})
    if (ARG_PROPERTIES)
        set_target_properties(${NAME} PROPERTIES PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS})
    endif()
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})

    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${NAME} VARNAME)
    set(INSTALL_${VARNAME} "Install ${NAME} library unconditionally" OFF PARENT_SCOPE)
    message("Install is set: ${INSTALL_${VARNAME}}")
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(TARGETS ${NAME}
                ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
                PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${NAME}"
        )
        if (NOT ARG_PUBLIC_HEADERS)
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endfunction()

function(SealLake_SharedLibrary NAME)
    set(SEAL_LAKE_LIB ${NAME} PARENT_SCOPE)
    set(SEAL_LAKE_LIB ${NAME})
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC PARENT_SCOPE)
    set(SEAL_LAKE_DEFAULT_SCOPE PUBLIC)

    cmake_parse_arguments(
        ARG
        ""
        ""
        "PROPERTIES;COMPILE_FEATURES;SOURCES;PUBLIC_HEADERS"
        ${ARGN}
    )


    add_library(${NAME} SHARED ${ARG_SOURCES})
    add_library("${NAME}::${NAME}" ALIAS ${NAME})
    target_include_directories(
            ${NAME}
            PUBLIC
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )

    SealLake_Properties(${ARG_PROPERTIES})
    set_target_properties(${NAME} PROPERTIES PUBLIC_HEADERS ${ARG_PUBLIC_HEADERS})
    SealLake_CompileFeatures(${ARG_COMPILE_FEATURES})

    SealLake_CheckStandalone(IS_STANDALONE)
    string(TOUPPER ${NAME} VARNAME)
    set(INSTALL_${VARNAME} "Install ${NAME} library unconditionally" OFF PARENT_SCOPE)
    message("Install is set: ${INSTALL_${VARNAME}}")
    if (IS_STANDALONE OR INSTALL_${VARNAME})
        install(TARGETS ${NAME}
                LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
                PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${NAME}"
        )
        if (NOT ARG_PUBLIC_HEADERS)
            install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/${NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
        endif()
        SealLake_InstallPackage(COMPATIBILITY SameMajorVersion)
    endif()
endfunction()

function (SealLake_GoogleTest NAME)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "SOURCES;LIBRARIES"
        ${ARGN}
    )
    enable_testing()
    find_package(Threads REQUIRED)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    include(GoogleTest)
    add_executable(${NAME} ${ARG_SOURCES})
    add_test(NAME ${NAME} COMMAND ${NAME})
    target_link_libraries(${NAME} PRIVATE ${ARG_LIBRARIES} Threads::Threads GTest::gtest_main)
    gtest_discover_tests(${NAME})
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
                set_target_properties(${SEAL_LAKE_LIB} PROPERTIES ${PROPERTY_NAME} "${PROPERTY_VALUE}")
            endif()
        endforeach()
    endif()
endfunction()

function (SealLake_CompileFeatures)
     foreach(FEATURE IN ITEMS ${ARGN})
        target_compile_features(${SEAL_LAKE_LIB} ${SEAL_LAKE_DEFAULT_SCOPE} ${FEATURE})
     endforeach()
endfunction()

function (SealLake_IncludeDirectoryInstall PATH)
     target_include_directories(
            ${SEAL_LAKE_LIB}
            PUBLIC
            $<INSTALL_INTERFACE:"${CMAKE_INSTALL_INCLUDEDIR}/${PATH}">
    )
endfunction()

function (SealLake_IncludeDirectoryBuild PATH)
    target_include_directories(
            ${SEAL_LAKE_LIB}
            ${SEAL_LAKE_DEFAULT_SCOPE}
            $<BUILD_INTERFACE:"${CMAKE_INSTALL_INCLUDEDIR}/${PATH}">
    )
endfunction()

function (SealLake_IncludePathInstall PATH)
     target_include_directories(
            ${SEAL_LAKE_LIB}
            PUBLIC
            $<INSTALL_INTERFACE:"${CMAKE_INSTALL_INCLUDEDIR}/${PATH}">
    )
endfunction()

function (SealLake_IncludePathBuild PATH)
    target_include_directories(
            ${SEAL_LAKE_LIB}
            ${SEAL_LAKE_DEFAULT_SCOPE}
            $<BUILD_INTERFACE:"${CMAKE_INSTALL_INCLUDEDIR}/${PATH}">
    )
endfunction()

function (SealLake_OptionalBuildSteps)
    list(LENGTH ARGN PROPERTIES_LENGTH)
    MATH(EXPR PROPERTY_LAST_INDEX "${PROPERTIES_LENGTH} - 2")
    if (PROPERTIES_LENGTH GREATER 1)
        foreach(PROPERTY_INDEX RANGE 0 ${PROPERTY_LAST_INDEX} 2)
            list(GET ARGN ${PROPERTY_INDEX} STEP_TYPE)
            MATH(EXPR PROPERTY_INDEX "${PROPERTY_INDEX}+1")
            list(GET ARGN ${PROPERTY_INDEX} STEP_NAME)

            if(NOT STEP_TYPE STREQUAL IF_ENABLED AND
               NOT STEP_TYPE STREQUAL IF_ENABLED_AND_STANDALONE AND
               NOT STEP_TYPE STREQUAL IF_ENABLED_OR_STANDALONE)
               message(WARNING "Unsupported build step type: ${STEP_TYPE}")
               continue()
            endif()

            SealLake_CheckStandalone(IS_STANDALONE)
            message("Add build step '${STEP_NAME}'")
            string(TOUPPER ${STEP_NAME} STEP_VARNAME)
            set(ENABLE_${STEP_VARNAME} "Enable ${NAME}" OFF PARENT_SCOPE)
            if(STEP_TYPE STREQUAL IF_ENABLED)
                if (ENABLE_${STEP_VARNAME})
                    add_subdirectory(${STEP_NAME})
                endif()
            elseif(STEP_TYPE STREQUAL IF_ENABLED_AND_STANDALONE)
                if (ENABLE_${STEP_VARNAME} AND IS_STANDALONE)
                    add_subdirectory(${STEP_NAME})
                endif()
            elseif(STEP_TYPE STREQUAL IF_ENABLED_OR_STANDALONE)
                if (ENABLE_${STEP_VARNAME} OR IS_STANDALONE)
                    add_subdirectory(${STEP_NAME})
                endif()
            endif()
        endforeach()
    endif()
endfunction()

function (SealLake_InstallDirectories)
install(DIRECTORY "${ARGN}" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${SEAL_LAKE_LIB})
endfunction()

function (SealLake_InstallFiles)
install(DIRECTORY "${ARGN}" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${SEAL_LAKE_LIB})
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
    set(PACK_PATH "${CMAKE_INSTALL_LIBDIR}/cmake/${SEAL_LAKE_LIB}")

    install(TARGETS "${SEAL_LAKE_LIB}"
            EXPORT "${SEAL_LAKE_LIB}-targets"
    )
    install(EXPORT "${SEAL_LAKE_LIB}-targets"
            FILE "${SEAL_LAKE_LIB}Targets.cmake"
            NAMESPACE "${SEAL_LAKE_LIB}::"
            DESTINATION "${PACK_PATH}"
    )

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_LIB}ConfigVersion.cmake"
            COMPATIBILITY "${ARG_COMPATIBILITY}"
            ARCH_INDEPENDENT
    )
    configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/cmake/${SEAL_LAKE_LIB}Config.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_LIB}Config.cmake"
            INSTALL_DESTINATION "${PACK_PATH}"
    )
    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_LIB}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${SEAL_LAKE_LIB}ConfigVersion.cmake"
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
    if (ARG_GIT_REPOSITORY STREQUAL "https://github.com/google/googletest.git")
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    endif()

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