set(VTK_MAJOR 6)
set(VTK_MINOR 0)
set(VTK_PATCH 0)
set(VTK_VERSION ${VTK_MAJOR}.${VTK_MINOR}.${VTK_PATCH})
#set(VTK_URL git://github.com/OpenGeoscience/VTK.git)
set(VTK_URL git://vtk.org/VTK.git)

add_sb_package(NAME vtk GROUPS "VIS;HPC" DEFAULT ON)
