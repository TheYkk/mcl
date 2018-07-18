FROM alpine:3.7

RUN apk -U add wget bc build-base gawk xorriso libelf-dev openssl-dev bison flex
RUN apk -U add linux-headers perl
RUN apk -U add rsync git

COPY . /build

WORKDIR /build

ENTRYPOINT ["./build.sh"]
CMD [""]
