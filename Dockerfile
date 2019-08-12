FROM ubuntu:18.04

LABEL maintainer "https://github.com/kibelous"

# Define environment variables
#ENV CUCKOO 2.0.7
ENV CUCKOO_UI_PORT 8000
ENV CUCKOO_CWD /opt/cuckoo
ENV SSDEEP 2.14.1
ENV VBOXUSERS_GID 117

# Update indexes of packages and install cuckoo sandbox required python libraries and other required packages
RUN apt update && apt install -y \
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
  guacd \
  netcat

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

# Install remotevbox for Virtual Box Web Service
RUN pip install remotevbox

# Install m2crypto tool
RUN pip install m2crypto

# Create directory, group and user for cuckoo sandbox
RUN mkdir $CUCKOO_CWD
RUN useradd -d $CUCKOO_CWD cuckoo
RUN groupadd -g $VBOXUSERS_GID vboxusers
RUN usermod -a -G vboxusers cuckoo

# Install cuckoo sandbox and required dependencies
RUN pip install cuckoo && pip install -U cuckoo

# Setting up Cuckoo Working Directory to /opt/cuckoo ($CWD)
#RUN cuckoo --cwd /opt/cuckoo

# Initialize Cuckoo Sandbox configuration files to $CWD && Downloading Cuckoo Community (included over 300 cuckoo signatures)
RUN cuckoo && cuckoo community

# Script for initialize of container
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && ln -s /usr/local/bin/docker-entrypoint.sh /opt/cuckoo
COPY update_conf.py /opt/cuckoo
RUN chmod u+x /opt/cuckoo/update_conf.py

# Fix all permissions
RUN chown -R cuckoo:cuckoo /opt/cuckoo

# Clean up unnecessary files
RUN rm -rf /tmp/*
# Clean up apt cache
RUN apt clean

USER cuckoo

WORKDIR /opt/cuckoo

VOLUME ["/opt/cuckoo"]

EXPOSE $CUCKOO_UI_PORT

ENTRYPOINT ["docker-entrypoint.sh"]
