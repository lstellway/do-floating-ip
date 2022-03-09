ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION}
COPY entrypoint.sh /

RUN apk add --update --no-cache \
    curl bash jq \
    && chmod +x /entrypoint.sh

ENV DO_METADATA_API=http://169.254.169.254\
    DO_API=https://api.digitalocean.com\
    DO_TOKEN=\
    DO_TOKEN_FILE=\
    DO_FLOATING_IP=\
    UPDATE_FREQUENCY=600

ENTRYPOINT [ "/bin/bash", "-c", "/entrypoint.sh" ]
