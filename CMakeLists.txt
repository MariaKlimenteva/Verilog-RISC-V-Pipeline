cmake_minimum_required(VERSION 3.15)
project(riscv_pipeline)

find_program(VERILATOR_BIN verilator)
if(NOT VERILATOR_BIN)
    message(FATAL_ERROR "Verilator executable not found in PATH")
endif()

get_filename_component(VERILATOR_BIN_DIR "${VERILATOR_BIN}" DIRECTORY)
get_filename_component(VERILATOR_ROOT "${VERILATOR_BIN_DIR}/.." ABSOLUTE)

set(VERILATOR_INCLUDE_DIR "${VERILATOR_ROOT}/share/verilator/include")
if(NOT EXISTS "${VERILATOR_INCLUDE_DIR}/verilated.h")
    message(FATAL_ERROR "Verilator headers not found in ${VERILATOR_INCLUDE_DIR}")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB_RECURSE VERILOG_SOURCES "src/*.sv" "src/*.v")
file(GLOB_RECURSE INCLUDE_FILES "include/*.vh" "include/*.svh")

set(VERILATOR_FLAGS
    -Wall
    -I${CMAKE_CURRENT_SOURCE_DIR}/src
    -I${CMAKE_CURRENT_SOURCE_DIR}/include
    -Wno-UNUSED
    -Wno-UNDRIVEN
    --Wno-fatal
    --Wno-width
    --trace
    --public-flat-rw
)

set(TOP_MODULE riscv_pipeline_top)

# Создаем кастомную команду для генерации Verilator модели
add_custom_target(verilator_build ALL
    COMMAND ${VERILATOR_BIN}
        --cc ${VERILOG_SOURCES}
        --exe ${CMAKE_CURRENT_SOURCE_DIR}/tb/${TOP_MODULE}_tb.cpp
        --top-module ${TOP_MODULE}
        ${VERILATOR_FLAGS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Building Verilator model"
)
file(GLOB VERILATOR_CPP_FILES ${CMAKE_CURRENT_BINARY_DIR}/obj_dir/*.cpp)

# Создаем исполняемый файл для теста
function(add_riscv_test TEST_NAME)
    add_executable(${TEST_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/tb/${TEST_NAME}_tb.cpp ${VERILATOR_CPP_FILES})
    target_link_libraries(${TEST_NAME} PRIVATE)
        
    target_include_directories(${TEST_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_BINARY_DIR}/obj_dir
        ${VERILATOR_INCLUDE_DIR}
        ${VERILATOR_INCLUDE_DIR}/vltstd
    )

    # Добавляем зависимость, чтобы тест собирался после генерации модели
    add_dependencies(${TEST_NAME} verilator_build)
     # Обеспечить, что файлы из obj_dir скопированы или доступны
    add_custom_command(TARGET verilator_build POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            ${CMAKE_CURRENT_BINARY_DIR}/obj_dir
            ${CMAKE_CURRENT_BINARY_DIR}/obj_dir
    )
    # Добавляем тест через ctest
    add_test(
        NAME ${TEST_NAME}
        COMMAND ${CMAKE_CURRENT_BINARY_DIR}/${TEST_NAME}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endfunction()



# Создаем тесты
set(TEST_NAMES addi forwarding lw_sw stall_bubble_lw branch_jump)
foreach(TEST ${TEST_NAMES})
    add_riscv_test(${TEST})
endforeach()

# Цель для запуска всех тестов
add_custom_target(run_all_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    DEPENDS ${TEST_NAMES}
    COMMENT "Running all tests"
)