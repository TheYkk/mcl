.PHONY: clean build test

all: build

clean:
	@rm -rf linux-* rootfs* *.tar.* *.gz *.xz *.iso

build:
	@echo "Building builder ..."
	@docker build -t minimal-linux-script .
	@echo "Building image ..."
	@docker run -i -t --name minimal_build minimal-linux-script
	@echo "Copying image ..."
	@docker cp minimal_build:/build/minimal_linux_live.iso .
	@docker cp minimal_build:/build/isoimage/kernel.gz .
	@docker cp minimal_build:/build/isoimage/rootfs.gz .
	@docker rm -f minimal_build

test:
	@./test.sh -g
