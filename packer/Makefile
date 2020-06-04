DESTDIR = $(CURDIR)/target

%_agent: %
	cp agent/*.dhall $(DESTDIR)/build
	dhall-to-json --file $(DESTDIR)/build/agent.dhall > $(DESTDIR)/result.json

%:
	mkdir -p $(DESTDIR)/build
	cp common/*.dhall $(DESTDIR)/build
	cp systems/$@.dhall $(DESTDIR)/build/system.dhall
ifeq ($(CLOUD_TOKEN),)
	# don't know ho to exclude data in dhall, so it's always in and we remot it when we don't want it
#	sed -i -e 's/, vagrant_cloud//' $(DESTDIR)/build/template.dhall
endif
	dhall-to-json --file $(DESTDIR)/build/template.dhall > $(DESTDIR)/result.json
	packer validate -var cloud_token=$(CLOUD_TOKEN) $(DESTDIR)/result.json
#	packer build -on-error=abort target/result.json

clean:
	rm -rf target output-virtualbox-iso

