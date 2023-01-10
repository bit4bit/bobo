# bobo

TODO: Write a description here

## Installation

TODO: Write installation instructions here

## Usage

1. `rake prod`
2. start mob
 1. `bash scripts/ssl_self.sh <my domain>`
 1. `./bin/bobo-mob -p 9691`
3. start programmer
 1. `./bin/bobo-programmer -i <MOB ID> -u <PROGRAMMIR ID> -l https://<BOBO DOMAIN>:9691`

## Development

1. testing
  1. `cd acceptante`
  2. `bundle install --path .vendor`
  3. `bash ../scripts/ssl_self.sh localhost`
  4. `bundle exec cucumber`
2. compiling
  1. `rake prod`
  
## Contributing

1. Fork it (<https://github.com/your-github-user/bobo/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jovany Leandro G.C](https://github.com/your-github-user) - creator and maintainer
