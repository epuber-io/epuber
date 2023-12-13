# Bookspec

Bookspec is file with `.bookspec` extension. It is the main file for each book when using Epuber. It's syntax is purely in Ruby. It is good to know a little bit about Ruby's syntax to write Bookspec file.

Bookspec holds all info about the book:

- metadata
- spine (chronological order of text files)
- table of contents (TOC)

And some other information about how to build the book:

- targets
- plugins
- other resource files that Epuber does not detect automatically

To create bookspec from scratch you can just create new text file and place this code in it:

```rb
Epuber::Book.new do |book|
  book.title = 'Book'
end
```

Or you can execute `epuber init` command and it will create all files and folders for you.

## Properties

Bookspec holds a lot of information about the book, let's show you all of them and add you some info about how to use them.

Following examples will be shown in this context:

```rb
Epuber::Book.new do |book|
  <<here>>
end
```

### Title (required)

Book's title. Epuber does support only single one (EPUB does support multiple, but not every reader will show them correctly).

```rb
book.title = 'Epuber example book'
```

This value will be added to content.opf file into `<dc:title>` tag.

### Subtitle (optional)

Book's subtitle.

```rb
book.subtitle = "Learn how to use Epuber and leverage it's greatness"
```

This value is not added anywhere in result EPUB (you can place it in Bade).

### Authors (required)

Book can have single or multiple authors (or contributors). By default all of them have role _author_.

```rb
book.author = 'Roman Kříž'

# use array to set multiple authors
book.authors = [
  'Roman Kříž',
  'Josef Novák',
]
```

Authors/contributors are placed in content.opf in `<dc:creator>` tags with correct structure depending on EPUB 2 or EPUB 3 output.

#### Custom version

Epuber tries to parse names and create file-as correctly even for more complicated names. But it can't be perfect. You can specify each part using Hash object and keys `first_name` and `last_name`. Such Hash object is written like this:

```rb
book.author = { first_name: 'Roman', last_name: 'Kříž' }
```

Or in multiline version:

```rb
book.author = {
  first_name: 'Roman',
  last_name: 'Kříž',
}
```

##### Pretty name / file-as

Pretty name and file-as is automatically calculated. But you can specify them using this syntax:

```rb
book.author = { pretty_name: 'Roman Kříž', file_as: 'KŘÍŽ, Roman' }
```

##### Role

And to specify role you have to use Hash syntax and use key `role` to set it, like in this example:

```rb
book.author = { name: 'Roman Kříž', role: 'ill' }
```
