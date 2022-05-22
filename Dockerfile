# syntax=docker/dockerfile:1
FROM lthn/build:compile as builder

WORKDIR /build

COPY . .

COPY --from=lthn/build:depends-x86_64-unknown-linux-gnu / /build/contrib/depends

RUN pwd \
    && mem_avail_gb=$(( $(getconf _AVPHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024) )) \
    && make_job_slots=$(( $mem_avail_gb < 4 ? 1 : $mem_avail_gb / 4)) \
    && echo make_job_slots=$make_job_slots \
    && set -x \
    && make -j $make_job_slots depends target=x86_64-unknown-linux-gnu

FROM debian:bullseye as container

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get --no-install-recommends --yes install ca-certificates \
    && apt-get clean

RUN adduser --system --group --disabled-password itw3 \
    && mkdir -p /home/itw3/wallet \
    && chown -R itw3:itw3 /home/itw3 \
    && chown -R itw3:itw3 /home/itw3/wallet

COPY --from=builder --chmod=0777 --chown=root:root /build/**/${BRANCH}/release/bin/ /usr/local/bin/

USER itw3

# iTw3 User Folder
VOLUME /home/itw3/data
VOLUME /home/itw3/wallet

ENV DATA_DIR=/home/itw3/data TEST_DATA_DIR=/home/itw3/data/testnet

ENV LOG_LEVEL 0

# P2P live + testnet
ENV P2P_BIND_IP=0.0.0.0 P2P_BIND_PORT=48772 TEST_P2P_BIND_PORT=38772

# RPC live + testnet
ENV RPC_BIND_IP=0.0.0.0 RPC_BIND_PORT=48782 TEST_RPC_BIND_PORT=38782

RUN mkdir -p ${TEST_DATA_DIR}

EXPOSE 48782/tcp
EXPOSE 48772/tcp
EXPOSE 38772/tcp
EXPOSE 38782/tcp

ENTRYPOINT ["itw3d", "--confirm-external-bind", "--log-level=${LOG_LEVEL}","--data-dir=${DATA_DIR}", "--testnet-data-dir=${TEST_DATA_DIR}",\
"--rpc-bind-ip=${RPC_BIND_IP}","--p2p-bind-ip=${P2P_BIND_IP}","--p2p-bind-port=${P2P_BIND_PORT}", "--testnet-p2p-bind-port=${TEST_P2P_BIND_PORT}",\
 "--rpc-bind-port=${RPC_BIND_PORT}", "--testnet-rpc-bind-port=${TEST_RPC_BIND_PORT}"]

