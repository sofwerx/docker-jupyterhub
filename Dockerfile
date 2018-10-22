FROM ubuntu:18.04

# This Dockerfile builds for both x86_64 and ppc64le

# install nodejs, utf8 locale, set CDN because default httpredir is unreliable
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install wget git bzip2 curl gnupg jq coreutils && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g configurable-http-proxy

ENV LANG=C.UTF-8 \
    MINICONDA_VERSION=4.5.11 \
    CONDA_DIR=/opt/conda \
    PATH=$PATH:/opt/conda/bin

RUN ARCH= \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x86_64' ; MD5SUM=e1045ee415162f944b6aebfe560b8fee ;; \
      ppc64el) ARCH='ppc64le' ; MD5SUM=4b1ac3b4b70bfa710c9f1c5c6d3f3166 ;; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && cd /tmp \
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-${ARCH}.sh \
    && echo "${MD5SUM} *Miniconda3-${MINICONDA_VERSION}-Linux-${ARCH}.sh" | md5sum -c - \
    && /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-${ARCH}.sh -f -b -p $CONDA_DIR \
    && rm Miniconda3-${MINICONDA_VERSION}-Linux-${ARCH}.sh \
    && $CONDA_DIR/bin/conda config --system --prepend channels conda-forge \
    && $CONDA_DIR/bin/conda config --system --set auto_update_conda false \
    && $CONDA_DIR/bin/conda config --system --set show_channel_urls true \
    && $CONDA_DIR/bin/conda install --quiet --yes conda="${MINICONDA_VERSION%.*}.*" \
    && $CONDA_DIR/bin/conda install --yes -c conda-forge \
      python=3.6 sqlalchemy tornado jinja2 traitlets requests pip pycurl \
    && pip install --upgrade pip \
    && $CONDA_DIR/bin/conda update --all --quiet --yes \
    && $CONDA_DIR/bin/conda clean -tipsy

ADD jupyterhub/ /src/jupyterhub
WORKDIR /src/jupyterhub

RUN pip install . && \
    rm -rf $PWD ~/.cache ~/.npm

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/
EXPOSE 8000

LABEL org.jupyter.service="jupyterhub"

# Install dockerspawner, oauth, postgres
RUN $CONDA_DIR/bin/conda install -yq psycopg2=2.7 && \
    $CONDA_DIR/bin/conda clean -tipsy && \
    $CONDA_DIR/bin/pip install --no-cache-dir \
        oauthenticator==0.7.* \
        dockerspawner==0.9.*

RUN pip install jupyterhub-dummyauthenticator

ADD jupyterhub_config.py .
ADD run.sh /run.sh

CMD /run.sh

#RUN chmod 700 /srv/jupyterhub/secrets && \
#    chmod 600 /srv/jupyterhub/secrets/*

#COPY ./userlist /srv/jupyterhub/userlist
