# package-builder
This repo sketches out a very simple (yet very powerful) package build system written in bash. While parts will be rewritten for performance (and to integrate a real package manager). Some parts such as environment setup will likely be part of another tool.

## How to use

Clone the repo and run a package build. To build zlib simply:

```
git clone https://github.com/sunnyflunk/package-builder.git
cd package-builder
./pb.sh zlib serpent-default
```

## Requirements

Currently you will need all the required headers, compiler and build tools needed for each build installed locally until it is integrated to an actual build system.
