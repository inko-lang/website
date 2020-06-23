FROM ruby:2.6-alpine

RUN apk add --no-cache --update build-base bash openssh imagemagick git nodejs \
    tzdata python3 python3-dev aws-cli git

RUN gem install bundler --no-doc
