$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'doorkeeper/version'

Gem::Specification.new do |gem|
  gem.name        = 'doorkeeper'
  gem.version     = Doorkeeper.gem_version
  gem.authors     = ['Felipe Elias Philipp', 'Tute Costa', 'Jon Moss', 'Nikita Bulai']
  gem.email       = %w(bulaj.nikita@gmail.com)
  gem.homepage    = 'https://github.com/doorkeeper-gem/doorkeeper'
  gem.summary     = 'OAuth 2 provider for Rails and Grape'
  gem.description = 'Doorkeeper is an OAuth 2 provider for Rails and Grape.'
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.require_paths = ['lib']

  gem.add_dependency 'railties', '>= 4.2'
  gem.required_ruby_version = '>= 2.1'

  gem.add_development_dependency 'capybara', '~> 2.18'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'danger', '~> 5.0'
  gem.add_development_dependency 'grape'
  gem.add_development_dependency 'database_cleaner', '~> 1.6'
  gem.add_development_dependency 'factory_bot', '~> 4.8'
  gem.add_development_dependency 'generator_spec', '~> 0.9.3'
  gem.add_development_dependency 'rake', '>= 11.3.0'
  gem.add_development_dependency 'rspec-rails'
end
