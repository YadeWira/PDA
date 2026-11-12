#!/usr/bin/env python3
"""Writes doc/SCOPE.txt: the scope and plan as plain-text tables (for the
forum and for readers without a Markdown viewer). Edit the tables here and
run it again:

    tools/mkscope.py
"""
import os
import textwrap
W=[]
def table(title, head, rows, widths):
    W.append(title); W.append('='*len(title)); W.append('')
    def line(ch='-'): return '+'+'+'.join(ch*(w+2) for w in widths)+'+'
    def emit(cells):
        cols=[textwrap.wrap(c,w) or [''] for c,w in zip(cells,widths)]
        for i in range(max(map(len,cols))):
            W.append('| '+' | '.join((c[i] if i<len(c) else '').ljust(w) for c,w in zip(cols,widths))+' |')
    W.append(line()); emit(head); W.append(line('='))
    for r in rows: emit(r); W.append(line())
    W.append('')
def para(t): W.extend(textwrap.wrap(t,100)); W.append('')

W.append('PDA (packDocument Algorithm) - scope and plan, early development (2026-11-12)')
W.append('#'*73); W.append('')
para('PDA is the document member of the family. Its job is exactly the "unpack first" step: it '
     'opens the container (ZIP, PDF, OLE2...), undoes every weak compression in a way that can be '
     'redone byte for byte (deflate, LZW, bzip2...), sends each stream to the sibling that handles it '
     'best, and rebuilds the original identically. Same rules as the siblings: byte-for-byte '
     'restoration, verify before writing, store as-is what cannot be taken.')

table('1. The family and what PDA takes from each (states as of 2026-11-12)',
 ['Project','Covers','State','Used by PDA for'],
 [['PJA','JPEG, JPEG-LS, JPEG 2000','0.9.8 (formats stable since 0.9.0); libpja, 7-Zip and zpaq-std plugins','JPEG and JPEG 2000 images (PDF DCTDecode/JPXDecode); also the code base'],
  ['PPA','PNG, APNG, MNG, JNG','0.1.1; libppa, 7-Zip plugin','PNG images; the family\'s reconstructible deflate (shared with PDA)'],
  ['PRA','raster: PNM, BMP, TIFF, PSD, PICT, ILBM, PCX, TGA, ICO, DDS, DICOM, EXR...','0.1.0','raw PDF images (after inflate), BMP/DIB, TIFF, PICT, PCX, ILBM, ICO'],
  ['PMPA','MPEG audio: MP1, MP2, MP3','0.4.0 (0.5.0 with libpmpa coming)','MP3/MP2 in PPT/PPTX/EPUB/PDF and attachments'],
  ['PAIA','animated images: GIF, WebP, FLI/FLC, ANI, IFF ANIM','0.1.0','GIF and WebP; its reconstructible LZW'],
  ['POA','Ogg: Vorbis, Opus, FLAC, Speex, Theora','early development, no release; libpoa, 7-Zip plugin','Ogg audio in PPTX/ODP/EPUB 3/Keynote and attachments'],
  ['tovyCT','text (BWT + QLFC)','1.1.0 (format v4 frozen)','all extracted text: XML, HTML, PDF content streams, RTF...'],
  ['PDA','document containers + precompression','early development: base layer (command, .pda container, checks); stores every file for now','everything else: containers, deflate & co., fonts, WMF/EMF, recursion']],
 [7,30,22,36])

