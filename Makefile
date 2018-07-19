.PHONY: clean build test

all: build

clean:
	@rm -rf *.gz *.iso

build:
	@echo "Building builder ..."
	@docker build -t mcl/builder .
	@echo "Building image ..."
	@docker run -i -t --name mcl_build mcl/builder
	@echo "Copying image ..."
	@docker cp mcl_build:/build/mcl.iso .
	@docker cp mcl_build:/build/kernel.gz .
	@docker cp mcl_build:/build/rootfs.gz .
	@docker cp mcl_build:/build/clouddrive.iso .
	@docker rm -f mcl_build

repack:
	@echo "Building builder ..."
	@docker build -t mcl/builder .
	@echo "Building image ..."
	@docker run -i -t --name mcl_build mcl/builder repack
	@echo "Copying image ..."
	@docker cp mcl_build:/build/mcl.iso .
	@docker cp mcl_build:/build/rootfs.gz .
	@docker cp mcl_build:/build/clouddrive.iso .
	@docker rm -f mcl_build

test:
	@./test.sh -g
