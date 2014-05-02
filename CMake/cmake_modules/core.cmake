cmake_minimum_required(VERSION 2.8)

include(PythonPackageInfo)

#/////////////////////////////////////////////////////////////////////////////
#
# Rules:
# 1. Turning ON a group sets packages that belong to that group to their
# default state.
#
# 2. Turning OFF a group turns off packages, unless some other group is still on
# that also requires the package.
#
# 3. If a package's default state is ON or SYSTEM and some group that requires it
# is ON. Then the user can turn if from ON to SYSTEM of vice-versa.
#
# 4. If a package's default state is OFF, and no groups that require it are ON,
# then the user can change it to OFF, ON, or SYSTEM.
#/////////////////////////////////////////////////////////////////////////////

#/////////////////////////////////////////////////////////////////////////////
#
# Marcro to extract key-value from the template
#
#/////////////////////////////////////////////////////////////////////////////
macro(__parse_extract_template template)
  set(_vars "")
  set(_extra "")

  foreach(pair ${template})
    string(REGEX MATCH "^[^=]+" varname "${pair}")
    string(REGEX REPLACE "^[^=]+=" "" token "${pair}")
    if("x_${varname}" STREQUAL "x_" OR "x_${token}" STREQUAL "x_")
      message(FATAL_ERROR "extract_args: bad variable/token pair '${pair}'")
    endif()
    set(${varname} "")
    set(__var_for_token_${token} "${varname}")
    list(APPEND _vars "${varname}")
  endforeach()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Function to extract key-value+extra from the argument list
#
#/////////////////////////////////////////////////////////////////////////////
function(extract_args template)
  __parse_extract_template("${template}")
  set(_var "")

  foreach(arg ${ARGN})
    # Skip empty args
    if(NOT "x_${arg}" STREQUAL "x_")
      # Test if arg is a token
      if(NOT "x_${__var_for_token_${arg}}" STREQUAL "x_")
        set(_var "${__var_for_token_${arg}}")
      # Not a token; test if we have a current token
      elseif(NOT "x_${_var}" STREQUAL "x_")
        # Add arg to named list
        list(APPEND ${_var} "${arg}")
      else()
        # Add arg to leftovers list
        list(APPEND _extra "${arg}")
      endif()
    endif()
  endforeach()

  # Raise lists to parent scope
  foreach(varname ${_vars})
    set(${varname} "${${varname}}" PARENT_SCOPE)
  endforeach()

  # Shift ARGN
  set(ARGN "${_extra}" PARENT_SCOPE)
endfunction()

