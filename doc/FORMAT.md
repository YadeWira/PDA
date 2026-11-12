# The `.pda` file

**Format 1, not frozen.** Until a 0.9.x freezes it (see PJA's
`doc/STABILITY.md` for how the family does it), the format may change;
a format this version does not read is refused with its number, never
guessed at.

```
offset  size  field
     0     4  magic: 'P' 'D' 'A' 0x1A
     4     1  format: 1
     5     1  flags: bit 0 = stored (the payload is the original as it is);
              the other bits are 0
     6     8  original size, little endian
    14    16  BLAKE3-128 of the original (the first 16 bytes of BLAKE3)
    30     -  payload
```

Today every file is **stored** (flag bit 0 set): this is the base layer,
before any document parser or codec. A coded payload (bit 0 clear) is
reserved for the stream tree that comes next (containers opened, weak
compression undone, each stream sent to its codec) and is refused by this
version.

A reader checks, in this order: the magic; the format; the flags; that the
payload is not longer than the declared size; and, after decoding, the
size and the BLAKE3-128. `pda x` writes nothing that fails any of them.
