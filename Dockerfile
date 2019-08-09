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

# Install m2crypto tool
RUN pip install m2crypto

# Create group and user for cuckoo sandbox
RUN mkdir /opt/cuckoo
RUN useradd -m /opt/cuckoo cuckoo
RUN groupadd -g $VBOXUSERS_GID vboxusers
RUN usermod -a -G vboxusers cuckoo

# Install cuckoo sandbox and required dependencies
RUN pip install cuckoo

# Setting up Cuckoo Working Directory to /opt/cuckoo
RUN cuckoo --cwd /opt/cuckoo

# Initialize cuckoo sandbox configuration files in /home/cuckoo/.cuckoo && Downloadin cuckoo community (included over 300 cuckoo signatures)
RUN cuckoo && cuckoo community

# Uploading cuckoo configuration files to intstance $CWD (Cuckoo Working Directory)
#COPY conf/reporting.conf /opt/cuckoo/conf/reporting.conf
#COPY web/local_settings.py /opt/cuckoo/web/local_settings.py

# Script for initialize of container
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && ln -s usr/local/bin/docker-entrypoint.sh /opt/cuckoo
COPY update_conf.py /opt/cuckoo
RUN chmod u+x /home/cuckoo/update_conf.py

# Fix all permissions
RUN chown -R cuckoo:cuckoo /opt/cuckoo

# Clean up unnecessary files 
RUN rm -rf /tmp/*

USER cuckoo

WORKDIR /opt/cuckoo

VOLUME ["/opt/cuckoo"]

EXPOSE $CUCKOO_WEB_PORT

ENTRYPOINT ["docker-entrypoint.sh"]
