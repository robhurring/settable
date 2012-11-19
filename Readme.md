# Settable 3.0

An alternative to using rails' environment files or YAML for application config. Settable was created out of the frustration of
missing a config setting in an environment file, or constantly duplicating YAML keys for different environments. Settable helps
make your config "safe" by always having a default value, and its built using Ruby so it is highly customizable and powerful.

Check the Usage for some details on how it can be used.

**Note:** This is a complete re-write from settable v2.0 and not backwards compatible. The old code was clunky and confusing, so
it was refactored to be cleaner and a little more flexible.


## Installation

Add this line to your application's Gemfile:

    gem 'settable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install settable

## Usage

### Basic Usage

```ruby
$config = Settable.configure do
  # basic set, similar to capistrano and sinatra
  set :username, 'user'
  set :password, 's3kr1t'

  # namespace support to keep config clean
  namespace :tracking do
    set :enabled, true
  end

  set :block do
    'blocks are allowed too!'
  end
end

if params[:user] == $config.username && params[:password] == $config.password
  ...
end

# all settings have a "presence" method, just add a "?" to check if it has been set
if $config.tracking.enabled?
  ...
end
```

### Rails Integration

```ruby
# config/initializers/app_config.rb
$config = Settable.configure do
  # this enables the +environment+ helpers below, so we can set values in specific
  # environments only. (environment testers can be swapped out - see the advanced example)
  use_environment :rails

  set :username do
    # checks Rails.env and will return 'superadmin' when in production
    environment :production, 'superadmin'

    # defaults back to 'devuser' if environment doesn't match
    'devuser'
  end

  set :password do
    environment :production, 's3kr1t'

    'defaultpassword'
  end

  set :tracking do
    # check if we're in production _or_ staging
    environment [:production, :staging], true
    false
  end
end

# some_controller.rb
http_basic_authenticate_with name: $config.username, password: $config.password
```

### Advanced Integration

To use a custom class/namespace for your configuration you can do the following:

```ruby
class MyApp
  # include the Settable DSL
  include Settable

  # create a custom environment tester, any object that respond to #matches?(value) can be used
  # as an environment tester. This is in the core code when using "use_environment :env"
  module EnvironmentTester
    def self.matches?(environment)
      ::ENV.has_key?(environment.to_s.upcase)
    end
  end

  # creates a class and instance method +config+ that holds all settings
  settable :config do
    # use our custom env tester for all +environment+ calls
    use_environment EnvironmentTester

    set :redis_uri do
      # check our ENV for the REDIS_TO_GO_URL key
      environment :REDIS_TO_GO_URL do
        ENV['REDIS_TO_GO_URL']
      end

      # default to localhost if not found
      'localhost:6379'
    end
  end

  def redis
    Redis.new(config.redis_uri)
  end
end

$app = MyApp.new
$redis = $app.redis
# you can also reach the redis_uri at MyApp.config.redis_uri
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
