find_package(Threads REQUIRED)

set(LIBYARA_SOURCES
    ahocorasick.c
    arena.c
    atoms.c
    compiler.c
    endian.c
    exec.c
    exefiles.c
    filemap.c
    grammar.c
    hash.c
    hex_grammar.c
    hex_lexer.c
    lexer.c
    libyara.c
    mem.c
    modules.c
    object.c
    parser.c
    proc.c
    re.c
    re_grammar.c
    re_lexer.c
    rules.c
    scan.c
    sizedstr.c
    stopwatch.c
    stream.c
    strutils.c
    threading.c)

# Modules.
list(APPEND LIBYARA_SOURCES
    modules/elf.c
    modules/math.c
    modules/pe.c
    modules/pe_utils.c
    modules/tests.c
    modules/time.c)

# Proc.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND LIBYARA_SOURCES proc/linux.c)
endif()

# Library.
add_library(libyara ${LIBYARA_SOURCES})

# Compiler defines.
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(libyara PUBLIC USE_LINUX_PROC)
endif()

# Link dependencies.
target_link_libraries(libyara ${CMAKE_THREAD_LIBS_INIT})
if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_link_libraries(libyara m)
endif()

# Target 'libyara' would produce liblibyara filename, so override it
set_target_properties(libyara PROPERTIES PREFIX "")
set_target_properties(libyara PROPERTIES OUTPUT_NAME "libyara")

# Bind include directories to 'libyara' target.
target_include_directories(libyara PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(libyara PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")