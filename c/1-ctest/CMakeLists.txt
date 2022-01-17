cmake_minimum_required(VERSION 3.5)

project(ctest_ex VERSION 1.0)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED True)
configure_file(include/config.h.in "${CMAKE_CURRENT_SOURCE_DIR}/include/config.h")

add_executable(ctest_ex
    "${CMAKE_CURRENT_SOURCE_DIR}/src/main.c")
target_include_directories(ctest_ex PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include")
set_target_properties(ctest_ex
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")

add_executable(ctest_test
    "${CMAKE_CURRENT_SOURCE_DIR}/test/main.c")
enable_testing()
add_test(
    NAME example_tests
    COMMAND $<TARGET_FILE:ctest_test>
    )
