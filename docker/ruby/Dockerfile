FROM ruby:3.0-alpine

RUN apk add --no-cache --update build-base bash openssh imagemagick git nodejs \
    tzdata python3 python3-dev aws-cli git openssl openssl-dev

RUN gem install bundler --no-doc
