### Copy pasted and modified from:
# - https://github.com/nginxinc/docker-nginx-amplify/blob/master/Dockerfile.alpine
# - https://github.com/nmhung1210/nginx-alpine-amplify/blob/master/Dockerfile

FROM nginx:stable-alpine AS nginx

LABEL maintainer="Muhammad Zamroi <halo@matriphe.com>"

# Install the NGINX Amplify Agent
RUN \
    # install packages required by agent
    apk update \
    && apk upgrade \
    && apk add --no-cache python3 procps util-linux py3-pip py3-setproctitle \
    # install packages required for agent build
    && apk add --no-cache --virtual .amplify python3-dev libffi-dev build-base git linux-headers gcc \
    && cd / \
    \
    # clone latest agent from repository and build it
    && git clone --single-branch --branch master https://github.com/nginxinc/nginx-amplify-agent \
    && cd nginx-amplify-agent/ \
    # manually install from packages/nginx-amplify-agent/requirements.txt 
    && pip3 install --no-cache-dir --break-system-packages --upgrade gevent greenlet netifaces netaddr flup crossplane rstr psutil python-daemon requests ujson PyMySQL \
    && cp packages/nginx-amplify-agent/setup.py ./ \
    && python3 setup.py install \
    \
    # link default Amplify Agent log location to stdout
    && mkdir -p /var/log/amplify-agent \
    && touch /var/log/amplify-agent/agent.log \
    && chown nginx /var/log/amplify-agent /var/log/amplify-agent/agent.log \
    \
    # create agent config file
    && cp /etc/amplify-agent/agent.conf.default /etc/amplify-agent/agent.conf \
    \
    # cleanup
    && cd / \
    && rm -Rf nginx-amplify-agent/ \
    && apk del .amplify \
    && rm -rf /var/cache/apk/*

# Keep the nginx logs inside the container
RUN unlink /var/log/nginx/access.log \
    && unlink /var/log/nginx/error.log \
    && touch /var/log/nginx/access.log \
    && touch /var/log/nginx/error.log \
    && chown nginx /var/log/nginx/*log \
    && chmod 644 /var/log/nginx/*log

# Copy nginx stub_status config
COPY ./conf.d/stub_status.conf /etc/nginx/conf.d

# API_KEY is required for configuring the NGINX Amplify Agent.
# It could be your real API key for NGINX Amplify here if you wanted
# to build your own image to host it in a private registry.
# However, including private keys in the Dockerfile is not recommended.
# Use the environment variables at runtime as described below.

ENV API_KEY 1234567890

# If AMPLIFY_IMAGENAME is set, the startup wrapper script will use it to
# generate the 'imagename' to put in the /etc/amplify-agent/agent.conf
# If several instances use the same 'imagename', the metrics will
# be aggregated into a single object in NGINX Amplify. Otherwise Amplify
# will create separate objects for monitoring (an object per instance).
# AMPLIFY_IMAGENAME can also be passed to the instance at runtime as
# described below.

ENV AMPLIFY_IMAGENAME ""

# The /entrypoint.sh script will launch nginx and the Amplify Agent.
# The script honors API_KEY and AMPLIFY_IMAGENAME environment
# variables, and updates /etc/amplify-agent/agent.conf accordingly.

COPY ./entrypoint.sh /entrypoint.sh

# To set/override API_KEY and AMPLIFY_IMAGENAME when starting an instance:
# docker run --name my-nginx1 -e API_KEY='..effc' -e AMPLIFY_IMAGENAME="service-name" -d nginx-amplify

ENTRYPOINT ["/entrypoint.sh"]
