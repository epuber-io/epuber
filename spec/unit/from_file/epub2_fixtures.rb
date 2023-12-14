# frozen_string_literal: true

EPUB2_OPF = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <package xmlns="http://www.idpf.org/2007/opf" version="2.0" xml:lang="en" unique-identifier="pub-id">

    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title>Abroad</dc:title>
      <dc:creator opf:file-as="Crane, Thomas" opf:role="aut">Thomas Crane</dc:creator>
      <dc:creator opf:file-as="Houghton, Ellen Elizabeth" opf:role="ill">Ellen Elizabeth Houghton</dc:creator>

      <dc:identifier id="pub-id">urn:uuid:12C1DF3E-DF35-4FCF-918B-643FF15A7870</dc:identifier>
      <dc:language>en</dc:language>

      <dc:date>1882-01-01</dc:date>

      <dc:publisher>
        London ; Belfast ; New York : Marcus Ward &amp; Co.
      </dc:publisher>
      <dc:contributor>University of California Libraries</dc:contributor>

      <dc:subject>France -- Description and travel Juvenile literature</dc:subject>

      <dc:rights>This work (Abroad EPUB 3), identified by Liza Daly, is free of known copyright restrictions.</dc:rights>

      <meta name="cover" content="image1" />
    </metadata>

    <manifest>
      <item href="childrens-book-style.css" id="css1" media-type="text/css"/>
      <item href="small-screen.css" id="css2" media-type="text/css"/>
      <item href="childrens-book-flowers.jpg" id="image1" media-type="image/jpeg"/>
      <item href="childrens-book-swans.jpg" id="image2" media-type="image/jpeg"/>
      <item href="childrens-book-page1.xhtml" id="page1" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2.xhtml" id="page2" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub1.xhtml" id="page2_sub1" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub2.xhtml" id="page2_sub2" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page2_sub3.xhtml" id="page2_sub3" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page3.xhtml" id="page3" media-type="application/xhtml+xml"/>
      <item href="childrens-book-page4.xhtml" id="page4" media-type="application/xhtml+xml"/>
      <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>
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

EPUB2_NCX = <<~HTML
  <?xml version="1.0" encoding="utf-8"?>
  <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
    <head>
      <meta name="dtb:uid" content="urn:uuid:4f74cebf-d97f-4014-b64f-ffc8f8b105ac" />
      <meta name="dtb:depth" content="2" />
      <meta name="dtb:totalPageCount" content="0" />
      <meta name="dtb:maxPageNumber" content="0" />
    </head>
  <docTitle>
    <text>Abroad</text>
  </docTitle>
  <navMap>
    <navPoint id="navPoint1">
      <navLabel>
        <text>Page 1</text>
      </navLabel>
      <content src="childrens-book-page1.xhtml" />
      <navPoint id="navPoint2">
        <navLabel>
          <text>Page 1.1</text>
        </navLabel>
        <content src="childrens-book-page1.xhtml#page_1_1" />
      </navPoint>
      <navPoint id="navPoint3">
        <navLabel>
          <text>Page 1.2</text>
        </navLabel>
        <content src="childrens-book-page1.xhtml#page_1_2" />
      </navPoint>
      <navPoint id="navPoint4">
        <navLabel>
          <text>Page 1.3</text>
        </navLabel>
        <content src="childrens-book-page1.xhtml#page_1_3" />
      </navPoint>
    </navPoint>
    <navPoint id="navPoint5">
      <navLabel>
        <text>Page 2</text>
      </navLabel>
      <content src="childrens-book-page2.xhtml" />
      <navPoint id="navPoint6">
        <navLabel>
          <text>Page 2.1</text>
        </navLabel>
        <content src="childrens-book-page2_sub1.xhtml" />
      </navPoint>
      <navPoint id="navPoint7">
        <navLabel>
          <text>Page 2.2</text>
        </navLabel>
        <content src="childrens-book-page2_sub2.xhtml" />
      </navPoint>
      <navPoint id="navPoint8">
        <navLabel>
          <text>Page 2.3</text>
        </navLabel>
        <content src="childrens-book-page2_sub3.xhtml" />
      </navPoint>
    </navPoint>
    <navPoint id="navPoint9">
      <navLabel>
        <text>Page 3</text>
      </navLabel>
      <content src="childrens-book-page3.xhtml" />
    </navPoint>
    <navPoint id="navPoint10">
      <navLabel>
        <text>Page 4</text>
      </navLabel>
      <content src="childrens-book-page4.xhtml" />
    </navPoint>
  </navMap>
  </ncx>
HTML
