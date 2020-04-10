OS = ubuntu18 debian10 sles12 bob
.PHONY: $(OS)

DESTDIR = $(CURDIR)/target

%_agent: %
	cp agent/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/agent.dhall > $(DESTDIR)/result.json

$(OS):
	mkdir -p $(DESTDIR)/build
	cp $@/*.dhall $(DESTDIR)/build
	cp common/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/template.dhall > $(DESTDIR)/result.json
	packer validate $(DESTDIR)/result.json

clean:
	rm -rf target

