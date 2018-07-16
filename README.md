# Visual VMD Container Images:

Included in this repository are two images, one with a ubuntu 16.04 base, the other from Centos 7. Each are equipped with a fully-fledged, visual version of VMD, OpenGL rendering capabilities, and Cuda acceleration built to pair with NVIDIA GPUs.

Each image was built by extending NVIDIA's CudaGl images (Cuda + Opengl). All cudagl images have dockerfiles hosted on [Gitlab](https://gitlab.com/nvidia/cudagl) and can be pulled from [Dockerhub](https://hub.docker.com/r/nvidia/cudagl/) 

These images include Cuda Version 9.1, and VMD version 1.9.4a12. You may either clone this repository and modify these images to your liking, or pull directly from Dockerhub. 

#### Image Size:
- `Centos 7`: 2.83GB
- `Ubuntu 16.04`: 2.83GB

## Purpose
The purpose of this image is to enable researchers to use either script-driven OR visual VMD depending upon their needs. While scripting in VMD is a very powerful tool, some researchers may find that certain tasks are best done visually. Further, they may find that some work-flows in VMD vary extensively enough experiment-to-experiment that scripting is not ideal. In our case, we need researchers who are not familiar with tcl/tk scripting to use some features of this container visually, enabling them to put forth their knowledge within their own realms of expertise without spending extensive time learning scripting. Containerized programs are attractive for a variety or reasons, including their ease-of-use, compatibility with powerful servers, and more. 

**This image is designed to make containerized VMD as versatile as possible.**

## Running this Container:

#### Requirements:
1. nvidia-docker2 installed
2. NVIDIA GPU on-board
3. NVIDIA drivers version 390 or greater
5. Have read and agreed to the University of Illinois Visual Molecular Dynamics Software License Agreement 

#### Selecting a Container:
Each of these containers are equipped with exactly the same functionality, the choice between operating systems is simply a matter of preference

#### Modifying a Container:
If your computer does not have cuda capabilities, you should still be able to run this image. In order to do so, select one of NVIDIA's development-level OpenGL images to replace the CudaGL image that these VMD containers are built on top of. Such images can be found in [NVIDIA's OpenGL repostiory on Dockerhub](https://hub.docker.com/r/nvidia/opengl). 

Alternatively, if you do have cuda, but your computer or server's cuda version is higher or lower than 9.1, consider going to [Nvidia's CudaGL repository on Dockerhub](https://hub.docker.com/r/nvidia/cudagl/). This repo will have plenty more images that may fit your needs. 

To modify the cuda version used in the VMD container, or to forego cuda capabilities entirely, simply change the "FROM" declaration at the top of the Dockerfile to whatever version of CudaGL or OpenGL you prefer. Ensure, however, that you are using the *development version* of whatever CudaGl image you choose. Any modifications to the "FROM" declaration should work just fine, as long as you retain the same OS (i.e. Ubuntu or Centos) and remember to use a development version.

Additionally, in the case you would like to use a different version of VMD, this is as simple as downloading the version you would like into the same repo as your Dockerfile of choice, and editing the Dockerfile's first "COPY" declaration to match your new VMD version.

#### Step 1: Enable X-forwarding
Type the following commands directing into your bash command line. This code will allow docker containers that you select to access the X server on your host:

	XSOCK=/tmp/.X11-unix
	XAUTH=/tmp/.docker.xauth
	touch $XAUTH
	xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
	xhost +local:docker


#### Step 2: Build the Container
Clone this repository. Download and untar/unzip a precompiled Linux VMD version 1.9.4a12 from VMD's webiste. Next, move the resultant vmd folder directly into the repository containing your Dockerfile of choice (either `visual-vmd-centos7` or `visual-vmd-ubuntu16.04. Then, cd to the directory containing your operating system of choice, and issue the following command:
	
	docker build -t your-container-name .
	
#### Step 3: Run the Container
To run the container, issue the command below. This will enable your container to access files in your local directory (such as .pdb files) within the container's workspace directory, and enable to the container to access the host's X-server.

	nvidia-docker run -it --rm -v $(pwd):/workspace \
	-v '/tmp/.X11-unix':'/tmp/.X11-unix' \
	-e XAUTHORITY=/tmp/.docker.xauth   
	-e DISPLAY \
	container-name
	
Running the image in this way will cause VMD to launch directly. If you would instead prefer to enter the container's command line first, you can issue the same command with `bin/bash` appended to the end:

	nvidia-docker run -it --rm -v $(pwd):/workspace \
	-v '/tmp/.X11-unix':'/tmp/.X11-unix' \
	-e XAUTHORITY=/tmp/.docker.xauth 
	-e DISPLAY \
	container-name /bin/bash

Then, simply type `vmd` from within the container to start the program.
