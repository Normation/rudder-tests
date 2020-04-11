DESTDIR = $(CURDIR)/target

%_agent: %
	cp agent/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/agent.dhall > $(DESTDIR)/result.json

%:
	mkdir -p $(DESTDIR)/build
	cp common/*.dhall $(DESTDIR)/build
	cp systems/$@.dhall $(DESTDIR)/build/system.dhall
	dhall-to-json --file $(DESTDIR)/build/template.dhall > $(DESTDIR)/result.json
	packer validate $(DESTDIR)/result.json
	packer build -on-error=abort target/result.json

clean:
	rm -rf target output-virtualbox-iso

