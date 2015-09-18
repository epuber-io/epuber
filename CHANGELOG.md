
# CHANGELOG

## v0.3.1.beta.1

- [FileResolver] #file_with_source_path now can find file with absolute source path
- [Server] fix several crashes because of not existing constants, etc
- [Server] fix calculation of relative path to destination path (causing to break style auto refreshes)
- [XHTMLProcessor] fix resolving images with unicode path
- [FileTypes::ImageFile] create folder if doesn't exists (causing to crash the compilation)
- [Compiler] now prints current file, helps with debugging and general using
- [Server] fix urls on page /files
- [Checker & Transformer] add third parameter CompilationContext

## v0.3

After a lot changes in core, bumping to 0.3.

- [bower] update cookies-js to 1.2.2 and uri.js to 1.15.2
- Rewritten file type system, now every type has separate class, should be easier to add new file types and add functionality in future
- Compiling now should be a little bit faster because of new searching files
- [Book::Target] now has link to book
- [FileTypes::XHTMLFile] now has link to TocItem
- [FileResolver] added tests
- [XHTMLProcessor] new module for dealing with XHTML

## v0.2.4.beta.4

- [Gemfile.lock] Update rb-fsevent to 0.9.6
- Nicer output when detected some unknown landmark
- Add full support for book custom identifier for EPUB 2
- Small improvements in init command
- Rewritten code for searching for files so it should be faster, more relible and more important it should display more helpfull information when it can't find some file
