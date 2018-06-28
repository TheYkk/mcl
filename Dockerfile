FROM ubuntu:trusty

RUN apt-get update && \
    apt-get install -y wget bc build-essential gawk xorriso && \
    apt-get clean

COPY . /build

WORKDIR /build

CMD ["./build.sh"]
