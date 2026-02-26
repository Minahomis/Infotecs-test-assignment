FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y make cmake gcovr lcov gcc g++ git

RUN mkdir -p /artefacts /coverage /reports

CMD ["/bin/bash"]
