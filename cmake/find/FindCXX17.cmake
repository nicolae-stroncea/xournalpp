

if (TARGET cxx17)
    # This module has already been processed. Don't do it again.
    return()
endif ()

include(CMakePushCheckState)
include(CheckIncludeFileCXX)
include(CheckCXXSourceCompiles)

cmake_push_check_state()

set(CMAKE_REQUIRED_QUIET ${})

# All of our tests required C++17 or later
set(CMAKE_CXX_STANDARD 17)
check_include_file_cxx("filesystem" _CXX_FILESYSTEM_HAVE_HEADER)
check_include_file_cxx("optional" _CXX_OPTIONAL_HAVE_HEADER)


string(CONFIGURE [[
        #include <filesystem>
        #include <optional>
        #include <map>
        #include <string>

        void filesystem_support()
        {
        	auto ignore = std::filesystem::exists("Hello World");
        	(void) ignore;
        }

        void map_splicing_support()
        {
        	std::map<int, std::string> id_to_name{{1, "Filip"}, {2, "Magda"}, {3, "Kacper"}, {4, "Apollo"}};
        	std::map<int, std::string> important{{5, "Filip Jr."}};

        	important.insert(id_to_name.extract(2));
        }

        void optional_support()
        {
        	std::optional<int> o = 1;
        	(void) o;
        }

        int main()
        {
        	filesystem_support();
        	map_splicing_support();
        	optional_support();
        	return 0;
        }

    ]] code @ONLY)

# Try to compile a simple filesystem program without any linker flags
check_cxx_source_compiles("${code}" CXX_FILESYSTEM_NO_LINK_NEEDED)

set(can_link ${CXX_FILESYSTEM_NO_LINK_NEEDED})

if (NOT can_link)
    set(prev_libraries ${CMAKE_REQUIRED_LIBRARIES})
    # Add the libstdc++ flag
    set(CMAKE_REQUIRED_LIBRARIES ${prev_libraries} -lstdc++fs)
    check_cxx_source_compiles("${code}" CXX_FILESYSTEM_STDCPPFS_NEEDED)
    set(can_link ${CXX_FILESYSTEM_STDCPPFS_NEEDED})
    if (NOT can_link)
        # Try the libc++ flag
        set(CMAKE_REQUIRED_LIBRARIES ${prev_libraries} -lc++fs)
        check_cxx_source_compiles("${code}" CXX_FILESYSTEM_CPPFS_NEEDED)
        set(can_link ${CXX_FILESYSTEM_CPPFS_NEEDED})
    endif ()
endif ()

if (can_link)
    add_library(cxx17 INTERFACE IMPORTED)
    target_compile_features(cxx17 INTERFACE cxx_std_17)
    set(_found TRUE)

    if (CXX_FILESYSTEM_NO_LINK_NEEDED)
        # Nothing to add...
    elseif (CXX_FILESYSTEM_STDCPPFS_NEEDED)
        target_link_libraries(cxx17 INTERFACE -lstdc++fs)
    elseif (CXX_FILESYSTEM_CPPFS_NEEDED)
        target_link_libraries(cxx17 INTERFACE -lc++fs)
    endif ()
endif ()

cmake_pop_check_state()

set(CXX17_FOUND ${_found} CACHE BOOL "TRUE if we can compile and link a program using cxx17" FORCE)

if (CXX17_FIND_REQUIRED AND NOT CXX17_FOUND)
    message(FATAL_ERROR "Cannot Compile simple program using cxx17")
endif ()
