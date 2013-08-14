cmake_minimum_required(VERSION 2.8)

# VTK, CDAT, NetCDF (with opendap support), NetCDF4Python, use system python

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

#/////////////////////////////////////////////////////////////////////////////
#
# Function to add a package to the superbuild.
#
# DEFAULT: ON OFF SYSTEM
#
#/////////////////////////////////////////////////////////////////////////////
function(add_sb_package)
  extract_args("_name=NAME;_version=VERSION;_groups=GROUPS;_default=DEFAULT" ${ARGN})
  message("name is ${_name}")
  message("version is ${_version}")
  message("groups are ${_groups}")
  message("default is ${_default}")

  # Create convenient names
  string(TOUPPER ${_name} uc_package_name)
  string(TOLOWER ${_name} lc_package_name)

  # Define a variable that could be used to define dependencies
  set(${lc_package_name}_pkg "${_name}")

  # Store the initial state for packages
  set(_use_system_${lc_package_name})
  set(_build_package_${lc_package_name})

  # Create a place holder to store transient state of the packages
  set(_transient_use_system_${lc_package_name} PARENT_SCOPE)
  set(_transient_build_package_${lc_package_name} PARENT_SCOPE)

  set(_use_system_${lc_package_name} OFF)
  set(_build_package_${lc_package_name} ON)

  if("${_default}" STREQUAL "ON")
    set(_build_package_${lc_package_name} ON)
  elseif("${_default}" STREQUAL "OFF")
    set(_build_package_${lc_package_name} OFF)
  elseif("${_default}" STREQUAL "SYSTEM")
    set(_use_system_${lc_package_name} ON)
    set(_build_package_${lc_package_name} OFF)
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

    list(FIND _group_names ${group} ${group}_exists)
    if ("${${group}_exists}" STREQUAL "-1")
      message("[sb:info] Appending group name ${_group_names}")
      list(APPEND _group_names ${group})
    endif()

    # Check if the package is already a part of the group or not
    # if it is skip adding it or else add it to the list of packages
    # group will enable
    list(FIND _${group}_pkgs ${_name} ${_name}_exists_in_${group})
    if(${${_name}_exists_in_${group}} STREQUAL "-1")
      list(APPEND _${group}_pkgs ${_name})
    endif()

    set(_group_names ${_group_names} PARENT_SCOPE)
    set(_${group}_pkgs ${_${group}_pkgs} PARENT_SCOPE)

    message("[sb:debug] group pkgs ${_${group}_pkgs}")
  endforeach()

  set(_use_system_${lc_package_name} ${_use_system_${lc_package_name}} PARENT_SCOPE)
  set(_build_package_${lc_package_name} ${_build_package_${lc_package_name}} PARENT_SCOPE)

  option(SB_BUILD_${uc_package_name} "${message}" ${_build_package_${lc_package_name}})
  mark_as_advanced(SB_BUILD_${uc_package_name})

  option(SB_USE_SYSTEM_${uc_package_name} "${message}" ${_use_system_${lc_package_name}})
  mark_as_advanced(SB_USE_SYSTEM_${uc_package_name})
endfunction()

#/////////////////////////////////////////////////////////////////////////////
#
# Function to create the superbuild
#
#/////////////////////////////////////////////////////////////////////////////
function(execute)
  set(_external_packages)
  create_package_and_groups()
  resolve_package_dependencies()
  create_build_list()
endfunction()

#/////////////////////////////////////////////////////////////////////////////
#
# Helper macro to gather list of packages and groups
#
#/////////////////////////////////////////////////////////////////////////////
macro(create_package_and_groups)
  foreach(group ${_group_names})
    message("[sb:debug] Group is ${group} with pkgs ${_${group}_pkgs}")
    option(SB_ENABLE_${group} "Enable group ${group}" ON)

    # If a group is ON, then eanble all of its packages or else don't build
    # any of its packages (unless this is overriden by dependency walker.
    if (SB_ENABLE_${group})
      foreach(package_name ${_${group}_pkgs})
        string(TOUPPER ${package_name} uc_package_name)
        string(TOLOWER ${package_name} lc_package_name)

        set_property(CACHE SB_USE_SYSTEM_${uc_package_name} PROPERTY VALUE ${_use_system_${lc_package_name}})
        set_property(CACHE SB_BUILD_${uc_package_name} PROPERTY VALUE ${_build_package_${lc_package_name}})

        set(_transient_use_system_${lc_package_name} ${_use_system_${lc_package_name}})
        set(_transient_build_package_${lc_package_name} ${_build_package_${lc_package_name}})

        # Append this package to the global list for all of the packages
        # that will be built by this instance
        list(FIND _external_packages "${package_name}" found_package)
        if("${found_package}"  STREQUAL "-1")
          list(APPEND _external_packages "${package_name}")
        endif()
      endforeach()
    else()
      foreach(package_name ${_${group}_pkgs})
        string(TOUPPER ${package_name} uc_package_name)
        string(TOLOWER ${package_name} lc_package_name)

        if(DEFINED _transient_use_system_${lc_package_name} AND NOT _transient_use_system_${lc_package_name})
          set_property(CACHE SB_USE_SYSTEM_${uc_package_name} PROPERTY VALUE OFF)
        endif()

        if(DEFINED _transient_build_package_${lc_package_name} AND NOT _transient_build_package_${lc_package_name})
          set_property(CACHE SB_BUILD_${uc_package_name} PROPERTY VALUE OFF)
        endif()
      endforeach()
    endif()
  endforeach()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Resolve package dependencies
#
#/////////////////////////////////////////////////////////////////////////////
macro(resolve_package_dependencies)
  include(TopologicalSort)
  message("[sb:debug] Packages: ${_external_packages}")
  foreach(package_name ${_external_packages})
    string(TOLOWER ${package_name} lc_package_name)
    include("${lc_package_name}_deps")
  endforeach()

  topological_sort(_external_packages "" "_deps")

  foreach(package_name ${_external_packages})
    do_resolve_package_deps(${package_name})
  endforeach()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
macro(do_resolve_package_deps package_name)
  message("PACKAGE NAME ${package_name}")
  string(TOUPPER ${package_name} uc_package_name)
  string(TOLOWER ${package_name} lc_package_name)

  message("${SB_BUILD_${uc_package_name}}")

  if(SB_BUILD_${uc_package_name})
    foreach(dep ${${package_name}_deps})
      string(TOUPPER ${dep} uc_dep)
      if(NOT SB_USE_SYSTEM_${uc_dep} AND NOT SB_BUILD_${uc_dep})
        set(SB_BUILD_${uc_dep} ON CACHE BOOL "" FORCE)
        message("[sb:info] Setting build package -- ${dep} ON -- as required by ${package_name}")
      endif()
    endforeach()
  endif()
endmacro()

#/////////////////////////////////////////////////////////////////////////////
#
# Create final build list
#
#/////////////////////////////////////////////////////////////////////////////
macro(create_build_list)
foreach(package ${_external_packages})
  string(TOLOWER ${package} lc_package)
  string(TOUPPER ${package} uc_package)

  if(SB_BUILD_${uc_package})
    message("[sb:info] Package --- ${package} --- will be built")
    list(APPEND packages_info "${package} ${${uc_package}_VERSION}\n")
    include("${lc_package}_external")
  endif()
endforeach()
endmacro()
