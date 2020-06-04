# Packer for rtf

Small project to generate Packer files to maintain our vagrant cloud boxes.


## Dependencies

* `dhall-to-json` binary, from https://github.com/dhall-lang/dhall-haskell/releases (take only dhall-to-json binary)
* packer: https://packer.io/downloads.html
* virtualbox

## Build

```
# To make the source for debian10
make debian10

# Same with an agent
make debian10_agent

# To publish debian-10 on vagrant cloud
make debian10 CLOUD_TOKEN=xxx
```
