set(SPHINX_MAJOR_SRC 1)
set(SPHINX_MINOR_SRC 2)
set(SPHINX_PATCH_SRC b1)

set (nm SPHINX)
string(TOUPPER ${nm} uc_nm)
set(${uc_nm}_VERSION ${${nm}_MAJOR_SRC}.${${nm}_MINOR_SRC}.${${nm}_PATCH_SRC})
add_sb_package(NAME Sphinx GROUPS "WO_ESGF" OFF)

