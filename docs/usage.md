# Usage

## File paths

All paths to files are relative or absolute from project root. You don't have to specify file extensions, Epuber will
resolve them during build.

Epuber process only (X)HTML/Bade and CSS/Stylus files, other files like JavaScript files are untouched.

Epuber support following situations:

#### Images

```html
<img src="some_image" />
->
<img src="../images/some_image.png" />
```

#### Scripts

```html
<script src="js/some_script" />
->
<script src="../js/some_script.js" />
```

#### Styles

```html
<link rel="stylesheet" href="some_css" />
->
<link rel="stylesheet" href="../styles/some_css.css" />
```

#### Links

```html
<a href="other_file#abc">link</a>
->
<a href="other_file.xhtml#abc">link</a>
```

#### Images in CSS

```css
div {
    background: url('image');
}
->
div {
    background: url('../images/image.png');
}
```

#### Fonts in CSS

```css
@font-face {
    font-family: 'MyFont';
    src: url('my-font-regular');
}
->
@font-face {
    font-family: 'MyFont';
    src: url('../fonts/my-font-regular.otf');
}
```


## Global IDs

Epuber supports global IDs across all text files. You can create link from one file to another by using only ID and
you don't have to specify filename. Global IDs has to be unique across all files.

Example how to do it:

File chapter_01.xhtml
```xhtml
<p>Lorem ipsum <a href="$element_id">link</a></p>
```

File chapter_02.xhtml
```xhtml
<p id="$element_id">Lorem ipsum 2</p>
```

In result the link will looks like this: `<a href="chapter_02.xhtml#element_id">link</a>`.
