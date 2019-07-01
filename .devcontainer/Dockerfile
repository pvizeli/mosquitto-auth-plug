#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
FROM ubuntu:18.04

ARG MOSQUITTO_VERSION=1.6.3

# Configure apt
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-utils procps lsb-release libcurl4-openssl-dev \
        libwebsockets8 libwebsockets-dev libc-ares2 \
        libc-ares-dev openssl uuid uuid-dev wget build-essential git \
    && wget http://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz \
    && tar xzvf mosquitto-${MOSQUITTO_VERSION}.tar.gz \
    && cd mosquitto-${MOSQUITTO_VERSION} \
    && make WITH_WEBSOCKETS=yes \
    && make install \
    && cd .. \
    && rm -fr mosquitto-${MOSQUITTO_VERSION}* \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Set the default shell to bash instead of sh
ENV SHELL /bin/bash