PROJECT_DIR="/mnt/nvme1n1p1/motioncorr3_testing"
MINICONDA_INSTALL_DIR=${PROJECT_DIR}/miniconda3
CUDA_INSTALL_DIR=${PROJECT_DIR}/cuda

# download both miniconda3 and cuda 12.4
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run


bash ./Miniconda3-latest-Linux-x86_64.sh -b -p ${MINICONDA_INSTALL_DIR}

bash ./cuda_12.4.0_550.54.14_linux.run --silent --toolkit --toolkitpath=${CUDA_INSTALL_DIR}