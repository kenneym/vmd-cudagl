# Base image provides cuda 9.1 support and opengl rendering for glx and egl
# If you posess a older or newer version of cuda, feel free to change the 
# base image by consulting the nvidia/cudagl repo on Dockerhub

FROM nvidia/cudagl:9.1-devel-centos7

# Install basic packages:
RUN yum install -y \
      autoconf \
      make \
      automake \
      libtool \
      git \
      openssh \
      openssh-server \
      openssh-clients \
      rsync \
      rlwrap \
      vim \
      csh \
      wget && \
    rm -rf /var/cache/yum*

# Install X11 packages and VMD dependencies
RUN yum install -y \
      libXcomposite \
      libXinerama \
      libXi \
      xauth \ 
      xorg-x11-devel && \
    rm -rf /var/cache/yum/*

# Provide driver all neccessary functions:
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,compat32,display

# Copy in VMD: 
COPY vmd-1.9.4a12 /opt/vmd/

# Configure and install VMD:
WORKDIR /opt/vmd/

RUN ./configure && \
      cd src && \
      make install 

# Drop the user at the root directory
WORKDIR /

# Start VMD when the container is launched, by default
CMD ["vmd"]
