cmake_minimum_required(VERSION 3.20)
project(CDBGRepro NONE)

set(LLVM_BUILD_DIR "" CACHE PATH "LLVM build directory")
option(ENABLE_PSEUDO_TESTS "Include debugging branch pseudo controls" OFF)
if(NOT LLVM_BUILD_DIR)
  message(FATAL_ERROR "Set LLVM_BUILD_DIR to an LLVM build directory")
endif()
get_filename_component(LLVM_BUILD_DIR "${LLVM_BUILD_DIR}" ABSOLUTE)

find_program(OPT opt PATHS "${LLVM_BUILD_DIR}/bin" NO_DEFAULT_PATH REQUIRED)
find_program(LLC llc PATHS "${LLVM_BUILD_DIR}/bin" NO_DEFAULT_PATH REQUIRED)
find_program(FILECHECK FileCheck PATHS "${LLVM_BUILD_DIR}/bin" NO_DEFAULT_PATH REQUIRED)
find_program(LLVM_LIT llvm-lit PATHS "${LLVM_BUILD_DIR}/bin" NO_DEFAULT_PATH REQUIRED)
find_program(CLANG clang PATHS "${LLVM_BUILD_DIR}/bin" NO_DEFAULT_PATH)
find_program(CLANG clang REQUIRED)

configure_file(lit.site.cfg.py.in lit.site.cfg.py @ONLY)
add_custom_target(check
  COMMAND "${LLVM_LIT}" -sv "${CMAKE_CURRENT_BINARY_DIR}"
  USES_TERMINAL VERBATIM)
