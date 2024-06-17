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

  <script type="module" src="https://cdn.jsdelivr.net/npm/@spaceshoes/spacewalk/spacewalk.js"></script>
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

That little text/ruby block with Shoes.app inside the Ruby script block? That's a real Shoes app, running [ruby.wasm](https://github.com/ruby/ruby.wasm). If you put other Ruby code in there, it will do Ruby things. If you put other Shoes code in there, it will do Shoes things. It's all done in your browser.

You don't have to have Ruby installed. You don't need to clone the SpaceShoes repository. All you need is to create a little HTML file and open it in the browser. It's even fine as a file URL.

## Local Spacewalk

If you've cloned the repository, you can build your own spacewalk.js. Run "bundle install" to get the appropriate gems and then run this:

    ./exe/space-shoes --dev build-default

That will build a local packed_ruby.wasm containing a Ruby build and your locally-modified version of SpaceShoes. If you make changes to SpaceShoes, that's a great way to test them.

You can also run the tests:

    rake test

There's a little example of using local SpaceShoes in html/templates/shoes_embed.html. It uses the spacewalk.js in html/templates. It won't work with a file URL though, because CORS policy doesn't like file URLs. So you'll need to run a local HTML server in the appropriate directory, something like this:

    # From SpaceShoes root directory
    ruby -run -e httpd -- -p 4321 .

Then you can access it with a local URL like "http://localhost:4321/html/templates/shoes_embed.html"

## Your Very Own Spacewalk

You can also build a packaged-up file for your app. If you want or need multiple files bundled into a Wasm module, you'll start from the Ruby side.

Add SpaceShoes to the application's Gemfile by executing:

    $ bundle add space_shoes

~~~HTML
<!DOCTYPE html>
<html lang="en">
  <head>

  <script type="module" src="spacewalk.js"></script>
  <script type="text/ruby">
    Shoes.app do
      para "Images are good too."
      image "my_local_file.png" # TODO: test me!
    end
  </script>

  </head>
  <body>
  </body>
</html>
~~~

TODO: more information about how to make this work.

## Binaryen

* https://github.com/WebAssembly/binaryen/releases
* tested with version 117
* install for your platform
* copy wasm-opt into your path

```
# Taken from Largo's ruby.wasm build instructions
bundle exec rbwasm --log-level debug build --ruby-version 3.3 --target wasm32-unknown-wasi --build-profile full  -o ruby-app.wasm
# Remove the debug info
wasm-opt --strip-debug ruby-app.wasm -o ruby-app.wasm
# Optimize for size without hurting speed as much.
wasm-opt ruby-app.wasm -Os -o ruby-app.wasm
```

To create a new NPM package you'll need to use wasm-opt to reduce the file size below 50MB.

## Development

You'll need a Ruby-based install to help develop SpaceShoes. You'll need Ruby 3.2 or later, probably installed via a version manager like chruby or rvm.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scarpe-team/space_shoes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).

## Random Notes and References

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
