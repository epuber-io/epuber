
# CHANGELOG

## v0.3.2

- [Command::Init] create sublime project
- [XHTMLProcessor] add `<meta charset="utf-8"/>` to default head (only for epub3.0+) 
- [OPFGenerator] fix duplicated items in spine
- [UserInterface] rewrite some logs and make big improvements, overwriting processing lines, so result output is much shorter
- [TocItem] now supports defined sub items only with fragment part


## v0.3.1

- [FileResolver] #file_with_source_path now can find file with absolute source path
- [Server] fix several crashes because of not existing constants, etc
- [Server] fix calculation of relative path to destination path (causing to break style auto refreshes)
- [XHTMLProcessor] fix resolving images with unicode path
- [FileTypes::ImageFile] create folder if doesn't exists (causing to crash the compilation)
- [Compiler] now prints current file, helps with debugging and general using
- [Server] fix urls on page /files
- [Checker & Transformer] add third parameter CompilationContext
- [Checker] add new checker type :source_text_file
- [Server] fix crashes after compilation error/crash
- [FileFinder] add support for paths containing fragment part
- [FileResolver] made some optimizations about adding files
- [FileResolver] #file_from_request now support searching from added files without matching exact file request instance
- [NavGenerator] fix generating paths with fragment part
- [Compiler] add support for nested toc items
- [Plugins] :source_text_file now receives source file instead of destination path
- [Gemfile.lock] update thin to 1.6.4


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
