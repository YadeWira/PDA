# PDA

**packDocument Algorithm**: lossless recompression of **documents** (PDF,
Office, OpenDocument, EPUB, CHM, ...), in FreePascal with C; no libraries.
A new project of the [pack-algorithm family](https://github.com/YadeWira/PJA).

> **Status: early development, nothing to download yet.** The base layer
> works: the `pda` command, the `.pda` container and the checks around them.
> It does not compress anything yet: every file is stored as it is, until
> the document parsers and codecs arrive. The scope and the plan are in
> [doc/SCOPE.txt](doc/SCOPE.txt). This is a long-term project.

    pda a report.pdf       # -> report.pdf.pda
    pda x report.pdf.pda   # -> report.pdf, the same file byte for byte

Nothing is written under an output's name unless it verified: `a`
decompresses its own result and compares it with the input first, and `x`
checks the size and the BLAKE3-128 the `.pda` carries. The command is
described in [doc/CLI.md](doc/CLI.md), the file in
[doc/FORMAT.md](doc/FORMAT.md) (format 1, not frozen).

A document is a tree of streams that are already compressed or encoded:
a DOCX is a ZIP of XML and images, a PDF holds Flate streams, fonts and
JPEGs. PDA:

1. **opens the container** (ZIP, PDF, OLE2, MIME, ...) and undoes every
   compression that compresses little (deflate, LZW, LZ4, bzip2, low-level
   zstd, ...) so that it can be redone byte for byte;
2. **sends each stream to the sibling that handles it best**: JPEG and
   JPEG 2000 to PJA, PNG to PPA, raster to PRA, MPEG audio to PMPA, GIF and
   WebP to PAIA, Ogg to POA, text to [tovyCT](https://github.com/YadeWira/tovyCT);
3. **rebuilds the original identically**, and verifies it before writing.

The first versions use only what already exists: the siblings, tovyCT and
basic precompression (store and deflate).

| Sibling | Formats | Successor of |
|---|---|---|
| [PJA](https://github.com/YadeWira/PJA) | JPEG, JPEG-LS and JPEG 2000 | [packJPG](https://github.com/YadeWira/packJPG) |
| [PMPA](https://github.com/YadeWira/PMPA) | MPEG audio (MP1, MP2, MP3) | [packMP3](https://github.com/YadeWira/packMP3), [packMP2](https://github.com/YadeWira/packMP2) |
| [PRA](https://github.com/YadeWira/PRA) | raster images (PNM, BMP, TIFF, PSD, HDR, ...) | [packPNM](https://github.com/packjpg/packPNM) |
| [PPA](https://github.com/YadeWira/PPA) | the PNG family (PNG, APNG, MNG, JNG) | [packPNG](https://github.com/YadeWira/packPNG) |
| [PAIA](https://github.com/YadeWira/PAIA) | animated images (GIF, WebP, FLI/FLC, ANI, ...) | (new) |
| [POA](https://github.com/YadeWira/POA) | Ogg (Vorbis, Opus, FLAC, Speex, Theora) | (new) |
| **PDA** | documents (PDF, Office, OpenDocument, EPUB, CHM, ...) | (new) |

## Building

FreePascal 3.2.2, no libraries:

    ./build.sh               # build/pda and build/tests/*
    sh .github/test.sh       # what CI runs: unit tests, the command's checks,
                             # selftest and the round trip of tests/doc

## License

MIT (see [LICENSE](LICENSE)); family code and credits in [NOTICE](NOTICE).
