#!/bin/bash

set -e

cp ../packaging/packed_ruby.wasm .
cp ../test/cache/spacewalk.js .
npm publish --access public
