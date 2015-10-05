# Epuber

[![Build Status](https://travis-ci.org/epuber-io/epuber.svg?branch=master)](https://travis-ci.org/epuber-io/epuber)

Epuber is simple tool to compile and pack source files into EPUB format. Offers to define multiple "targets" which allows to create multiple versions of the book by running only one command. Eliminates copying code and information, eliminates needs to use _git_ branches to differ ebook content.


## Features

- creating multiple versions of book with requirement to maintain only one source (e.g. for iBooks, Google Play, ...)
    - defined constants are usable in almost all source files
- using template engines (currenlty only [Bade](https://github.com/epuber-io/bade)), css preprocessors (currently only Stylus) and standard EPUB formats at the same time
- have local development server which
    - automatically refresh web browser when some source file changes
    - quick jumping to next page with arrow keys on keyboard
- supports EPUB 2 and 3 + MOBI


## Installation

Installation is easy, just type following line to terminal:

    $ gem install epuber


## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samnung/bade. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## TODO

- [ ] move all cards from Trello to GitHub
- [ ] create documentation 
- [ ] create several examples of book specification

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
