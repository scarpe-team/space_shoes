# SpaceShoes

SpaceShoes allows embedding Ruby GUI code in your web pages. You can embed simple Ruby GUI applications directly or you can write a multi-file application and package it up to be loaded from the page or pages of your choice.

SpaceShoes is based on [Scarpe](https://github.com/scarpe-team/scarpe), which is a reimplementation of Shoes by [_why the lucky stiff](https://en.wikipedia.org/wiki/Why_the_lucky_stiff). It contains a lot of code from [Scarpe-Wasm](https://github.com/scarpe-team/scarpe-wasm) by [Giovanni Borgh](https://github.com/alawysdelta/) and [Noah Gibbs](https://github.com/noahgibbs).

## The Simplest Spacewalk

SpaceShoes does a few different tricks. The easiest is for you to add a line in an HTML page and then run your Shoes app right from the page.

Here's how that looks:

~~~HTML
<!DOCTYPE html>
<html lang="en">
  <head>

  <script type="module" src="spacewalk.js"></script>
  <script type="text/ruby">
    Shoes.app do
      @p = para "Buttons are good!"
      button("OK") { @p.replace("Buttons are amazing!") }
    end
  </script>

  </head>
  <body>
  </body>
</html>
~~~

That little block with Shoes.app inside the Ruby script block? That's a real Shoes app, running [ruby.wasm](https://github.com/ruby/ruby.wasm). If you put other Ruby code in there, it will do Ruby things. If you put other Shoes code in there, it will do Shoes things.

But first you'll need that spacewalk.js file to exist and be useful. If you've checked out the SpaceShoes repository, a simple "bundle install" followed by "./exe/space-shoes --dev build-default" will create the files you need.

(TODO: add npm-module-based spacewalks)

## Bundled Applications

If you want or need multiple files bundled into a Wasm module, you'll start from the Ruby side.

Add SpaceShoes to the application's Gemfile by executing:

    $ bundle add space_shoes

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install space_shoes

(MORE INSTALL INSTRUCTIONS HERE)

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

Single-line HTTP server: "ruby -run -e httpd -- -p 4321 ."

EvilMartians blog post on using Ruby.wasm's Bundler integration
    https://evilmartians.com/chronicles/first-steps-with-ruby-wasm-or-building-ruby-next-playground

## History

[Giovanni Borgh](https://github.com/alawysdelta/) wrote the initial scarpe-wasm code, including tools like wasify, for his Google Summer of Code project. Noah Gibbs then adapted it to Scarpe and its dependencies (e.g. Lacci, Scarpe-Components, Calzini).

The top-level structure of SpaceShoes is different from scarpe-wasm. But a lot of the actual initial code comes from scarpe-wasm and was co-written by Noah Gibbs and/or Giovanni Borgh. The import of scarpe-wasm doesn't attempt to tease all this apart accurately - there are some commits that credit Giovanni as co-author in general, but mostly the code is just copied over.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SpaceShoes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).
