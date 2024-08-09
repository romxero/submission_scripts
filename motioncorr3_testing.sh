PROJECT_DIR="/mnt/nvme1n1p1/motioncorr3_testing"
MINICONDA_INSTALL_DIR=${PROJECT_DIR}/miniconda3
CUDA_INSTALL_DIR=${PROJECT_DIR}/cuda

# download both miniconda3 and cuda 12.4
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run


bash ./Miniconda3-latest-Linux-x86_64.sh -b -p ${MINICONDA_INSTALL_DIR}

bash ./cuda_12.4.0_550.54.14_linux.run --silent --toolkit --toolkitpath=${CUDA_INSTALL_DIR}


# rapid testing variables 
PRJHOME=/mnt/nvme1n1p1/motioncorr3_testing/MotionCor3
CONDA=/mnt/nvme1n1p1/motioncorr3_testing/miniconda3
CUDAHOME=/mnt/nvme1n1p1/motioncorr3_testing/cuda


hipify-clang --cuda-path=$CUDAHOME -I${PRJHOME}/LibSrc/Include ./Util/GAddFrames.cu



# try out somet diffferent methods of hipifying the code in question 


# make sure to get dos2unix to reformat the code 
sudo apt-get install -ymq dos2unix 

# make sure to get those icky CRLFs out of our repo
find . -name '*.h' -print -exec dos2unix -o {} \;
find . -name '*.cpp' -print -exec dos2unix -o {} \;
find . -name '*.cu' -print -exec dos2unix -o {} \;





hipify-clang --cuda-path=$CUDAHOME -I${PRJHOME}/LibSrc/Include ./CMainInc.h 

1)
# DDN Lustre storage with 5.9PB 80% capacity # and a VAST w/ 1PB 16%

2) 
A lot of inodes, anaconda

3) AI workloads, Bioinformatics thru sequencing, and imaging workload through relion from microscope data, etc. 

* Data transfers from imaging microscopes,  speed for AI workloads (purchasing more VAST).

4) Bioinformatics, Imaging, ML/AI workloads

5) Infiniband HDR, our DGX nodes are on NDR fabric

6) I'm not the storage person at my company, but I want to learn a bit more about current and best practices, how we can better our stack