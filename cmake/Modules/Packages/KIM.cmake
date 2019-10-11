if(PKG_KIM)
  set(KIM-API_MIN_VERSION 2.1)
  find_package(CURL)
  if(CURL_FOUND)
    include_directories(${CURL_INCLUDE_DIRS})
    list(APPEND LAMMPS_LINK_LIBS ${CURL_LIBRARIES})
    add_definitions(-DLMP_KIM_CURL)
  endif()
  find_package(KIM-API QUIET)
  if(KIM-API_FOUND)
    if (KIM-API_VERSION VERSION_LESS ${KIM-API_MIN_VERSION})
      if ("${DOWNLOAD_KIM}" STREQUAL "")
        message(WARNING "Unsuitable KIM-API version \"${KIM-API_VERSION}\" found, but required is at least \"${KIM-API_MIN_VERSION}\".  Default behavior set to download and build our own.")
      endif()
      set(DOWNLOAD_KIM_DEFAULT ON)
    else()
      set(DOWNLOAD_KIM_DEFAULT OFF)
    endif()
  else()
    if ("${DOWNLOAD_KIM}" STREQUAL "")
      message(WARNING "KIM-API package not found.  Default behavior set to download and build our own")
    endif()
    set(DOWNLOAD_KIM_DEFAULT ON)
  endif()
  option(DOWNLOAD_KIM "Download KIM-API from OpenKIM instead of using an already installed one" ${DOWNLOAD_KIM_DEFAULT})
  if(DOWNLOAD_KIM)
    if(CMAKE_GENERATOR STREQUAL "Ninja")
      message(FATAL_ERROR "Cannot build downloaded KIM-API library with Ninja build tool")
    endif()
    message(STATUS "KIM-API download requested - we will build our own")
    include(CheckLanguage)
    include(ExternalProject)
    enable_language(C)
    check_language(Fortran)
    if(NOT CMAKE_Fortran_COMPILER)
      message(FATAL_ERROR "Compiling the KIM-API library requires a Fortran compiler")
    endif()
    ExternalProject_Add(kim_build
      URL https://s3.openkim.org/kim-api/kim-api-2.1.3.txz
      URL_MD5 6ee829a1bbba5f8b9874c88c4c4ebff8
      BINARY_DIR build
      CMAKE_ARGS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
                 -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
                 -DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
                 -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                 -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      )
    ExternalProject_get_property(kim_build INSTALL_DIR)
    set(KIM-API_INCLUDE_DIRS ${INSTALL_DIR}/include/kim-api)
    set(KIM-API_LDFLAGS ${INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/libkim-api${CMAKE_SHARED_LIBRARY_SUFFIX})
    list(APPEND LAMMPS_DEPS kim_build)
  else()
    find_package(KIM-API ${KIM-API_MIN_VERSION} REQUIRED)
  endif()
  list(APPEND LAMMPS_LINK_LIBS "${KIM-API_LDFLAGS}")
  include_directories(${KIM-API_INCLUDE_DIRS})
endif()