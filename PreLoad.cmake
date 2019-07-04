## Fix for windows
if (WIN32)
	set (CMAKE_GENERATOR "CodeBlocks - Ninja" CACHE INTERNAL "" FORCE)
endif ()
