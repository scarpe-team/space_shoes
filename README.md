# SpaceShoes

SpaceShoes allows embedding Ruby GUI code in your web pages. Its based on the old Shoes library by \_why, and by Giovanni Borgh's work on [Scarpe-Wasm](https://github.com/scarpe-team/scarpe-wasm).

## Javascript-Based Installation

SpaceShoes operates in two ways. You can use it in a Ruby application and bundle that into a web site. Or you can use it via a Wasm module included from Javascript.

JS-based installation is useful if you have a single Shoes file with no additional files included, or with only files you can include via URL. It's also a great way to experiment with SpaceShoes without a complicated installation.

(MORE INSTALL INSTRUCTIONS HERE)

## Ruby-Based Installation

If you want or need multiple files bundled into a Wasm module, you'll start from the Ruby side.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add space_shoes

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install space_shoes

(MORE INSTALL INSTRUCTIONS HERE)

## Usage

TODO: Write usage instructions here

## Development

You'll need a Ruby-based install to help develop SpaceShoes.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scarpe-team/space_shoes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SpaceShoes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scarpe-team/space_shoes/blob/main/CODE_OF_CONDUCT.md).