macro(add_sb_python_package)
  set(_tmp ${ARGN})
  list(APPEND _tmp PYTHON_PACKAGE TRUE)
  add_sb_package(${_tmp})
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Function to add a package to the superbuild.
#
# example: add_sb_package(NAME vtk VERSION 6.0.0 GROUPS VIS;CLIMATE DEFAULT ON)
#
#/////////////////////////////////////////////////////////////////////////////
function(add_sb_package)
  extract_args("_name=NAME;_version=VERSION;_groups=GROUPS;_default=DEFAULT;_python=PYTHON_PACKAGE" ${ARGN})

  if ( "${_python}" STREQUAL "")
    set(_python FALSE)
  endif()

  #message("")
  #message("[sb:info] ///////Adding [${_name}]///////")
  #message("[sb:info] Package version is [${_version}]")
  #message("[sb:info] Package groups are [${_groups}]")
  #message("[sb:info] Default state is [${_default}]")

  # Create convenient names
  string(TOUPPER ${_name} uc_package_name)
  string(TOLOWER ${_name} lc_package_name)

  # Store the initial state for this package
  set(_enable_package_${lc_package_name} ${_default})

  # Create a place holder to store transient state of the packages
  set(_enable_package_${lc_package_name} PARENT_SCOPE)

  # Remember what groups this package belongs to
  if (_groups)
    list(LENGTH _groups _num_groups)
    #message("[sb:info] ${lc_package_name} belongs to ${_groups} ${_num_groups}")
    set(_package_${lc_package_name}_groups ${_groups} PARENT_SCOPE)
  endif()

  # Find all the groups this package belongs to and then
  # append this package to each group
  foreach(group ${_groups})
    if(NOT DEFINED _group_names)
      set(_group_names)
    endif()

    if(NOT DEFINED _group_pkgs)
      set(_group_pkgs)
    endif()

    # If this is the first time this group has been seen, remember it
    list(FIND _group_names ${group} ${group}_exists)
    if ("${${group}_exists}" STREQUAL "-1")
      list(APPEND _group_names ${group})
    endif()

    # If this package is not yet part of this group, add it to the list
    # of packages that the group controls.
    list(FIND _${group}_pkgs ${_name} ${_name}_exists_in_${group})
    if(${${_name}_exists_in_${group}} STREQUAL "-1")
      list(APPEND _${group}_pkgs ${_name})
    endif()

    set(_group_names ${_group_names} PARENT_SCOPE)
    set(_${group}_pkgs ${_${group}_pkgs} PARENT_SCOPE)
  endforeach()

  set(_enable_package_${lc_package_name} ${_enable_package_${lc_package_name}} PARENT_SCOPE)

  set(SB_ENABLE_${uc_package_name} "${_enable_package_${lc_package_name}}" CACHE STRING "${message}")
  #for cmake-gui
  set_property(CACHE SB_ENABLE_${uc_package_name} PROPERTY STRINGS OFF ON SYSTEM)

  #for everything else
  if (NOT SB_ENABLE_${uc_package_name} STREQUAL "OFF" AND
      NOT SB_ENABLE_${uc_package_name} STREQUAL "ON" AND
      NOT SB_ENABLE_${uc_package_name} STREQUAL "SYSTEM")
    message("WARNING: ${uc_package_name} is set ${SB_ENABLE_${uc_package_name}}. Packages must be either set to OFF, ON, or SYSTEM. Setting it to OFF.")
    set(SB_ENABLE_${uc_package_name} OFF CACHE STRING "${message}" FORCE)
  endif()
  mark_as_advanced(SB_ENABLE_${uc_package_name})

  if(SB_ENABLE_${uc_package_name} STREQUAL "SYSTEM")

    if(NOT _python)
        if(DEFINED _version)
          find_package(${_name} ${_version})
        else()
          find_package(${_name})
        endif()

        if(NOT ${_name}_FOUND AND NOT ${uc_package_name}_FOUND)
          message(FATAL_ERROR "[sb:error] Unable to find system package ${_name}")
        endif()
    # Python package so query Python for installed version
    else()
      unset(_installed_version)
      python_package_version(${_name} _installed_version)

      if(_installed_version)
        if(NOT "" STREQUAL "${_version}")
          if(_installed_version VERSION_EQUAL _version OR
             _installed_version VERSION_GREATER _version)
            message("[INFO] We have ${_name} ${_installed_version} installed")
          else()
            message(FATAL_ERROR "[sb:error] Unable to find required version Python package ${_name}, ${_version} is required, ${_installed_version} is installed")
          endif()
        else()
          message(WARNING "[sb:warning] No required version specified for Python package ${_name}")
        endif()
      else()
          message(FATAL_ERROR "[sb:error] Unable to find Python package ${_name}")
      endif()
    endif()

  endif()
endfunction()

#/////////////////////////////////////////////////////////////////////////////
#
# Function to create the superbuild
#
#/////////////////////////////////////////////////////////////////////////////
macro(_execute)
  set(_external_packages)
  _create_package_and_groups()
  _resolve_package_dependencies()
  _create_build_list()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Helper macro to gather list of packages and groups
#
#/////////////////////////////////////////////////////////////////////////////
macro(_add_external_package package_name)
  string(TOUPPER ${package_name} uc_package_name)
  string(TOLOWER ${package_name} lc_package_name)

  # Check if the package already exists in the list of external packages
  list(FIND _external_packages "${package_name}" found_package)

  # If yes, and if we need to build it, add it to the list
  if("${found_package}"  STREQUAL "-1")
    if (SB_ENABLE_${uc_package_name} STREQUAL "ON")
      # Define a variable that could be used to define dependencies
      set(${lc_package_name}_pkg "${package_name}")
      list(APPEND _external_packages "${package_name}")
    endif()
  endif()
endmacro()

macro(_remove_external_package package_name)
  string(TOUPPER ${package_name} uc_package_name)
  string(TOLOWER ${package_name} lc_package_name)

  # Check if the package already exists in the list of external packages
  list(FIND _external_packages "${package_name}" found_package)

  # If yes, and if don't need to build it, then remove it from the list
  if(NOT "${found_package}" STREQUAL "-1")
    if (NOT SB_ENABLE_${uc_package_name} STREQUAL "ON")
      list(REMOVE _external_packages "${package_name}")
      unset(${${lc_package_name}_pkg})
    endif()
  endif()
endmacro()

