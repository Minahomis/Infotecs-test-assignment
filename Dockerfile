FROM ubuntu:22.04

WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y make gcovr lcov gcc perl git libpcre3-dev zlib1g-dev libssl-dev \
    && mkdir -p /artefacts /coverage /reports

COPY start_nginx.sh .
RUN chmod +x start_nginx.sh
# CMD ["tail", "-f", "/dev/null"]

ENTRYPOINT ["./start_nginx.sh"]
# На будующее, сменить права пользователя
