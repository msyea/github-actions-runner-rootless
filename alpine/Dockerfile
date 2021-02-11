# aka alpine:3.13
FROM docker:20-dind

RUN apk update --no-cache && apk upgrade --no-cache && apk add curl bash

# https://docs.microsoft.com/en-us/dotnet/core/install/linux-alpine
RUN apk add --update icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib gcompat alpine-sdk
RUN apk add --update --virtual build-dependencies
#  musl part of gcompat?

RUN adduser --disabled-password runner
USER runner
WORKDIR /home/runner

# https://docs.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
RUN curl -O -L https://dot.net/v1/dotnet-install.sh

RUN chmod +x ./dotnet-install.sh

RUN ./dotnet-install.sh -c 3.0
ENV DOTNET_ROOT="/home/runner/.dotnet"
ENV PATH="$PATH:$DOTNET_ROOT"

RUN env > env.txt
WORKDIR /actions-runner

RUN chown -R runner:runner /actions-runner


# RUN curl -O -L https://githubassets.azureedge.net/runners/2.159.1/actions-runner-linux-x64-2.159.1.tar.gz

# RUN tar xzf ./actions-runner-linux-x64-2.159.1.tar.gz

RUN curl -O -L https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz

RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz

USER root
RUN apk add lttng-ust
# RUN apk del icu-libs gcompat
# RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
#   && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk \
#   && apk add glibc-2.32-r0.apk
USER runner


# RUN cat ./config.sh

# RUN ./config.sh --url https://github.com/simon-kenichi --token XXXX

# RUN ./run.sh


# liblttng-ust0
# libkrb5-3
# zlib1g
# libssl1.1, libssl1.0.2 or libssl1.0.0
# libicu63, libicu60, libicu57 or libicu55