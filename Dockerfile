FROM ruby:2.7-alpine AS base

LABEL maintainer="Delivery Engineering"

RUN apk --no-cache upgrade
RUN apk --no-cache add \
        bash \
        curl \
        jq

COPY --from=mikefarah/yq:2 /usr/bin/yq /usr/bin/yq
COPY --from=realestate/shush:1.4.1 /go/bin/shush /usr/bin/shush
COPY --from=realestate/stackup:1.5.0 /usr/local/bundle/ /usr/local/bundle/
COPY --from=alpine/helm:3.3.4 /usr/bin/helm /usr/bin/helm

##----------------------------------------------------------------------

FROM base AS with-python

COPY --from=python:3.9-alpine /usr/local/bin/ /usr/local/bin/
COPY --from=python:3.9-alpine /usr/local/include/ /usr/local/include/
COPY --from=python:3.9-alpine /usr/local/lib/ /usr/local/lib/
COPY --from=python:3.9-alpine /usr/lib/ /usr/lib/

RUN pip install --no-cache -U \
        pip \
        pipenv

ADD Pipfile* /tmp/
WORKDIR /tmp
RUN pipenv install --system --ignore-pipfile

##----------------------------------------------------------------------

FROM with-python AS runtime

LABEL maintainer="Delivery Engineering"

RUN mkdir -p /cwd && chmod 1777 /cwd
RUN adduser -D -s /bin/bash hermitcrab
USER hermitcrab
WORKDIR /cwd

ENV AWS_DEFAULT_REGION=ap-southeast-2
ENV TZ="Australia/Melbourne"
