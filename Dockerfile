# syntax = docker/dockerfile:1

FROM ubuntu:22.04 AS builder

ARG RENODE_GIT_URL=https://github.com/renode/renode.git
ARG RENODE_GIT_TAG=v1.15.2
ARG RENODE_BUILD_OPTIONS=-pn

ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=SC1091
RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    <<EOF
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends \
    build-essential ca-certificates gnupg \
    git automake cmake autoconf libtool g++ coreutils policykit-1 \
    libgtk-3-dev uml-utilities gtk-sharp3 python3 python3-pip \
    ruby ruby-dev rpm 'bsdtar|libarchive-tools'
    gem install fpm
    gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list
    apt-get update -qq
    apt-get install -qq -y --no-install-recommends \
    mono-complete libmono-addins-gui-cil-dev
EOF

RUN git clone -b ${RENODE_GIT_TAG} ${RENODE_GIT_URL} /renode

WORKDIR /renode

RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache,sharing=locked \
    <<EOF
    python3 -m pip install -r tests/requirements.txt
    ./build.sh ${RENODE_BUILD_OPTIONS}
EOF

FROM scratch

COPY --from=builder /renode/output/packages/* /
