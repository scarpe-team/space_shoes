# SpaceShoes Architecture

## Host-Side vs App-Side

SpaceShoes has an App-Side environment. This most frequently happens inside the web browser, but could also be inside a different Wasm-based environment like Wasmtime. Eventually we may even support Ruby-to-JS translators. But inside any of these environments is considered to be App-Side.

There is also often a Host-Side environment for packaging, running HTTP servers, setting up Wasm builds and tools and so on.

Some files are intended to be required in the App-Side environment. Some are intended to be required from the Host-Side environment. A very few files (e.g. space_shoes/version.rb) are intended to be included by both.
