-- -*- lua -*-
-- -- vim:ft=lua:et:ts=4
--

local pkg = {}
local appsroot = appsRoot()

-- get module name/version and build paths
pkg.name = myModuleName()
pkg.version = myModuleVersion()
pkg.id = pathJoin(pkg.name, pkg.version)

app.root   = pathJoin("/hpc/apps/", pkg.name, pkg.version)
app.mpi_path = pathJoin(app.root, "ompi")

hpcx.root = "/hpc/apps/hpcx/2.19"

-- family: Only one thing in a family can be loaded
family("hpcx")

-- this thing will likely conflict w/ versions of openmpi
conflict("mpi")

-- Set the environment variables
setenv("HPCX_DIR", app.root)
setenv("HPCX_HOME", app.root)
--
setenv("HPCX_UCX_DIR", pathJoin(app.root, "ucx"))
setenv("HPCX_UCC_DIR", pathJoin(app.root, "ucc"))
setenv("HPCX_SHARP_DIR", pathJoin(app.root, "sharp"))
setenv("HPCX_HCOLL_DIR", pathJoin(app.root, "hcoll"))
setenv("HPCX_NCCL_RDMA_SHARP_PLUGIN_DIR", pathJoin(app.root, "nccl-rdma-sharp-plugin"))
-- 
setenv("HPCX_CLUSTERKIT_DIR", pathJoin(app.root, "clusterkit"))
setenv("HPCX_MPI_DIR", pathJoin(app.mpi_path))
setenv("HPCX_OSHMEM_DIR", pathJoin(app.mpi_path))
setenv("HPCX_MPI_TESTS_DIR", pathJoin(app.mpi_path, "mpi-tests"))
setenv("HPCX_OSU_DIR", pathJoin(app.mpi_path, "osu"))

-- setting up the PATH, LD_LIBRARY_PATH, and LIBRARY_PATH, CPATH and PKG_CONFIG_PATH
-- PATH
prepend_path("PATH", pathJoin(app.root, "ucx/bin"))
prepend_path("PATH", pathJoin(app.root, "ucc/bin"))
prepend_path("PATH", pathJoin(app.root, "hcoll/bin"))
prepend_path("PATH", pathJoin(app.root, "sharp/bin"))
prepend_path("PATH", pathJoin(app.mpi_path, "tests/imb"))
prepend_path("PATH", pathJoin(app.root, "clusterkit/bin"))

-- LD_LIBRARY_PATH
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "ucx/lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "ucx/lib/ucx"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "ucc/lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "ucc/lib/ucc"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "hcoll/lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "sharp/lib"))
prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "nccl_rdma_sharp_plugin/lib"))

-- LIBRARY_PATH
prepend_path("LIBRARY_PATH", pathJoin(app.root, "ucx/lib"))
prepend_path("LIBRARY_PATH", pathJoin(app.root, "ucc/lib"))
prepend_path("LIBRARY_PATH", pathJoin(app.root, "hcoll/lib"))
prepend_path("LIBRARY_PATH", pathJoin(app.root, "sharp/lib"))
prepend_path("LIBRARY_PATH", pathJoin(app.root, "nccl_rdma_sharp_plugin/lib"))

-- CPATH
prepend_path("CPATH", pathJoin(app.root, "hcoll/include"))
prepend_path("CPATH", pathJoin(app.root, "sharp/include"))
prepend_path("CPATH", pathJoin(app.root, "ucx/include"))
prepend_path("CPATH", pathJoin(app.root, "ucc/include"))
prepend_path("CPATH", pathJoin(app.mpi_path, "include"))

-- PKG_CONFIG_PATH
prepend_path("PKG_CONFIG_PATH", pathJoin(app.root, "hcoll/lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(app.root, "sharp/lib/pkgconfig))
prepend_path("PKG_CONFIG_PATH", pathJoin(app.root, "ucx/lib/pkgconfig"))
prepend_path("PKG_CONFIG_PATH", pathJoin(app.root, "ompi/lib/pkgconfig"))

-- MANPATH
prepend_path("MANPATH", pathJoin(app.root, "share/man"))

-- Included openmpi stuff 
setenv("OPAL_PREFIX", app.root)
setenv("PMIX_INSTALL_PREFIX", app.root)
setenv("OMPI_HOME", app.root)
setenv("MPI_HOME", app.root)
setenv("OSHMEM_HOME", app.root)
setenv("SHMEM_HOME", app.root)


prepend_path("PATH", pathJoin(app.mpi_path, "bin")
prepend_path("LD_LIBRARY_PATH", pathJoin(app.mpi_path, "lib")
prepend_path("LIBRARY_PATH", pathJoin(app.mpi_path, "lib")







-------------------------------------------------------------------------------------
-- Our whatis info for this module.
whatis("Name: hpcx")
whatis("Version: " .. pkg.version)
whatis("Category: toolkit")
whatis("Keywords: mpi, hpcx, openmpi, ucx, rdma, infiniband, mellanox")
whatis("Description: NVIDIA HPC-X toolkit") 
whatis("URL: https://developer.nvidia.com/networking/hpc-x")

-- Help message for users. Should point to documentation.
local help_message = [[
    The base environment for HPC-X
    
    https://docs.nvidia.com/networking/display/hpcxv215/installing+and+loading+hpc-x
    ]]
    
    help(help_message,"\n")


-- prepend_path("PATH", pathJoin(app.root, "bin"))
-- prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "lib64"))
-- prepend_path("C_PATH", pathJoin(app.root, "include"))
-- prepend_path("MANPATH", pathJoin(app.root, "share/man"))