table('2. Documents (containers)',
 ['Priority','Group','Formats'],
 [['High','PDF and PostScript','.pdf .ps .eps .ai .djvu'],
  ['High','ZIP based','OOXML (.docx .docm .dotx .xlsx .xlsm .xltx .xlsb .pptx .pptm .potx .ppsx .vsdx), ODF (.odt .ods .odp .odg .odf .odb .ott), .epub, iWork (.pages .key .numbers), .xps .oxps, .cbz .cbr .cb7, .hwpx, .ofd'],
  ['Medium','OLE2 / CFB','.doc .dot .xls .xlt .ppt .pot .pps .vsd .pub .msg .mpp .one .hwp'],
  ['Medium','Text with embedded binaries','.rtf .mht .mhtml .eml .fodt .fods'],
  ['Medium','Compiled help and e-books','.chm .mobi .azw .azw3 .fb2 .fbz'],
  ['Low','Nearly extinct','.lit .lrf .hlp .inf (OS/2) .prc .ibooks, StarOffice (.sxw .sxc .sxi .sxd .sdw .sdc), .wps (Works), Word 2003 XML'],
  ['Low','Old binary formats','.wpd .lwp .abw .sla .qxd .indd .pmd, Lotus .wk1 .wk3 .123, .qpw'],
  ['Low','Text with little binary','.html .htm .xhtml .sam .wri'],
  ['Out','Text only (for tovyCT)','.txt .md .rst .adoc .tex .bib .dvi, WordStar, Norton Guides, AmigaGuide']],
 [8,28,60])

table('3. Embedded content',
 ['Priority','Format','Handled by'],
 [['Mandatory','every compression format that compresses little: zip/deflate, LZ4, LZ5, low zstd, low Brotli... (table 4)','PDA (LZW from PAIA)'],
  ['High','JPEG','PJA'],
  ['High','PNG','PPA'],
  ['High','raw PDF images','PRA'],
  ['High','TrueType/OpenType, CFF, ODTTF','PDA (font model)'],
  ['High','XML, HTML, CSS, JS','tovyCT'],
  ['High','JBIG2','no owner yet'],
  ['High','WMF, EMF, EMF+','PDA (the bitmap inside to PRA)'],
  ['High','JPEG 2000 (PDF JPXDecode, JP2/JPX/JPM)','PJA (8.42% saved on 113 real codestreams)'],
  ['Medium','MP1, MP2, MP3','PMPA'],
  ['Medium','Ogg: Vorbis, Opus, FLAC, Speex, Theora','POA'],
  ['Medium','GIF, WebP','PAIA'],
  ['Medium','TIFF','PRA (LZW/deflate inside undone by PDA first; JPEG inside to PJA)'],
  ['Medium','CCITT G3/G4','no owner yet'],
  ['Medium','BMP / DIB','PRA'],
  ['Medium','SVG','tovyCT'],
  ['Medium','Type 1, CID fonts / CMaps, WOFF / WOFF2','PDA'],
  ['Medium','OLE objects, nested documents, attachments','PDA (recursion)'],
  ['Medium','VBA, ICC profiles, XMP','PDA'],
  ['Medium','ASCII85, Hex, Base64, quoted-printable','PDA (decode and recurse)'],
  ['Medium','PalmDoc (LZ77, MOBI/AZW and loose .pdb), HUFF/CDIC','PDA (weak compression: mandatory)'],
  ['Medium','WAV / PCM','generic model'],
  ['Low','PICT, PCX, IFF ILBM, ICO/CUR','PRA'],
  ['Low','MP2 inside .mpg','PMPA (needs demuxing)'],
  ['Low','SWF, EOT, JPEG XR, SHG/MRB, CGM, MIDI, DXF, embedded PDF','case by case']],
 [9,44,44])

table('4. Precompression: every compression format that compresses little is recompressed, no exceptions',
 ['Order','Method','Where it appears','How it is rebuilt identically'],
 [['1','Store (no compression) in ZIP, 7z, RAR, tar, CAB','attachments, embedded objects','parse and go down to the files'],
  ['1','Deflate / zlib / gzip','ZIP, OOXML, ODF, EPUB, PDF, PNG, WOFF, SVGZ, .gz','core engine: try known zlib settings, else recipe + differences (preflate-like, written from scratch)'],
  ['2','CAB MSZIP','.cab, installers','same deflate engine'],
  ['2','LZW','PDF LZWDecode, GIF, TIFF, .Z, ARC, ZIP Shrink','PAIA\'s LZW; parameters in the recipe'],
  ['2','bzip2','.bz2, .tbz, attachments','unique BWT; try libbzip2 levels, else recipe'],
  ['2','LZ4 / LZ4HC, LZ5 / Lizard, LZO, Snappy, LZF, LZJB, QuickLZ','.lz4, .lz5, .lzo, iWork, file systems','the stream already is the literal/match list: model it; try reference implementations, else recipe'],
  ['2','Brotli, low quality (~0-4; cut-off set by measuring)','WOFF2, compressed HTML/EPUB, .br','try the reference implementation per version and quality, else recipe from the stream commands'],
  ['2','zstd, low levels (fast/negative and ~1-3; cut-off set by measuring)','.zst, modern containers, attachments','try libzstd per version and level, else recipe from the sequences the frame carries'],
  ['3','LZX','CHM, LIT, CAB LZX, WIM','recipe + differences'],
  ['3','ZIP Implode / Reduce / Shrink','old ZIPs','PKZIP 1.x behaviour, else recipe'],
  ['3','LHA / LZH (lh0-lh7)','.lzh, .lha','reference implementation, else recipe'],
  ['3','ARJ (methods 1-4)','.arj','reference implementation, else recipe']],
 [5,26,28,36])
