# PyQt
#
set(PyQt_source "${CMAKE_CURRENT_BINARY_DIR}/build/PyQt")
message("[INFO] Using environment PYTHONPATH \"$ENV{PYTHONPATH}\"")

set(sip_token "")
set(sip_include_dir_token "")

if (SB_BUILD_SIP)
  set(sip_token "--sip=${sip_binary_dir}/sip")
  set(sip_include_dir_token "--sip-incdir=${sip_include_dir}")
endif()

set(PyQt_configure_command env PYTHONPATH=$ENV{PYTHONPATH} ${PYTHON_EXECUTABLE} configure-ng.py
      -q ${QT_QMAKE_EXECUTABLE} --confirm-license -b ${CMAKE_INSTALL_PREFIX}/bin
      -d ${PYTHON_SITE_PACKAGES} -v ${CMAKE_INSTALL_PREFIX}/include
      -v ${CMAKE_INSTALL_PREFIX}/share --designer-plugindir ${CMAKE_INSTALL_PREFIX}/share/plugins
      -n ${CMAKE_INSTALL_PREFIX}/share/qsci ${sip_token} ${sip_include_dir_token}
      --assume-shared -e QtGui -e QtHelp -e QtMultimedia -e QtNetwork -e QtDeclarative -e QtOpenGL
      -e QtScript -e QtScriptTools -e QtSql -e QtSvg -e QtTest -e QtWebKit -e QtXml
      -e QtXmlPatterns -e QtCore)

ExternalProject_Add(PyQt
  DOWNLOAD_DIR ${CDAT_PACKAGE_CACHE_DIR}
  SOURCE_DIR ${PyQt_source}
  URL ${PYQT_URL}/${PYQT_GZ_${CMAKE_PLATFORM}}
  URL_MD5 ${PYQT_MD5_${CMAKE_PLATFORM}}
  BUILD_IN_SOURCE 1
  CONFIGURE_COMMAND ${PyQt_configure_command}
  DEPENDS ${PyQt_deps}
  ${ep_log_options}
)
