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



-- family: Only one thing in a family can be loaded
family("hpcx")

-- this thing will likely conflict w/ versions of openmpi
conflict("mpi")



setenv("HPCX_DIR", app.root)
setenv("HPCX_HOME", app.root)
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
HPCX_DIR
HPCX_HOME

setenv
HPCX_UCX_DIR
HPCX_UCC_DIR
HPCX_SHARP_DIR
HPCX_HCOLL_DIR
HPCX_NCCL_RDMA_SHARP_PLUGIN_DIR

setenv
HPCX_CLUSTERKIT_DIR
HPCX_MPI_DIR
HPCX_OSHMEM_DIR
HPCX_MPI_TESTS_DIR
HPCX_OSU_DIR
HPCX_OSU_CUDA_DIR


--pkg.mpi_path = pathJoin(pkg.name, pkg.version, "ompi")

-- might not need this stuff below. Just need to set the paths for the conda environment
pkg.prefix = pathJoin(appsroot, pkg.name, pkg.version)

pkg.conda_envfile = pathJoin(appsroot, pkg.name, pkg.version, 'etc/profile.d', 'conda.' .. myShellType())
pkg.mamba_envfile = pathJoin(appsroot, pkg.name, pkg.version, 'etc/profile.d', 'mamba.' .. myShellType())

----------------------------------------------------------------------------
-- Deprecated in favor of a pure module implementation 
-- Initialize hpcx
-- execute{cmd="source " .. pkg.conda_envfile .. "; source " .. pkg.mamba_envfile .. "; export -f " .. funcs, modeA={"load"}}
-- Unload environments and clear conda from environment
-- execute{cmd="", modeA={"unload"}}

-- Set the environment variables
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


--    prepend_path("PATH", pathJoin(app.root, "bin"))
    -- prepend_path("LD_LIBRARY_PATH", pathJoin(app.root, "lib64"))
    -- prepend_path("C_PATH", pathJoin(app.root, "include"))
--    prepend_path("MANPATH", pathJoin(app.root, "share/man"))
