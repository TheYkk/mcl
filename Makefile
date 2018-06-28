.PHONY: clean build test

all: build

clean:
	@rm -rf linux-* rootfs* *.tar.* *.gz *.iso

build:
	@echo "Building builder ..."
	@docker build -t minimal-linux-script .
	@echo "Building image ..."
	$(eval CID=$(shell sh -c "docker run -d -i -t minimal-linux-script"))
	@docker logs -f $(CID)
	@echo "Copying image ..."
	@docker cp $(CID):/build/minimal_linux_live.iso .
	@docker cp $(CID):/build/isoimage/kernel.gz .
	@docker cp $(CID):/build/isoimage/rootfs.gz .

test: minimal_linux_live.iso
	@./test.sh -g
