# Packer for rtf

Small project to generate Packer files to maintain our vagrant cloud boxes.


## Dependencies

* `dhall-to-json` binary, from [https://dhall-lang.org/](https://dhall-lang.org/)
* packer: https://packer.io/downloads.html

## Build

```
# To make the source for debian10
make debian10

# Same with an agent
make debian10_agent
```
