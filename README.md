# SpaceShoes

SpaceShoes allows embedding Ruby GUI code in your web pages. You can embed simple Ruby GUI applications directly or you can write a multi-file application and package it up to be loaded from the page or pages of your choice.

SpaceShoes is based on [Scarpe](https://github.com/scarpe-team/scarpe), which is a reimplementation of Shoes by [_why the lucky stiff](https://en.wikipedia.org/wiki/Why_the_lucky_stiff). It contains a lot of code from [Scarpe-Wasm](https://github.com/scarpe-team/scarpe-wasm) by [Giovanni Borgh](https://github.com/alawysdelta/) and [Noah Gibbs](https://github.com/noahgibbs).

## Javascript-Based Installation

SpaceShoes operates in two ways. You can use it in a Ruby application and bundle that into a web site. Or you can use it via a Wasm module included from Javascript.

JS-based installation is useful if you have a single Shoes file with no additional files included, or with only files you can reference via URL. It's a great way to experiment with SpaceShoes without repeated build steps.

You'll still need to create a Wasm module containing the SpaceShoes code and some default gems and so on.

    $ space_shoes build-default

(MORE INSTALL INSTRUCTIONS HERE)

## Ruby-Based Applications

If you want or need multiple files bundled into a Wasm module, you'll start from the Ruby side.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add space_shoes

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install space_shoes

You can directly run SpaceShoes-based apps from the command line, which will package the application and run a browser:

    $ space_shoes my_app.rb

You can also package a SpaceShoes application to be included in a web page of your choice:

    $ space_shoes src-package my_app_dir

(MORE INSTALL INSTRUCTIONS HERE)

## Usage

TODO: Write usage instructions here

## Development

You'll need a Ruby-based install to help develop SpaceShoes.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scarpe-team/space_shoes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).

## References

This will package gems in ruby.wasm, built into the Ruby binary
    bundle exec rbwasm build --ruby-version 3.3 -o ruby.wasm

Think we can use the built Ruby-with-gems with rbwasm pack to combine with source dir
    bundle exec rbwasm pack ruby.wasm --mapdir GUESTDIR:HOSTDIR -o packed_ruby.wasm

To install wasmtime for testing: https://github.com/bytecodealliance/wasmtime

EvilMartians blog post on using Ruby.wasm's Bundler integration
    https://evilmartians.com/chronicles/first-steps-with-ruby-wasm-or-building-ruby-next-playground

## History

[Giovanni Borgh](https://github.com/alawysdelta/) wrote the initial scarpe-wasm code, including tools like wasify, for his Google Summer of Code project. Noah Gibbs then adapted it to Scarpe and its dependencies (e.g. Lacci, Scarpe-Components, Calzini).

The top-level structure of SpaceShoes is different from scarpe-wasm. But a lot of the actual initial code comes from scarpe-wasm and was co-written by Noah Gibbs and/or Giovanni Borgh. The import of scarpe-wasm doesn't attempt to tease all this apart accurately - there are some commits that credit Giovanni as co-author in general, but mostly the code is just copied over.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SpaceShoes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).
