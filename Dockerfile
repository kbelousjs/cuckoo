FROM ubuntu:18.04

LABEL maintainer "https://github.com/kbelousjs"

# Define environment variables
#ENV CUCKOO 2.0.7
ENV CUCKOO_WEB_PORT 8000
ENV SSDEEP 2.14.1
ENV VBOXUSERS_GID 117

# Update indexes of packages
RUN apt update

# Install cuckoo sandbox required python libraries and other required packages
RUN apt install -y \
  python \
  python-pip \
  python-dev \
  libffi-dev \
  libssl-dev \
  python-virtualenv \
  python-setuptools \
  libjpeg-dev \
  zlib1g-dev \
  swig \
  curl \
  git \
  swig \
  tcpdump \
  apparmor-utils \
  libguac-client-rdp0 \
  libguac-client-vnc0 \
  libguac-client-ssh0 \
  guacd

# Upgrade pip libraries
RUN pip install -U \
  pip \
  setuptools \
  wheel

# Install Auxiliary Mitmproxy Module and Required Dependencies
#RUN apt install -y python3-pip
#RUN pip3 install -U pip
#RUN pip3 install mitmproxy

# Install Pydeep Plugin and Required Dependencies
RUN curl -L https://github.com/ssdeep-project/ssdeep/releases/download/release-$SSDEEP/ssdeep-$SSDEEP.tar.gz -o /tmp/ssdeep-$SSDEEP.tar.gz
RUN cd /tmp && tar xzf ssdeep-$SSDEEP.tar.gz && cd ssdeep-$SSDEEP && ./configure && make && make install
RUN cd /tmp && git clone https://github.com/kbandla/pydeep.git && cd pydeep && python setup.py build && python setup.py install

# Install Volatility Tool
RUN cd /tmp && git clone https://github.com/volatilityfoundation/volatility.git && cd volatility && python setup.py build && python setup.py install

# Install M2Crypto Tool and Required Dependencies
RUN pip install m2crypto

# Create Group and User for Cuckoo Sandbox
RUN useradd -m cuckoo
RUN groupadd -g $VBOXUSERS_GID vboxusers
RUN usermod -a -G vboxusers cuckoo

# Install Cuckoo Sandbox and Required Dependencies
#RUN pip install -U cuckoo==$CUCKOO
RUN pip install cuckoo

# Initialize Cuckoo Sandbox Configuration Files in /home/cuckoo/.cuckoo
RUN cuckoo

# Downloadin Cuckoo Community (included over 300 Cuckoo Signatures)
RUN cuckoo community

# Initialize Cuckoo Sandbox Web Interface (Built-in Django Web Server)
RUN cuckoo web runserver 0.0.0.0:$CUCKOO_WEB_PORT

# Clean up Unnecessary Files 
RUN rm -rf /tmp/*

# Uploading Cuckoo Configuration Files to Intstance $CWD (Cuckoo Working Directory)
#COPY conf ~/conf

EXPOSE $CUCKOO_WEB_PORT
