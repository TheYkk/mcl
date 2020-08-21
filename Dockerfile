FROM ubuntu

RUN apt update && apt install wget \
	bc \
  build-essential \
  gawk \
  xorriso \
  libelf-dev \
  libssl-dev \
  bison \
  flex \
  perl \
  rsync \
  git \
  make \
  gcc 

WORKDIR /build

COPY build.sh /tmp/build.sh
RUN /tmp/build.sh download

COPY . /build

ENTRYPOINT ["./build.sh"]
CMD ["build"]
