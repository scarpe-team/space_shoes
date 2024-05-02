# SpaceShoes Architecture

## Ruby-Side vs JS-Side

Some files are intended to be required from Ruby inside the Browser (or other Wasm) side. Some are intended to be required from Ruby outside Wasm, especially for packaging, or setting up the Wasm and HTTP environment.

A very few files (e.g. space_shoes/version.rb) are intended to be included by both.