macro(_create_package_and_groups)
  #message("")
  foreach(group ${_group_names})
    message("[sb:info] Group [${group}] has [${_${group}_pkgs}]")
    option(SB_ENABLE_${group} "Enable group ${group}" ON)

    # If a group is ON, then set all of its packages to their default state.
    if (SB_ENABLE_${group})
      foreach(package_name ${_${group}_pkgs})
        string(TOUPPER ${package_name} uc_package_name)
        string(TOLOWER ${package_name} lc_package_name)

        if (SB_ENABLE_${uc_package_name} STREQUAL "OFF")
          #turn to ON/SYSTEM if package wants it that way
          set_property(CACHE SB_ENABLE_${uc_package_name}
                         PROPERTY VALUE ${_enable_package_${lc_package_name}})
        else()
          if ("${_enable_package_${lc_package_name}}" STREQUAL "OFF")
            #turn to OFF if package wants it that way
            set_property(CACHE SB_ENABLE_${uc_package_name}
                         PROPERTY VALUE ${_enable_package_${lc_package_name}})
          endif()
        endif()

        if(SB_ENABLE_${uc_package_name} STREQUAL "SYSTEM")
          if(${uc_package_name}_INCLUDE_DIR)
            list(APPEND found_system_include_dirs ${${uc_package_name}_INCLUDE_DIR})
          endif()
          if(${uc_package_name}_LIBRARY)
            get_filename_component(lib_path ${${uc_package_name}_LIBRARY} PATH)
            list(APPEND found_system_libraries ${lib_path})
          endif()
        endif()

        set(_package_state_${lc_package_name} ${_enable_package_${lc_package_name}})

        _add_external_package(${package_name})

      endforeach()
    else()
      foreach(package_name ${_${group}_pkgs})
        string(TOUPPER ${package_name} uc_package_name)
        string(TOLOWER ${package_name} lc_package_name)

        # If any other group still needs this package, do nothing otherwise turn it off
        list(LENGTH _package_${lc_package_name}_groups _num_groups)
        set(_all_off TRUE)
        foreach(group ${_package_${lc_package_name}_groups})
           if (${SB_ENABLE_${group}})
             set(_all_off FALSE)
           endif()
        endforeach()
        if (_all_off)
           if (NOT ${_enable_package_${lc_package_name}} STREQUAL "OFF")
             set_property(CACHE SB_ENABLE_${uc_package_name}
                         PROPERTY VALUE "OFF")
           endif()
        endif()

        _remove_external_package(${package_name})

      endforeach()
    endif()
  endforeach()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Resolve package dependencies
#
#/////////////////////////////////////////////////////////////////////////////
macro(_resolve_package_dependencies)
  # First unset variable related to packages that we are not going to build
  # like paraview_pkg so that others won't look for it as dependency
  foreach(package_name ${_external_packages})
    string(TOLOWER ${package_name} lc_package_name)
    string(TOUPPER ${package_name} uc_package_name)

    if(NOT SB_ENABLE_${uc_package_name})
      _remove_external_package(${package_name})
    endif()
  endforeach()

  foreach(package_name ${_external_packages})
    string(TOLOWER ${package_name} lc_package_name)
    include("${lc_package_name}_deps")
  endforeach()

  foreach(package_name ${_external_packages})
    _do_resolve_package_deps(${package_name})
  endforeach()

  include(TopologicalSort)
  topological_sort(_external_packages "" "_deps")
  #message("[sb:info] External Packages are [${_external_packages}]")
endmacro()

#/////////////////////////////////////////////////////////////////////////////
macro(_enable_sb_package package_name)
  string(TOUPPER ${package_name} uc_package_name)
  string(TOLOWER ${package_name} lc_package_name)

  # Enable the package
  set_property(CACHE SB_ENABLE_${uc_package_name} PROPERTY VALUE ON)

  # Add this package to the list
  _add_external_package(package_name)

  # Include package dependencies
  include("${lc_package_name}_deps")

  # Resolve dependency for this package now
  _do_resolve_package_deps(${package_name})
endmacro()

#/////////////////////////////////////////////////////////////////////////////
macro(_do_resolve_package_deps package_name)
  string(TOUPPER ${package_name} uc_package_name)
  string(TOLOWER ${package_name} lc_package_name)

  if(SB_ENABLE_${uc_package_name} STREQUAL "ON")

    foreach(dep_package_name ${${package_name}_deps})
      string(TOUPPER ${dep_package_name} uc_dep_package_name)
      if(NOT SB_ENABLE_${uc_dep_package_name})
        _enable_sb_package(${uc_dep_package_name})
        message("[sb:info] Setting -- ${dep_package_name} ON -- as
                 required by ${package_name}")
      endif()
    endforeach()
  endif()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Create final build list
#
#/////////////////////////////////////////////////////////////////////////////
macro(_create_build_list)
#message("")
foreach(package ${_external_packages})
  string(TOLOWER ${package} lc_package)
  string(TOUPPER ${package} uc_package)

  if(SB_ENABLE_${uc_package} STREQUAL "ON")
    message("[sb:info] Package --- ${package} --- will be built")
    list(APPEND packages_info "${package} ${${uc_package}_VERSION}\n")
    include("${lc_package}_external")
  endif()
endforeach()
#message("")
endmacro()
