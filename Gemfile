# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in space_shoes.gemspec
gemspec

#gem "js"

group :development do
  gem "rake", "~> 13.0"
  gem "minitest", "~> 5.16"
  gem "webrick", "~> 1.8.1"
  gem "capybara"
  gem "selenium-webdriver"
  gem "nokogiri", ">= 1.16.5" # Capybara dependency
end

gem "lacci", github: "scarpe-team/scarpe", glob: "lacci/lacci.gemspec"
gem "scarpe-components", github: "scarpe-team/scarpe", glob: "scarpe-components/scarpe-components.gemspec"

