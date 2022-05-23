# syntax=docker/dockerfile:1
FROM debian:bullseye as builder

RUN apt-get update && apt-get -y upgrade
RUN apt install -y build-essential cmake pkg-config libssl-dev libzmq3-dev libunbound-dev libsodium-dev libunwind8-dev \
    liblzma-dev libreadline6-dev libldns-dev libexpat1-dev libpgm-dev qttools5-dev-tools libhidapi-dev libusb-1.0-0-dev \
    libprotobuf-dev protobuf-compiler libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev \
    libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev \
    libboost-thread-dev python3 ccache doxygen graphviz git


WORKDIR /build

COPY . .

RUN pwd \
    && mem_avail_gb=$(( $(getconf _AVPHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024 * 1024) )) \
    && make_job_slots=$(( $mem_avail_gb < 4 ? 1 : $mem_avail_gb / 4)) \
    && echo make_job_slots=$make_job_slots \
    && set -x \
    && make -j $make_job_slots release-static

FROM debian:bullseye-slim as container

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get --no-install-recommends --yes install ca-certificates \
    && apt-get clean

RUN adduser --system --group --disabled-password itw3 \
    && mkdir -p /home/itw3/wallet \
    && chown -R itw3:itw3 /home/itw3 \
    && chown -R itw3:itw3 /home/itw3/wallet

USER itw3

COPY --from=builder --chmod=0777 /build/**/${BRANCH}/release/bin/ /home/itw3/bin/

# iTw3 User Folder
VOLUME /home/itw3/data
VOLUME /home/itw3/wallet

ENV DATA_DIR=/home/itw3/data TEST_DATA_DIR=/home/itw3/data/testnet

ENV LOG_LEVEL 0

ENV MAINNET=0 STAGNET=0 TESTNET=1

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

