DESTDIR = $(CURDIR)/target
PUBLISH = false

%_agent: %
	cp agent/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/agent.dhall > $(DESTDIR)/result.json

%:
	@date
	mkdir -p $(DESTDIR)
	lua packer.lua $@ $(PUBLISH) $(CLOUD_TOKEN) > $(DESTDIR)/result.json
	packer validate $(DESTDIR)/result.json
	packer build -on-error=abort target/result.json
	@date

clean:
	rm -rf target output-virtualbox-iso

veryclean: clean
	rm -rf builds
