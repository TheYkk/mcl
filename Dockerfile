FROM ubuntu:trusty

RUN apt-get update && \
    apt-get install -y wget bc build-essential gawk xorriso && \
    apt-get install -y libelf-dev libssl-dev bison flex && \
    apt-get clean

COPY . /build

WORKDIR /build

CMD ["./build.sh"]
