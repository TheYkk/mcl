.PHONY: clean build test

all: build

clean:
	@rm -rf kernel.gz rootfs.gz minimal.iso

build:
	@echo "Building builder ..."
	@docker build -t minimal/builder .
	@echo "Building image ..."
	@docker run -i -t --name minimal_build minimal/builder
	@echo "Copying image ..."
	@docker cp minimal_build:/build/minimal.iso .
	@docker cp minimal_build:/build/kernel.gz .
	@docker cp minimal_build:/build/rootfs.gz .
	@docker cp minimal_build:/build/clouddrive.iso .
	@docker rm -f minimal_build

repack:
	@echo "Building builder ..."
	@docker build -t minimal/builder .
	@echo "Building image ..."
	@docker run -i -t --name minimal_build minimal/builder repack
	@echo "Copying image ..."
	@docker cp minimal_build:/build/minimal.iso .
	@docker cp minimal_build:/build/rootfs.gz .
	@docker cp minimal_build:/build/clouddrive.iso .
	@docker rm -f minimal_build

test:
	@./test.sh -g
