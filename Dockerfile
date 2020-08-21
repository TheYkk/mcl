FROM alpine:3.12

RUN apk -U add wget \
	bc build-base gawk xorriso libelf-dev openssl-dev bison flex \
	linux-headers perl rsync git argp-standalone make  gcc-10 

WORKDIR /build

COPY build.sh /tmp/build.sh
RUN /tmp/build.sh download

COPY . /build

ENTRYPOINT ["./build.sh"]
CMD ["build"]
