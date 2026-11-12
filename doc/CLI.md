# The `pda` command

```
pda a [options] FILE...     compress:  report.pdf -> report.pdf.pda
pda x [options] FILE...     extract:   report.pdf.pda -> report.pdf
pda list FILE...            what each .pda holds: original size, stored size, hash
pda t FILE...               test each .pda: extract and verify in memory, write nothing
pda info FILE...            the structure of each file, and what PDA does with it
pda report [FILE]           a bug report (no document contents) and a link to open an issue
pda bench FILE...           how fast this machine runs a, a --no-verify and x on them
pda selftest                the samples inside the binary
pda --version, pda -V       the build and the system
```

The command follows the pack-algorithm family's (PJA's `doc/CLI.md` is the
model); this page says what PDA does and where it differs. Today PDA takes
any file and stores it in a `.pda` (stage 1 of the plan, see
[SCOPE.txt](SCOPE.txt)): the command, the container and the checks come
first, the document parsers and codecs after.

**Names.** A `.pda` does not store the original's extension: `a` appends
`.pda` to the whole name (`report.pdf` -> `report.pdf.pda`) and `x` removes it
(`report.pdf.pda` -> `report.pdf`). A name that does not end in `.pda` gets
`.out` when extracted.

| switch | what it does |
|---|---|
| `-o PATH` | output name with one input; a directory if it exists or ends in `/` |
| `--output-dir=DIR` | output directory |
| `-f`, `--force` | replace an existing output, only with something that verified |
| `-th N`, `--threads=N` | files worked on at once, the largest first; by default the processors, up to 8. A file is coded on one thread. Each file's lines come out in the order of the inputs |
| `--max-output=SIZE` | `x`, `t`: refuse a declared original above SIZE (`256M` by default, `K`/`M`/`G`, `0` = no limit), before decoding |
| `--keep-corrupt` | `x`: an output that does not verify stays as `NAME.corrupt` |
| `--no-verify` | `a`: do not decompress the stream to check it before writing (about twice as fast; a codec bug would then only show when extracting, where the hash catches it). The `.pda` is the same byte for byte |
| `--no-sync` | do not wait for each output to reach the disk before it takes its name; after a power cut an output may be empty or missing |
| `--clean-temps` | `a`, `x`: delete the temporaries an interrupted run left in the directories this run writes to: only PDA's (`.pda-tmp-PID-N`), only regular files, only older than an hour, never one whose process is still running |
| `-n`, `--dry-run` | do everything but write |
| `-q`, `--quiet` | only errors |
| `--stats` | `a`, `x`, `t`: where each file's time went (read, encode, verify, decode, hash, write) |
| `--json` | `a`, `x`, `t`, `info`, `list`: one JSON object a line for each file, in the order of the inputs, then `{"summary": ...}` |
| `--cpu=PATH` | accepted for the family's scripts: PDA has one path, `plain`; any other is refused (exit 2) |
| `-o REPORT` | `report`: the file the report goes to (never over an existing one) |
| `--with-file` | `report`: also copy FILE beside the report as `pda-report-NAME`, to attach if you choose to (without FILE: exit 2) |
| `-r N` | `bench`: runs of each measure, the best counts (3 by default) |
| `--` | everything after it is a file |

All warnings and errors go to stderr.

| exit status | when |
|---|---|
| 0 | every file went through (`t`: every `.pda` verified; `selftest`: every check passed) |
| 1 | a file failed: it is not a `.pda` (`x`, `t`, `list`), it is damaged, it could not be read or written; `selftest`: a check failed |
| 2 | usage error: an unknown command or option, a value out of range, an option for another command, `--cpu` with a path not here |
| 3 | a bug in PDA: an exception that is not about the file or the system. The run ends with `This is a bug in PDA. Please run: pda report FILE and open an issue at https://github.com/YadeWira/PDA/issues` |
| 130, 143, 129, 141 | ended by SIGINT, SIGTERM, SIGHUP or SIGPIPE, after deleting the temporaries it was writing |

## Checking and reporting

- **`pda t`**: what `x` does, without writing: the header, the declared
  size against `--max-output`, decoding, then the size and the BLAKE3-128.
  `NAME: OK` for each one that verifies, `pda: NAME: ...` on stderr for
  each that does not (exit 1).
- **`pda info`**: for a document, what `a` does with it (today: stored as
  is, since this version has no container parser yet). For a `.pda`, its
  header (format, flags, original size, BLAKE3-128) and whether it extracts
  and verifies. Document contents are never printed.
- **`pda report`**: PDA's version and build, the system, the command line
  (paths cut to their names), and for FILE its size, BLAKE3-128, structure
  and what `a` does with it. No document contents. Then a link that
  opens a GitHub issue with the report in it. `--with-file` copies the file
  beside the report: it goes nowhere unless you attach it.
- **`pda bench`**: for each file, the best of N runs of `a`, `a --no-verify`
  and `x`, in milliseconds and MB/s of the original, and the write alone.
  Nothing is written beside the inputs.
- **`pda selftest`**: the binary carries three samples (`pas/pdaselftest.inc`,
  written by `tools/gen_selftest.py` from `tests/doc`) and the BLAKE3-128 of
  the `.pda` each one has to give: each is compressed, compared with it and
  extracted back.
- **`pda --version`**: version, commit (from `PDA_COMMIT` at build time;
  `build.sh` takes it from git), build date, FPC, target, system, processor,
  `cpu_path: plain`, processors, default threads, `.pda` format.

## Nothing written that did not verify

- `a` writes the `.pda` only after it has decompressed its own stream and
  compared it with the input (unless `--no-verify`).
- `x` validates the header, refuses a declared size above `--max-output`
  before decoding, decodes with that size as the cap, checks the size and
  the BLAKE3-128, and only then writes.
- Writing goes to a temporary in the same directory (`.pda-tmp-PID-N`),
  flushed to the disk (unless `--no-sync`) and renamed to the output only
  once it is complete; on Unix the directory is flushed after. Without `-f`
  the name is taken only if it is still free. A run cut short never leaves a
  partial file under the output's name; a temporary left by `kill -9` or a
  power cut is named by the next run that writes there, and deleted only
  with `--clean-temps`.
