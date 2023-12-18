# Plugins

Epuber has basic support for plugins. There are several ways to attach into Epuber's building process. You can add
validation steps or transform files.

To start using plugins you need to specify what files or folders Epuber should use. You can do that by calling `use`
method in bookspec, like in following example:

```ruby
Epuber::Book.new do |book|
    # ... metadata ...

    # use single file
    book.use 'validations.rb'

    # use whole folder
    book.use 'url_plugin/'
end
```

When specifying folder, Epuber will find all Ruby files (recursive) and use them as plugin files.

Plugin file allows to create validator or transformer. You can define multiple validators and/or transformers in single
file. Following example is basic structure of how to implement such plugin:

```ruby
check <type> do |checker|
  # this will be called at some point
end

transform <type> do |transformer|
  # this will be called at some point
end
```

Change `<type>` to type of validator or transformer. See in next sections.


## Validators

To validate files you have following types:

- `:result_text_xhtml_string` - will be triggered after converting all text files to result (X)HTML
- `:source_text_file` - will be triggered after loading source files (either (X)HTML or Bade)
- `:bookspec` - will be triggered after loading bookspec file

### API

Reporting of warnings or errors:

`checker.warning(message | problem)` - will print warning message to console
`checker.error(message | problem)` - will print error message to console (will stop build when doing release build)

You can pass strings or match problems. You can see them in following example:

```ruby
check :result_text_xhtml_string do |checker|
  if checker.file_path =~ /chapter_[0-9]+.xhtml/ && !checker.text.include?('<h1')
    checker.error('Missing required header in chapter')
  end

  if checker.text =~ /[-–—][-–—]+/i
    match = Regexp.last_match
    # report issue
    problem = Epuber::Checker::TextChecker::MatchProblem.new(match, 'Contains redundant dashes', checker.file_path)
    checker.warning(problem)
  end
end
```

### Types

#### `:result_text_xhtml_string`

You can validate final (X)HTML file. This is triggered for each file at the end of processing.

File is not really final, only thing missing is to resolve [global IDs](./usage.md#global-ids).

Example of validation plugin:

```ruby
check :result_text_xhtml_string do |checker, xhtml_string, context|
  # result file should not contain span without any attributes (case-sensitive)
  checker.should_not_contain(/<span>/, 'this is message')

  # same example, but case-INsensitive (see letter "i" after regex)
  checker.should_not_contain(/<span>/i, 'this is message')
end
```

You can also perform any validation you would like:

```ruby
check :result_text_xhtml_string do |checker|
  # parse using Nokogiri library
  doc = Nokogiri::XML(checker.text)

  # go through all nodes
  doc.traverse do |node|
    # validate only text nodes
    if node.text?
      # check for multiple dashes next to each other
      if node.to_s =~ /[-–—][-–—]+/i
        match = Regexp.last_match

        # report issue
        problem = Epuber::Checker::TextChecker::MatchProblem.new(match, 'Contains redundant dashes', checker.file_path)
        checker.warning(problem)
      end
    end
  end
end
```

To start using Nokogiri look at this [cheat sheet](https://gist.github.com/carolineartz/10276637) or their [documentation pages](https://nokogiri.org/index.html).

#### `:source_text_file`

You can validate source (X)HTML or Bade file. This is triggered for each file right after initial loading.

```ruby
check :source_text_file do |checker|
  # source file should not contain span without any attributes
  checker.should_not_contain(/<span>/i, 'this is message')
end
```

#### `:bookspec`

You can also validate Bookspec file. This is triggered right after loading Bookspec file.

```ruby
check :bookspec do |checker|
  checker.error('ISBN is invalid') if checker.book.isbn == '123'
end
```


## Transformers

To transform files you have following types to attach to:

- `:result_text_xhtml_string` - will be triggered after converting all text files to result (X)HTML
- `:source_text_file` - will be triggered after loading source files (either (X)HTML or Bade)
- `:after_all_text_files` - will be triggered after processing all text files

### Types

#### `:result_text_xhtml_string`

You can transform final (X)HTML file. This is triggered for each file at the end of processing.

```ruby
transform :result_text_xhtml_string do |transformer|
  transformer.replace_all('i', 'o')
  transformer.replace_all(/i/, 'o')
end
```

#### `:source_text_file`

You can transform source (X)HTML or Bade file. This is triggered for each file right after initial loading.

```ruby
transform :source_text_file do |transformer|
  transformer.replace_all('i', 'o')
  transformer.replace_all(/i/, 'o')
end
```

#### `:after_all_text_files`

This is triggered once after all text files are processed. This is good place to create some links between all files,
like footnotes or endnotes.

```ruby
transform :after_all_text_files do |transformer|
  transformer.find_destination_files('text/chapter_*.xhtml').each do |file|
    content = transformer.read_destination_path(file)
    content.gsub!(/i/, 'o')
    transformer.write_destination_file(file, content)
  end
end
```

##### API

This transformer has some more APIs so you can easily start writing plugin.

Pattern are like everywhere else, it can be relative (from bookspec in this case), absolute from root of the project, don't have to contain extension.

`find_file(path | pattern)` - find file, return instance or nil
`find_destination_files(path | pattern)` - return all files matching path or pattern
`get_file(path | pattern)` - find file, return instance or throw exception
`read_destination_file(path | pattern | instance)` - read file from destination folder and returns it as string
`write_destination_file(path | pattern | instance, content)` - write file to destination folder
