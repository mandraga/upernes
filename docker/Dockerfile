FROM debian:buster-slim

ENV OPT /opt
ENV WORKSPACE ${OPT}/workspace

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get --allow-releaseinfo-change update && apt-get -y upgrade

RUN apt-get update && apt-get install -y gawk wget git-core diffstat unzip build-essential curl flex bison cmake
RUN apt-get update && apt-get install -y libsdl1.2-dev

RUN groupadd -r builder \
	&& useradd -m -d /home/builder -g builder builder \
	&& adduser builder dialout && adduser builder sudo && echo "builder:builder" | chpasswd

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Build wla from source
RUN git clone https://github.com/vhelin/wla-dx
RUN cd wla-dx && git checkout v10.2 && mkdir build && cd build && cmake .. && cmake --build . --config Release && cmake -P cmake_install.cmake

# Build nesasm from source
RUN git clone https://github.com/camsaul/nesasm.git
RUN cd nesasm && cd source && make && make install

USER builder

# Set workdir
WORKDIR ${WORKSPACE}

# Add aliases to git commands
RUN echo 'alias status="git status"' >> /home/builder/.bashrc
RUN echo 'alias checkout="git checkout"' >> /home/builder/.bashrc
RUN echo 'alias branch="git branch"' >> /home/builder/.bashrc
RUN echo 'alias branches="git branch -a"' >> /home/builder/.bashrc
RUN echo 'alias clone="git clone"' >> /home/builder/.bashrc
RUN echo 'alias commit="git commit -m "' >> /home/builder/.bashrc
RUN echo 'alias log="git log"' >> /home/builder/.bashrc
RUN echo 'alias submod="git submodule update --init --recursive"' >> /home/builder/.bashrc
RUN echo 'alias pull="git pull"' >> /home/builder/.bashrc
RUN echo 'alias fund="find ./ | grep"' >> /home/builder/.bashrc
