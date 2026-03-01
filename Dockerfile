FROM ubuntu:22.04

WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y make gcovr lcov gcc git libpcre3-dev zlib1g-dev libssl-dev \
    && mkdir -p /artefacts /coverage /reports

COPY start_nginx.sh .
ARG build_type
RUN chmod +x start_nginx.sh && ./start_nginx.sh $build_type

CMD ["tail", "-f", "/dev/null"]
# На будующее, сменить права пользователя
