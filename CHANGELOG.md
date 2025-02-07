# CHANGELOG

## v0.12.0 (2025-02-07)

- Add basic support for SVG files (Epuber will correctly find them even when extension is missing) [#66](https://github.com/epuber-io/epuber/issues/66)


## v0.11.1 (2025-01-24)

- do not use epubcheck v5.2.0 (bacause of issue [w3c/epubcheck #1595](https://github.com/w3c/epubcheck/issues/1595))


## v0.11.0 (2025-01-23)

- NCX file is now generated always (even for EPUB 3)
- add missing playOrder attribute in generated NCX file (which is required)


## v0.10.3 (2024-09-03)

- fixed resolving urls in CSS when there are multiple `url()` functions in one declaration


## v0.10.2 (2024-06-13)

- fixed parsing multiple problems from Epubcheck with same ID [#115](https://github.com/epuber-io/epuber/issues/115)
- fixed crash when running server


## v0.10.1 (2024-06-06)

- fixed parsing result from Epubcheck when there was some error


## v0.10.0 (2024-05-26)

- redo logging messages, error and progress [#85](https://github.com/epuber-io/epuber/issues/85)
- format Epubcheck validation issues with line preview (shows location to build folder, actual error message) [#111](https://github.com/epuber-io/epuber/issues/111)
- allow to run from any nested folder [#79](https://github.com/epuber-io/epuber/issues/79)
- enhance BookTransformer to include more options how to find files (`:context_path` + `:groups`)


## v0.9.4 (2024-05-13)

- fixed missing `properties="cover-image"` in EPUB v3 [#96](https://github.com/epuber-io/epuber/issues/96)
- fixed missing font files when doing incremental builds or running server


## v0.9.3 (2024-05-06)

- fixed crash when resolving files in CSS or Bade and the target file was not found


## v0.9.2 (2024-02-14)

- fixed warning about not founding file when using `<a href="#">` link in (x)html file


## v0.9.1 (2023-12-19)

- fixed adding to final EPUB files that were found in cache but were deleted afterwards


## v0.9.0 (2023-12-19)

- add way to specify contributor's role by adding `:role` key in hash syntax (see [bookspec.md](docs/bookspec.md#role))
- add some docs about bookspec (see [bookspec.md](docs/bookspec.md))
- add command `from-file` to create new Epuber project from existing EPUB file [#95](https://github.com/epuber-io/epuber/pull/95)
- resolves linked files in CSS and Stylus files [#97](https://github.com/epuber-io/epuber/issues/97)


## v0.8.0 (2023-11-19)

- fixed not failing build when running `build --check` or `build --release` and Epubcheck fails with errors #82
- add Global ID feature (more in [docs](docs/usage.md#global-ids)) #57
- add validation of `.bookspec` file in plugins #20


## v0.7.4

- fixed using precompiled version of Bade and correct import and require paths


## v0.7.3

- fixed usage of deprecated API that was removed in Ruby 3.2 #87


## v0.7.2

- fixed caching of generated files #86

## v0.7.1

- fixed not working Epuber's script in server pages (wrong Content-Type header for XHTML files)

## v0.7.0
- remove Ruby constants created in Bade templates
- add support for Ruby 3.0 + drop 2.5
- update Bower components for book development webpage
- update all RubyGems dependencies

## v0.6.0
- update all dependencies
- update RMagick to latest version (issue #69)
- drop support for Ruby 2.4 and older
- fix crash when resolving path to local file - missing URI::encode (issue #71)

## v0.5.7
- do not generate empty `<ol>` in `nav.xhtml` file

## v0.5.6
- add namespaces into XHTML files when there is not any namespace
- better handling of empty `<html>`

## v0.5.5
- fix mimetype for OTF and TTF fonts
- fix parsing of version on `.bookspec` file

## v0.5.4
- XHTML + Bade - improve adding default styles when there is the default style already present
- OPF - fix IDs when root folder starts with number

## v0.5.3
- less pessimistic version specifies for nokogiri and stylus

## v0.5.2
- better handling of non-existing lockfile

## v0.5.1
- XHTML + Bade - improve adding default DOCTYPE for EPUB 2

## v0.5.0
- add support for abstract targets
- drop support for Ruby 2.2

## v0.3.6
- add support for older versions of Ruby (2.1.X and 2.0.X) which doesn't support string unicode normalization


## v0.3.5

- [Server] fix AutoRefresh for style changes
- [Server] add AutoRefresh for home pages (`/`, `/toc`, `/files`)
- [Server] add `--open` CLI flag to open automatically web browser after server starts


## v0.3.4

- upgrade Bade to 0.1.3


## v0.3.3

- [FileTypes] add new classes for generated files (`META-INF/*`, `nav.xhtml`, `content.opf`, ...)
- [TextChecker] fix formatting when indent contains tab characters
- [TextChecker] fix crasheshes for cases when problem is at beginning or end of line
- [Server] fix several crashes when compilation fails
- [Server] move `/toc/*` requests to `/book/*` so it supports loading images from css
- [OPFGenerator] add `opf:file-as` to author element for EPUB 2


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
