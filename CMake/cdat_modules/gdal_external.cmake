set(gdal_source "${CMAKE_CURRENT_BINARY_DIR}/build/gdal")
set(gdal_install "${cdat_EXTERNALS}")

set(_args --prefix=<INSTALL_DIR>)

if (SB_ENABLE_TIFF STREQUAL "ON")
  list(APPEND _args --with-libtiff=<INSTALL_DIR>)
endif()

if (SB_ENABLE_NETCDF)
  list(APPEND _args --with-netcdf=<INSTALL_DIR>)
endif()

ExternalProject_Add(gdal
  DOWNLOAD_DIR ${CDAT_PACKAGE_CACHE_DIR}
  SOURCE_DIR ${gdal_source}
  INSTALL_DIR ${gdal_install}
  URL ${GDAL_URL}/${GDAL_GZ}
  URL_MD5 ${GDAL_MD5}
  BUILD_IN_SOURCE 1
  PATCH_COMMAND ""
  CONFIGURE_COMMAND <SOURCE_DIR>/configure ${_args}
  DEPENDS "${gdal_deps}"
  ${ep_log_options}
)
