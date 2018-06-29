FROM alpine:3.7

RUN apk -U add wget bc build-base gawk xorriso libelf-dev openssl-dev bison flex
RUN apk -U add linux-headers
RUN apk -U add perl

COPY . /build

WORKDIR /build

CMD ["./build.sh"]
