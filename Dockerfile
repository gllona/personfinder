FROM phusion/baseimage:jammy
LABEL authors="Carlo Lobrano <c.lobrano@gmail.com>, Mathieu Tortuyaux <mathieu.tortuyaux@gmail.com>"

CMD ["/sbin/my_init"]

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="${PATH}:/opt/google-cloud-sdk/bin"
ENV APPENGINE_DIR=/opt/google-cloud-sdk/platform/google_appengine
ENV PERSONFINDER_DIR=/opt/personfinder/
ENV INIT_DATASTORE=0

# Enable universe repo (needed for python2.7 on jammy) and install system deps
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y \
        build-essential \
        unzip \
        python2.7 \
        libpython2.7-dev \
        python-is-python3 \
        curl \
        git \
        time \
        gettext \
        apt-transport-https \
        ca-certificates \
        gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# python2 symlink — the GAE Python 2.7 sandbox launcher calls "python2", not "python2.7"
RUN ln -s /usr/bin/python2.7 /usr/bin/python2

# pip for Python 2.7 (bootstrap.pypa.io/get-pip.py dropped Python 2 support;
# the archived 2.7-compatible installer lives at the pip/2.7/ path)
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py && \
    /usr/bin/python2.7 get-pip.py && \
    rm get-pip.py
RUN /usr/bin/python2.7 -m pip install pytest==3.7.4 lxml cssselect pillow==4.1.0 mock modernize

# Node.js 18 LTS (Node 10 is EOL and its nodesource setup script is gone)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Google Cloud SDK 420.0.0 — last major release before Python 2.7 EOL (Jan 2024),
# so dev_appserver still supports the python27 runtime.
# The apt package installs the latest SDK which has dropped python27 support,
# so we use the versioned tarball instead.
WORKDIR /opt/
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-420.0.0-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-420.0.0-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-420.0.0-linux-x86_64.tar.gz && \
    /opt/google-cloud-sdk/install.sh --quiet --path-update=false && \
    /opt/google-cloud-sdk/bin/gcloud components install app-engine-python app-engine-python-extras --quiet

# Install app vendor dependencies into app/vendors/ so they're available to the
# GAE Python 2.7 runtime. app/vendors/ is gitignored, so we bake the packages
# into the image here; a named Docker volume in docker-compose.yml preserves
# them independently of the source bind-mount.
COPY requirements.txt /tmp/requirements.txt
RUN mkdir -p /opt/personfinder/app/vendors && \
    /usr/bin/python2.7 -m pip install -r /tmp/requirements.txt -t /opt/personfinder/app/vendors/

ADD docker/gae-run-app.sh      /usr/bin/
ADD docker/setup_datastore.sh  /usr/bin/

RUN echo "opt_in: false\ntimestamp: $(date +%s)\n" > /root/.appcfg_nag

WORKDIR /opt/personfinder/

# Clean up
RUN rm -rf /tmp/* /var/tmp/*
