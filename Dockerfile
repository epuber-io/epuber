FROM ruby:2.7-alpine
LABEL maintainer="roman@kriz.io"

ENV EPUBER_VERSION="0.7.1"

# Install Epuber and all dependencies
RUN apk --no-cache --update add imagemagick nodejs zip openjdk7 && \
    apk --no-cache add --virtual .build-deps g++ musl-dev make imagemagick-dev && \
    gem update --system && \
    gem update --default && \
    gem update && \
    gem install epuber --version $EPUBER_VERSION && \
    apk del .build-deps
