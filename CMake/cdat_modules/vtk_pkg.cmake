set(VTK_MAJOR 6)
set(VTK_MINOR 0)
set(VTK_PATCH 0)
set(VTK_VERSION ${VTK_MAJOR}.${VTK_MINOR}.${VTK_PATCH})
set(VTK_URL git://github.com/OpenGeoscience/VTK.git)

#set(VTK_GZ ParaView-${VTK_VERSION}c.tar.gz)
#set(VTK_MD5 81565b70093784dea38d2d62e072287b)

add_sb_package(NAME vtk GROUPS "VIS;VIS-HPC" DEFAULT ON)
