# PDA

**packDocument Algorithm**: lossless recompression of **documents** (PDF,
Office, OpenDocument, EPUB, CHM, ...), in FreePascal with C; no libraries.
A new project of the [pack-algorithm family](https://github.com/YadeWira/PJA).

> **Status: concept.** There is no code yet. The scope and the plan are in
> [doc/SCOPE.txt](doc/SCOPE.txt). This is a long-term project.

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

## License

MIT (see [LICENSE](LICENSE)).
