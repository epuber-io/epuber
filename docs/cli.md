# CLI commands

Epuber does have few CLI commands. You can always use `epuber --help` to print them all with some information about each of them.

## Init

Command to setup current directory for using as Epuber project.

```sh
epuber init book_name
```

Change `book_name` to whatever you like, this will be basename of created bookspec file.


## From file

Command to setup current directory for using as Epuber project by leveraging existing EPUB file and using all information stored there to create Bookspec with all metadata, TOC, ...

```sh
epuber from-file book_name.epub
```

New command introduced in version 0.9.0.


## Server

Command to create development server, starts to listening for changes in files and automatically rebuilds whole book and updates preview in web browser.

```sh
epuber server [TARGET]
```

After start of server you can open your favorite web browser and open http://localhost:4567.

You need to be in directory where bookspec is located.

Argument `[TARGET]` is optional. You can change target on web page.


## Build

Command to build specific or all targets.

```sh
epuber build [TARGET ...]
```

There will be new EPUB files after finish of this command.

You can use following flags to change output or behavior:

- `--check` Performs additional validation on sources + checks result epub with epubcheck.
- `--write` Performs additional transformations which writes to source files.
- `--release` Create release version of the book, no caching, everything creates from scratch + performs epubcheck validation.
- `--no-cache` Turns off incremental build, can resolve some bugs but build takes much longer.
- `--verbose` Show more debugging information
