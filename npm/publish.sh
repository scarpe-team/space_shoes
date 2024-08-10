#!/bin/bash

set -e

# How do we want to install wasm-opt?

cp ../packaging/packed_ruby.wasm .
~/Desktop/binaryen-version_118/bin/wasm-opt packed_ruby.wasm -Os -o packed_ruby.wasm
cp ../test/cache/spacewalk.js .
#npm publish --access public
