set(vtk_source "${CMAKE_CURRENT_BINARY_DIR}/build/vtk")
set(vtk_binary "${CMAKE_CURRENT_BINARY_DIR}/build/vtk-build")
set(vtk_install "${cdat_EXTERNALS}")

ExternalProject_Add(vtk
  DOWNLOAD_DIR ${CDAT_PACKAGE_CACHE_DIR}
  SOURCE_DIR ${vtk_source}
  BINARY_DIR ${vtk_build}
  INSTALL_DIR ${vtk_install}
  GIT_REPOSITORY ${VTK_URL}
  PATCH_COMMAND ""
  CMAKE_CACHE_ARGS
    -DBUILD_SHARED_LIBS:BOOL=ON
    -DBUILD_TESTING:BOOL=OFF
    -DCMAKE_CXX_FLAGS:STRING=${cdat_tpl_cxx_flags}
    -DCMAKE_C_FLAGS:STRING=${cdat_tpl_c_flags}
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_CFG_INTDIR}
    ${cdat_compiler_args}
    -DVTK_WRAP_PYTHON:BOOL=ON
    -DVTK_LEGACY_SILENT:BOOL=ON
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
  DEPENDS ${vtk_deps}
  ${ep_log_options}
)
