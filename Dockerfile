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

# Install auxiliary mitmproxy module and required dependencies
#RUN apt install -y python3-pip
#RUN pip3 install -U pip
#RUN pip3 install mitmproxy

# Install pydeep plugin and required dependencies
RUN curl -L https://github.com/ssdeep-project/ssdeep/releases/download/release-$SSDEEP/ssdeep-$SSDEEP.tar.gz -o /tmp/ssdeep-$SSDEEP.tar.gz
RUN cd /tmp && tar xzf ssdeep-$SSDEEP.tar.gz && cd ssdeep-$SSDEEP && ./configure && make && make install
RUN cd /tmp && git clone https://github.com/kbandla/pydeep.git && cd pydeep && python setup.py build && python setup.py install

# Install volatility tool and required dependencies
RUN pip install distorm3
RUN cd /tmp && git clone https://github.com/volatilityfoundation/volatility.git && cd volatility && python setup.py build && python setup.py install

# Install m2crypto tool
RUN pip install m2crypto

# Create group and user for cuckoo sandbox
RUN useradd -m cuckoo
RUN groupadd -g $VBOXUSERS_GID vboxusers
RUN usermod -a -G vboxusers cuckoo

# Install cuckoo sandbox and required dependencies
RUN pip install cuckoo

# Uploading cuckoo configuration files to intstance $CWD (Cuckoo Working Directory)
COPY conf/reporting.conf /home/cuckoo/.cuckoo/conf/reporting.conf
COPY update_conf.py /home/cuckoo/update_conf.py

# Script for initialize of container
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /home/cuckoo/docker-entrypoint.sh

# Fix all permissions
RUN chown -R cuckoo:cuckoo /home/cuckoo

# Clean up unnecessary files 
RUN rm -rf /tmp/*

USER cuckoo

# Initialize cuckoo sandbox configuration files in /home/cuckoo/.cuckoo && Downloadin cuckoo community (included over 300 cuckoo signatures)
RUN cuckoo && cuckoo community

WORKDIR /home/cuckoo/

VOLUME ["/home/cuckoo/"]

EXPOSE $CUCKOO_WEB_PORT

ENTRYPOINT ["docker-entrypoint.sh"]
