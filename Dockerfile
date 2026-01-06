FROM ruby:3.2-alpine
LABEL org.opencontainers.image.source="https://github.com/epuber-io/epuber"
LABEL org.opencontainers.image.authors="Roman Kříž <roman@kriz.io>"


# Set Epuber version
ARG EPUBER_VERSION
ENV EPUBER_VERSION=${EPUBER_VERSION}

# Install Epuber and all dependencies
RUN apk --no-cache --update add imagemagick nodejs zip openjdk11 gcompat && \
    apk --no-cache add --virtual .build-deps g++ musl-dev make imagemagick-dev && \
    gem update --system && \
    gem update --default && \
    gem update && \
    EPUBER_VERSION=$(echo $EPUBER_VERSION | sed 's/^v//') && \
    echo "Installing Epuber $EPUBER_VERSION" && \
    gem install epuber --version $EPUBER_VERSION && \
    apk del .build-deps && \
    epuber --version
