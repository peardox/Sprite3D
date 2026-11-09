# Pointing the OpenH264 downloads at Cisco

Written 9 November 2026, from the code review (`code-review.md`, items 8
and 9) and `src/lib/Sprite3DLibraryUpdate.pas` at `0d0103f`.

## How the download works now

1. At start-up, once the first model is shown, the program fetches the
   list from `https://sprite3d.com/openh264/openh264.json`
   (`Sprite3DLibraryUpdate.pas`, lines 5 and 53).
2. The list has an entry per platform key; each entry's `url` names the
   library to fetch (line 364). The entry whose `url` differs from the
   one recorded in `installed.json` in the settings folder (line 816) is
   downloaded.
3. The download is saved as a `.part` file, bzip2-decompressed if it is
   compressed, checked for a native-library magic number (`MZ`, ELF or
   Mach-O; line 721), then moved over `Target`, which is
   `FileNameFromUrl(Choice.Url)` in the libraries folder (lines 677,
   727 to 729). `installed.json` then records the new `url` (line 732).
4. `RecheckH264` loads the new library on the next check.

So the client needs no change to point at Cisco: alter the `url` values
in `openh264.json` and it fetches from there. Two things stand in the
way of that going smoothly.

## 1. The file names must differ from the installed ones

`Target` is the file name taken from the URL. On Windows the library
already installed is loaded by `OpenH264Available` at start-up, so
`TFile.Delete(Target)` on a file of the same name fails with a sharing
violation, the `except` at line 741 reports "could not be saved",
`installed.json` keeps the old `url`, and the next start downloads the
64 MB again and fails the same way, every start.

Cisco's archives are versioned (`openh264-2.6.0-win64.dll.bz2` and so
on), so:

- Moving to a **newer version** at the same time: the names differ, the
  move succeeds, no problem.
- Pointing at the **same version** the users already have: same name,
  the loop above.

Either way, the client should not depend on the name changing. Review
item 8's fix: save the new copy under a name that includes the version
or a hash of the URL (and record that name in `installed.json`), or
defer the replace until the library is not loaded. That change should
go in before the list is changed, or at least before it points at a
same-named file.

## 2. Use https, and consider a hash

Cisco's downloads are usually linked as
`http://ciscobinary.openh264.org/...`. The client accepts `http` as well
as `https` (line 306) and follows redirects, so an `http` URL works, but
nothing then protects the transfer, and the only check before the
library is loaded into the process is the magic number. Review item 9.

- Put the **`https://`** form of Cisco's URLs in the list; the same
  files are served over it.
- If the list gains a `sha256` field per entry, the client can check
  the decompressed library against it before the move and refuse a
  mismatch. That is a small change to `Sprite3DLibraryUpdate.pas` (read
  the field at line 364, hash the `.part` file before line 727 with
  `System.Hash`); the hashes come from Cisco's published checksums or
  from hashing the files once downloaded.

## 3. Licence text

`docs/licences-required.md` and the README's Licences section say the
OpenH264 copies are served from sprite3d.com. Cisco's patent cover
applies to binaries downloaded from Cisco, which is the reason for the
change; once the list points there, update both to say the libraries
are downloaded from Cisco's own servers (`CLAUDE.md`, Things to check).

## Order of work

1. Client: the same-name replace (item 8), and optionally the `sha256`
   check (item 9). Deliver and test with the current list.
2. List: change the `url` values to Cisco's `https://` URLs (and add
   `sha256` values if the client checks them).
3. Docs: `docs/licences-required.md`, the README's Licences, and strike
   the item from `CLAUDE.md`.
