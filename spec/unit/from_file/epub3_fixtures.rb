# frozen_string_literal: true

EPUB3_OPF = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <package xmlns="http://www.idpf.org/2007/opf" version="3.0" xml:lang="en" unique-identifier="pub-id">

    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title id="title">Abroad</dc:title>
      <meta refines="#title" property="title-type">main</meta>

      <dc:creator id="creator">Thomas Crane</dc:creator>
      <meta refines="#creator" property="file-as">Crane, Thomas</meta>
      <meta refines="#creator" property="role" scheme="marc:relators">aut</meta>

      <dc:creator id="illustrator">Ellen Elizabeth Houghton</dc:creator>
      <meta refines="#illustrator" property="file-as">Houghton, Ellen Elizabeth</meta>
      <meta refines="#illustrator" property="role" scheme="marc:relators">ill</meta>

      <dc:identifier id="pub-id">urn:uuid:12C1DF3E-DF35-4FCF-918B-643FF15A7870</dc:identifier>
      <meta refines="#pub-id" property="identifier-type" scheme="xsd:string">15</meta>

      <dc:language>en</dc:language>

      <meta property="dcterms:modified">2012-04-09T12:00:00Z</meta>

      <dc:contributor id="contrib1">Liza Daly</dc:contributor>
      <meta refines="#contrib1" property="role" scheme="marc:relators">mrk</meta>

      <dc:date>1882-01-01</dc:date>

      <dc:publisher>London ; Belfast ; New York : Marcus Ward &amp; Co.</dc:publisher>
      <dc:contributor>University of California Libraries</dc:contributor>

      <dc:subject>France -- Description and travel Juvenile literature</dc:subject>

      <dc:rights>This work (Abroad EPUB 3), identified by Liza Daly, is free of known copyright restrictions.</dc:rights>
    </metadata>

    <manifest>
      <item href="childrens-book-style.css" id="css1" media-type="text/css"/>
      <item href="small-screen.css" id="css2" media-type="text/css"/>
      <item href="childrens-book-flowers.jpg" id="image1" properties="cover-image" media-type="image/jpeg"/>
      <item href="childrens-book-swans.jpg" id="image2" media-type="image/jpeg"/>
      <item href="childrens-book-page1.xhtml" id="page1" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2.xhtml" id="page2" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub1.xhtml" id="page2_sub1" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub2.xhtml" id="page2_sub2" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub3.xhtml" id="page2_sub3" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page3.xhtml" id="page3" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page4.xhtml" id="page4" media-type="application/xhtml+xml"/>
      <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>
      <item id="toc" properties="nav" href="toc.xhtml" media-type="application/xhtml+xml"/>
    </manifest>

    <spine toc="ncx">
      <itemref idref="page1" />
      <itemref idref="page2" />
      <itemref idref="page2_sub1" />
      <itemref idref="page2_sub2" />
      <itemref idref="page2_sub3" />
      <itemref idref="page3" />
      <itemref idref="page4" />
    </spine>

  </package>
XML

EPUB3_NAV = <<~XML
  <?xml version="1.0"?>
  <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
      <title>Abroad</title>
    </head>
    <body>
      <nav id="toc" epub:type="toc">
        <h1>Table of Contents</h1>
        <ol>
          <li><a href="childrens-book-page1.xhtml">Page 1</a>
            <ol>
              <li><a href="childrens-book-page1.xhtml#page_1_1">Page 1.1</a></li>
              <li><a href="childrens-book-page1.xhtml#page_1_2">Page 1.2</a></li>
              <li><a href="childrens-book-page1.xhtml#page_1_3">Page 1.3</a></li>
            </ol>
          </li>
          <li><a href="childrens-book-page2.xhtml">Page 2</a>
            <ol>
              <li><a href="childrens-book-page2_sub1.xhtml">Page 2.1</a></li>
              <li><a href="childrens-book-page2_sub2.xhtml">Page 2.2</a></li>
              <li><a href="childrens-book-page2_sub3.xhtml">Page 2.3</a></li>
            </ol>
          </li>
          <li><a href="childrens-book-page3.xhtml">Page 3</a></li>
          <li><a href="childrens-book-page4.xhtml">Page 4</a></li>
        </ol>
      </nav>
      <nav epub:type="landmarks">
        <ol>
          <li>
            <a epub:type="bodymatter" href="childrens-book-page1.xhtml">Start Reading</a>
          </li>
          <li>
            <a epub:type="ibooks:reader-start-page" href="childrens-book-page1.xhtml">Start Reading</a>
          </li>
          <li>
            <a epub:type="cover" href="childrens-book-page1.xhtml">Cover page</a>
          </li>
          <li>
            <a epub:type="copyright-page" href="childrens-book-page2.xhtml">Copyright page</a>
          </li>
        </ol>
      </nav>
    </body>
  </html>
XML

EPUB3_ANCHORES_NAV = <<~XML
  <?xml version="1.0"?>
  <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
      <title>Abroad</title>
    </head>
    <body>
      <nav id="toc" epub:type="toc">
        <h1>Table of Contents</h1>
        <ol>
          <li><a href="childrens-book-page1.xhtml#s_123">Page 1</a></li>
          <li><a href="childrens-book-page2.xhtml#s_345">Page 2</a></li>
          <li><a href="childrens-book-page3.xhtml#s_678">Page 3</a></li>
          <li><a href="childrens-book-page4.xhtml#s_901">Page 4</a></li>
        </ol>
      </nav>
      <nav epub:type="landmarks">
        <ol>
          <li>
            <a epub:type="bodymatter" href="childrens-book-page1.xhtml">Start Reading</a>
          </li>
          <li>
            <a epub:type="ibooks:reader-start-page" href="childrens-book-page1.xhtml">Start Reading</a>
          </li>
          <li>
            <a epub:type="cover" href="childrens-book-page1.xhtml">Cover page</a>
          </li>
          <li>
            <a epub:type="copyright-page" href="childrens-book-page2.xhtml">Copyright page</a>
          </li>
        </ol>
      </nav>
    </body>
  </html>
XML
