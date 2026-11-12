#!/usr/bin/env python3
"""Writes the small test documents in tests/doc, made here from nothing so
that they carry no third-party content. Deterministic: the same bytes on
every run (fixed ZIP times, fixed zlib level).

    scripts/mksamples.py
"""
import os, zipfile, zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tests', 'doc')


def pdf():
    """A one-page PDF with a FlateDecode content stream and a valid xref."""
    content = b'BT /F1 24 Tf 72 712 Td (PDA test document) Tj ET\n' * 4
    flate = zlib.compress(content, 6)
    objs = [
        b'<< /Type /Catalog /Pages 2 0 R >>',
        b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R'
        b' /Resources << /Font << /F1 5 0 R >> >> >>',
        b'<< /Length %d /Filter /FlateDecode >>\nstream\n' % len(flate) + flate + b'\nendstream',
        b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ]
    out = bytearray(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')
    offs = []
    for i, o in enumerate(objs, 1):
        offs.append(len(out))
        out += b'%d 0 obj\n' % i + o + b'\nendobj\n'
    xref = len(out)
    out += b'xref\n0 %d\n0000000000 65535 f \n' % (len(objs) + 1)
    for o in offs:
        out += b'%010d 00000 n \n' % o
    out += b'trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' % (len(objs) + 1, xref)
    return bytes(out)


def docx():
    """A minimal WordprocessingML package (deflated XML parts)."""
    parts = [
        ('[Content_Types].xml',
         '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
         '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
         '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
         '<Default Extension="xml" ContentType="application/xml"/>'
         '<Override PartName="/word/document.xml" ContentType="application/'
         'vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'),
        ('_rels/.rels',
         '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
         '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
         '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/'
         'relationships/officeDocument" Target="word/document.xml"/></Relationships>'),
        ('word/document.xml',
         '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
         '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'
         + ''.join('<w:p><w:r><w:t>PDA test paragraph %d.</w:t></w:r></w:p>' % i for i in range(20))
         + '</w:body></w:document>'),
    ]
    path = os.path.join(OUT, 'minimal.docx')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, text in parts:
            zi = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(zi, text.encode('utf-8'), compresslevel=6)


def rtf():
    body = ''.join(r'\par PDA test line %d.' % i for i in range(10))
    return (r'{\rtf1\ansi\deff0{\fonttbl{\f0 Helvetica;}}\f0\fs24 ' + body + '}\n').encode('ascii')


def main():
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, 'minimal.pdf'), 'wb') as f:
        f.write(pdf())
    docx()
    with open(os.path.join(OUT, 'minimal.rtf'), 'wb') as f:
        f.write(rtf())
    for n in sorted(os.listdir(OUT)):
        print(n, os.path.getsize(os.path.join(OUT, n)))


if __name__ == '__main__':
    main()
