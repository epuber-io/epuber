# Epuber

[![Gem Version](https://badge.fury.io/rb/epuber.svg)](http://badge.fury.io/rb/epuber) [![Build Status](https://travis-ci.org/epuber-io/epuber.svg?branch=master)](https://travis-ci.org/epuber-io/epuber) [![Coverage Status](https://coveralls.io/repos/epuber-io/epuber/badge.svg?branch=master&service=github)](https://coveralls.io/github/epuber-io/epuber?branch=master) [![Inline docs](http://inch-ci.org/github/epuber-io/epuber.svg?branch=master)](http://inch-ci.org/github/epuber-io/epuber) [![Join the chat at https://gitter.im/epuber-io/epuber](https://badges.gitter.im/epuber-io/epuber.svg)](https://gitter.im/epuber-io/epuber?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Epuber is simple tool to compile and pack source files into EPUB format. Offers to define multiple "targets" which allows to create multiple versions of the book by running only one command. Eliminates copying code and information, eliminates needs to use _git_ branches to differ ebook content.


## Features

Simple example of `.bookspec` file defining all book's metadata and Table Of Contents. This file can be generated by running command `epuber init`.

```ruby
Epuber::Book.new do |book|
  book.title = 'Epuber example book'
  book.author = 'Roman Kříž'
  book.isbn = '123-45-67890-12-3'
  book.version = '1.0.1'
  book.build_version = '5'

  book.cover_image = 'cover'
  book.add_default_style 'default_style.styl'

  # create spine and toc
  book.toc do |toc|
    toc.file 'cover', :landmark_cover
    toc.file 'copyright', :landmark_copyright
    toc.file 'toc', :landmark_toc

    toc.file 'intro', 'Intro'

    toc.file 'chapter_01', 'Chapter One' do
      toc.file '#section_01', 'Section One, awesome'
      toc.file '#section_02', 'Section Two, more awesome'
      toc.file '#section_03', 'Section Three, wow, much, very'
    end

    toc.file 'conclusion', 'Conclusion'

    toc.file 'footnotes', 'Footnotes', linear: false
  end

  # load basic validators folder with ruby scripts
  book.use 'basic_validators/'
end
```

Except for paths to plugins `book.use`, every path could be only name of the file, even without extension. So you can rename them, move them, the correct path will always resolved. Only exception is when the same name has more then one file.

           | Epuber
-----------|------------------------------------------------------------
:book:     | Creates seamless workflow for creating ebooks
:monorail: | Defines different _targets_ for several book stores (iBookstore, Google Play store, ...)
:wrench:   | Extend and customise the functionality with _plugins_
:pencil2:  | Defines _constants_ so you can have link to related book in proper book store
:pencil:   | Defines mechanisms to deal with duplicated 
:tophat:   | Easy setup assistant to get started in a few minutes
:ghost:    | Automatically validates generated text so you don't have to worry about typos and other mistakes
:rocket:   | Saves you **hours** when developing new or updating existing book
:page_with_curl: | Supports template engines, CSS preprocessors and standard EPUB formats at the same time
:computer: | Have local development web server to iterate and experiment quickly
:loop:     | Automatically refresh web browser when some source file changes
:bomb:     | Quick jumping through pages with arrow keys on keyboard
:closed_book: | Supports EPUB 2 and 3


## Installation

First of all Epuber uses [RMagick](https://github.com/rmagick/rmagick) which has several external dependencies, so you have to install that first:

- ImageMagick
- pkg-config

On OS X make sure you Xcode Command Line Tools installed:
    
    xcode-select --install

And the easiest way to install prerequisites on OS X is to use [brew](http://brew.sh):

    brew install imagemagick pkg-config

On Ubuntu, you can run:

    sudo apt-get install libmagickwand-dev


### Finish

Then just type following line to terminal:

    sudo gem install epuber

If everything goes well, try running following line in terminal:

    epuber --help


## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/epuber-io/epuber. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## TODO

- [ ] move all cards from Trello to GitHub
- [ ] create documentation 
- [ ] create several examples of book specification

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
