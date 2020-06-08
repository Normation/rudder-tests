DESTDIR = $(CURDIR)/target
PUBLISH = false

%_agent: %
	cp agent/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/agent.dhall > $(DESTDIR)/result.json

%:
	mkdir -p $(DESTDIR)
	lua packer.lua $@ $(PUBLISH) > $(DESTDIR)/result.json
	packer validate -var cloud_token=$(CLOUD_TOKEN) $(DESTDIR)/result.json
	packer build -var cloud_token=$(CLOUD_TOKEN) -on-error=abort target/result.json

clean:
	rm -rf target output-virtualbox-iso

