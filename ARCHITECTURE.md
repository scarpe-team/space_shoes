# SpaceShoes Architecture

## Distributions, Builds and Naming

There will be (predicted: 23 May 2024) full releases of e.g. Spacewalk that use specific builds of ruby.wasm, specific SpaceShoes versions, etc. But we also need to figure out filenames and locations for local builds, for debugging and customised per-app builds.

I don't want to build Wasm files to the app dir itself mostly -- it's too easy for them to be accidentally included in other Wasm files, leading to an absolute explosion of file size and load time. But where do I put temp builds outside the app directory, particularly for apps that need a custom build?

## Build Dirs

Right now (23 May 2024) we build in the app directory itself. That leaves a lot of files behind. It's not obvious what the right way to avoid it is, though -- wherever we run rbwasm, that directory needs the right Gemfile and Gemfile.lock, and the build picks up whatever files are in that directory, and we want it to.

It would be nice to be able to build more cleanly. For instance, imagine doing a Ruby build that could be shared between all apps so we didn't need to re-download and re-build Ruby for each app. You can get some of this with Spacewalk. But apps that need extra gems clearly can't use that, and apps that need extra files can't either.

## Files and Paths

The app directory that gets packed will have random files show up in the Wasi-Wasm file system (e.g. shows up with Dir.glob). However, mapped directories (e.g. src) do *not* show up with Dir.glob. So you have to already know they're there and change to them. In fact, it's generally hard to reliably get the top level dirs. This may cause trouble for some apps.

## Distributed Wasm Builds

Once things stabilise, we should make a basic default build with reasonable gems per-release that can be used directly (from Github?). This is for the single-file simple JS-based install. It should also be easy to make a default build locally, well before that.

It should also be very possible to do a custom build from a Ruby app directory when that app uses SpaceShoes. The default build is just this with particular directory contents.

## Host-Side vs App-Side (Guest-Side)

SpaceShoes has an App-Side environment. This most frequently happens inside the web browser, but could also be inside a different Wasm-based environment like Wasmtime. Eventually we may even support Ruby-to-JS translators. But inside any of these environments is considered to be App-Side, also referred to as Guest-Side.

There is also often a Host-Side environment for packaging, running HTTP servers, setting up Wasm builds and tools and so on.

Some files are intended to be required in the App-Side environment. Some are intended to be required from the Host-Side environment. A very few files (e.g. space_shoes/version.rb) are intended to be included by both.
