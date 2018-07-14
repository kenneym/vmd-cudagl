FROM nvidia/cudagl:9.1-devel-ubuntu16.04

# Install basic packages:
RUN apt-get update && apt-get install -y --no-install-recommends \
      vim \
      git \        
      ssh \        
      rsync \        
      python \       
      csh \
      wget && \
    rm -rf /var/lib/apt/lists/*

# Install X libraries and X authentication
RUN apt-get update && apt-get install -y --no-install-recommends \        
      libx11-6 \
      libxi6 \
      xauth && \
    rm -rf /var/lib/apt/lists/*

# Install additional x libraries and VMD dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \        
      x11proto-gl-dev \        
      libdrm-dev \        
      libxdamage-dev \        
      libx11-xcb-dev \        
      libxcb-glx0-dev \       
      libxcb-dri2-0-dev \ 
      libxinerama-dev && \
    rm -rf /var/lib/apt/lists/* 

# Add all neccessary driver capabilities
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,compat32,display

# Copy VMD into container
COPY vmd-1.9.4a12/ /opt/vmd/

# Configure and install VMD
WORKDIR /opt/vmd/

RUN ./configure && \
      cd src && \
      make install 

# Place the user at the root directory upon starting the container
WORKDIR /

# Run VMD by default upon container starting
CMD ["vmd"]