para('The rule is about how much a format compresses, not which format it is. Not precompressed '
     '(they already compress well, no margin): LZMA (xz/7z), high zstd levels, high Brotli quality, '
     'anything encrypted. Compressed RAR is out because its encoder is closed and cannot be '
     'reproduced (its stored parts are used).')

table('5. Already compressed with no sibling yet: known lossless recompressors (stored as is for now)',
 ['Format','Known recompressor','Claimed gain','Decision'],
 [['H.264','Dropbox avrecode','~13%','candidate for a future sibling'],
  ['HEVC / HEIC','hevcpress','~10%','candidate for a future sibling'],
  ['AAC','none found (Huffman, like MP3)','no data','candidate, maybe with PMPA'],
  ['WMA','none found','no data','low priority']],
 [12,30,12,32])

table('6. Discarded',
 ['Format','Why'],
 [['AV1 / AVIF','adaptive multi-symbol arithmetic coder, no known recompression'],
  ['JPEG XL','context-modelled ANS'],
  ['VP9 / WebM','no known recompression'],
  ['Encrypted content','noise without the key'],
  ['LZMA (xz/7z), high-level zstd, high Brotli, compressed RAR','compress well (little margin) or cannot be rebuilt identically today']],
 [42,55])

table('7. How files get inside documents (so recursion is mandatory)',
 ['Document','Mechanism'],
 [['MSG / EML','attachments (most common case of a .zip/.rar inside)'],
  ['PDF','/EmbeddedFile, portfolios, PDF/A-3 (ZUGFeRD / Factur-X invoices)'],
  ['DOC, XLS, PPT, RTF','OLE "Package" object (Ole10Native); in RTF inside \\objdata'],
  ['DOCX, XLSX, PPTX','embeddings/ folder'],
  ['ODF','embedded objects'],
  ['OneNote','file attachments'],
  ['Self-extracting .exe','zip/cab/7z signature inside (low priority)']],
 [22,70])

table('8. Stages',
 ['#','Stage','Done when'],
 [['0','Research: modern corpus, what a real document is made of (% JPEG, PNG, XML, fonts...)','composition table per format'],
  ['1','Base: .pda container, CLI, store mode with verification','pda a / pda x work on any file (done, 2026-11-12)'],
  ['2','Reconstructible deflate','100% of the corpus deflate streams rebuilt'],
  ['3','ZIP family (Office, ODF, EPUB, XPS, CBZ) + tovyCT, PJA, PPA','round trip identical, compared with 7z/xz/precomp'],
  ['4','PDF: tolerant parser, filters, object/xref streams, incremental updates','corpus PDFs round trip identical'],
  ['5','Fonts: TTF/OTF, CFF, Type 1, ODTTF, WOFF','measured gain over the generic model'],
  ['6','OLE2: DOC/XLS/PPT, MSG, PUB, VSD; WMF/EMF; VBA','same'],
  ['7','RTF, MHT/EML (MIME), FB2','same'],
  ['8','CHM (LZX), MOBI/AZW','same'],
  ['9','PostScript, iWork, DjVu','same'],
  ['10','Complete precompression: every method of table 4','every method round trips on the corpus'],
  ['11','Low priority formats','as the corpus asks']],
 [3,62,32])

open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'doc', 'SCOPE.txt'), 'w').write('\n'.join(W).rstrip()+'\n')
