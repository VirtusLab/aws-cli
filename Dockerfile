FROM debian:stable-slim

# The AWS CLI version to install
ARG AWS_CLI_VERSION

ARG USER=user
ARG UID=1000
ARG GID=1000

# Disable prompts from apt.
ARG DEBIAN_FRONTEND=noninteractive

# Add more deb repos, initialize apt
RUN \
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        jq \
        software-properties-common \
    && apt-get update

# Add Python apps (awscli and bitbucket-cli)
RUN BUILD_DEPS="python-dev" \
    apt-get install -y --no-install-recommends \
        python \
        python-pip \
        python-setuptools \
        groff \
        less \
        $BUILD_DEPS \
    && pip install --no-cache-dir awscli==$AWS_CLI_VERSION \
    && apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        $BUILD_DEPS

# Add more software
RUN \
    apt-get install -y --no-install-recommends \
        bash \
        watch \
        make \
        git \
        curl

# Cleanup build dependencies and caches
RUN \
    apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf \
       /var/cache/debconf/* \
       /var/lib/apt/lists/* \
       /var/log/* \
       /tmp/* \
       /var/tmp/*

# setup user
RUN \
    groupadd -g $GID $USER \
    && useradd -u $UID -g $GID -ms /bin/bash $USER
USER $USER

VOLUME /home/$USER/.aws

WORKDIR /home/$USER
ENTRYPOINT ["bash"]
