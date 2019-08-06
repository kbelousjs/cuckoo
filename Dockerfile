FROM ubuntu:18.04

LABEL maintainer "https://github.com/kbelousjs"

ENV CUCKOO_VERSION 2.0.5.3

RUN apt update
RUN apt install -y python python-pip python-dev libffi-dev libssl-dev
RUN apt install -y python-virtualenv python-setuptools
RUN apt install -y libjpeg-dev zlib1g-dev swig
RUN apt install -y mongodb
RUN apt install -y postgresql libpq-dev

RUN echo deb http://download.virtualbox.org/virtualbox/debian xenial contrib | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
RUN wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
RUN apt update
RUN apt install -y virtualbox-5.2

RUN apt install -y tcpdump apparmor-utils
RUN aa-disable /usr/sbin/tcpdump
