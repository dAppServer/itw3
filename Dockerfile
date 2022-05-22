# syntax=docker/dockerfile:1
FROM lthn/build:compile as builder

ARG IMG_PREFIX=lthn
ARG THREADS=2
ARG TARGET=x86_64-unknown-linux-gnu
WORKDIR /build
COPY . .
COPY --from=lthn/build:depends-x86_64-unknown-linux-gnu / /build/contrib/depends

RUN make depends target=x86_64-unknown-linux-gnu

# runtime stage
FROM debian:bullseye as container

RUN adduser --system --group --disabled-password itw3 && \
	mkdir -p /wallet /home/itw3 && \
	chown -R itw3:itw3 /home/itw3 && \
	chown -R itw3:itw3 /wallet

RUN set -ex && \
    apt-get update && \
    apt-get --no-install-recommends --yes install ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt


COPY --from=builder --chmod=0777 --chown=itw3:itw3 /build/**/${BRANCH}/release/bin/ /usr/local/bin/

# Create iTw3 user
RUN adduser --system --group --disabled-password itw3 && \
	mkdir -p /home/itw3/wallet && \
	chown -R itw3:itw3 /home/itw3/wallet

# iTw3 User Folder
VOLUME /home/itw3
VOLUME /home/itw3/wallet

ENV LOG_LEVEL 0

# switch to user monero
USER itw3

# P2P live + testnet
ENV P2P_BIND_IP 0.0.0.0
ENV P2P_BIND_PORT 48772
ENV TEST_P2P_BIND_PORT 38772

# RPC live + testnet
ENV RPC_BIND_IP 0.0.0.0
ENV RPC_BIND_PORT 48782
ENV TEST_RPC_BIND_PORT 38782
ENV DATA_DIR /home/itw3/data
ENV TEST_DATA_DIR /home/itw3/data/testnet

RUN mkdir -p ${TEST_DATA_DIR}

EXPOSE 48782
EXPOSE 48772
EXPOSE 38772
EXPOSE 38782

ENTRYPOINT ["itw3d", "--non-interactive"]
#CMD , "--confirm-external-bind", "--log-level=${LOG_LEVEL}",
#    "--data-dir=${DATA_DIR}", "--testnet-data-dir=${TEST_DATA_DIR}",
#    "--rpc-bind-ip=${RPC_BIND_IP}","--p2p-bind-ip=${P2P_BIND_IP}",
#    "--p2p-bind-port=${P2P_BIND_PORT}", "--testnet-p2p-bind-port=${TEST_P2P_BIND_PORT}",
#    "--rpc-bind-port=${RPC_BIND_PORT}", "--testnet-rpc-bind-port=${TEST_RPC_BIND_PORT}"
#



