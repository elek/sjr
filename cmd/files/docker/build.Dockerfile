# syntax=docker/dockerfile:1
ARG TYPE
FROM --platform=$TARGETPLATFORM ubuntu:22.04 as base
ARG TARGETPLATFORM
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install curl && curl -sfL https://deb.nodesource.com/setup_16.x  | bash -
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install git sudo nodejs make gcc brotli g++
RUN echo ${TARGETPLATFORM} | sed 's/linux\///' | xargs -I PLATFORM curl --fail -L https://go.dev/dl/go1.17.12.linux-PLATFORM.tar.gz | tar -C /usr/local -xz && cp /usr/local/go/bin/go /usr/local/bin/go


RUN useradd storj --uid 1000 -d /var/lib/storj && mkdir -p /var/lib/storj/shared && chown storj. /var/lib/storj

USER storj
WORKDIR /var/lib/storj
RUN go install github.com/go-delve/delve/cmd/dlv@latest

FROM base AS github
ARG BRANCH
RUN git clone https://github.com/storj/storj.git --depth=1 --branch ${BRANCH}
WORKDIR storj

FROM base AS gerrit
ARG REF
RUN git clone https://github.com/storj/storj.git
WORKDIR storj
RUN git fetch https://review.dev.storj.io/storj/storj ${REF} && git checkout FETCH_HEAD

FROM ${TYPE} AS binaries
RUN env env GO111MODULE=on GOOS=js GOARCH=wasm GOARM=6 -CGO_ENABLED=1 TAG=head scripts/build-wasm.sh && \
    go build ./cmd/... && \
    cd .. && \
    rm -rf storj
WORKDIR ../

FROM base AS storjupbuild
ENV CGO_ENABLED=0
ADD . /var/lib/storj
WORKDIR /var/lib/storj
RUN go install

FROM binaries AS final
ADD pkg/recipe/entrypoint.sh /var/lib/storj/entrypoint.sh
COPY --chown=storj identities /var/lib/storj/identities
COPY --chown=storj --from=storjupbuild /var/lib/storj/go/bin/storj-up /var/lib/storj/go/bin/storj-up
