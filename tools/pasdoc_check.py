"""Heuristic PasDoc and source checker for Sprite3D.

Usage, from the repository root:

    python3 tools/pasdoc_check.py            check every unit under src
    python3 tools/pasdoc_check.py FILE ...   check only these files

Sprite3D's documentation is built with `pasdoc --staronly`, so only `//**`
comments reach PasDoc; a plain `//` comment is for people reading the
source. This script reads every .pas file in src/lib, src/common and src/ui,
and src/Sprite3d.dpr (src/ffmpeg is third-party and left alone), and
reports:

  - a file that is not ASCII (a UTF-8 byte order mark alone is allowed);
  - a unit or program with no `//**` comment holding @abstract before it;
  - an interface declaration with no comment immediately before it
    ("undocumented"), or with only a plain `//` comment ("plain comment",
    which PasDoc does not see);
  - unbalanced brackets in a @tag(...) of a `//**` comment (PasDoc's
    escaped brackets, `@(` and `@)`, are allowed for);
  - a @link(...) whose target is not declared anywhere in the project;
  - a class field declared after a method or property in the same
    section, which Delphi rejects (E2169).

Fields declared one after another may share one comment: a field directly
under another field counts as documented by the comment above the first.
Attributes such as [NeonProperty('...')] and compiler directives between a
comment and its item are skipped.

Pass --summary to print only the count of each kind of problem per file.
The script does not parse Pascal fully, so it can miss things PasDoc would
warn about, but it needs nothing but Python 3. It prints "No problems
found" when it finds nothing, and exits with 1 when it finds anything.
"""
import pathlib
import re
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'src'

DECL_KW = re.compile(r'^(class\s+)?(procedure|function|constructor|destructor|property|operator)\b', re.I)
TYPE_DECL = re.compile(r'^([A-Za-z_]\w*)(<[^>]*>)?\s*=\s*\S', re.I)
FIELD = re.compile(r'^(class\s+var\s+)?([A-Za-z_]\w*(\s*,\s*[A-Za-z_]\w*)*)\s*:\s*[^=]', re.I)
SECTION = re.compile(r'^(type|const|var|resourcestring|threadvar|private|protected|public|published|'
                     r'strict\s+private|strict\s+protected)\s*$', re.I)
CLASS_START = re.compile(r'^[A-Za-z_]\w*(<[^>]*>)?\s*=\s*(packed\s+)?(class|record|interface)\b', re.I)

# Names PasDoc links to that are declared outside the project
KNOWN_EXTERNAL = set()


def strip_strings(line):
    """Blanks out string literals so brackets and keywords in them are ignored."""
    return re.sub(r"'[^']*'", "''", line)


def files_to_check(args):
    if args:
        return [pathlib.Path(a).resolve() for a in args]
    result = []
    for folder in ('lib', 'common', 'ui'):
        result += sorted((SRC / folder).glob('*.pas'))
    result += sorted(SRC.glob('*.dpr'))
    return result


def project_files():
    result = []
    for folder in ('lib', 'common', 'ui'):
        result += sorted((SRC / folder).glob('*.pas'))
    return result + sorted(SRC.glob('*.dpr'))


def declared_names(texts):
    names = set()
    for f, text in texts.items():
        names.add(f.stem.lower())
        for m in re.finditer(r'\b([A-Za-z_]\w*)\s*(?:<[^>]*>)?\s*=', text):
            names.add(m.group(1).lower())
        for m in re.finditer(r'\b(?:procedure|function|constructor|destructor|property)\s+'
                             r'(?:[A-Za-z_]\w*\.)?([A-Za-z_]\w*)', text, re.I):
            names.add(m.group(1).lower())
        for m in re.finditer(r'^\s*([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*:', text, re.M):
            for n in m.group(1).split(','):
                names.add(n.strip().lower())
        for m in re.finditer(r'\(\s*([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)+)\s*\)', text):
            for n in m.group(1).split(','):
                names.add(n.strip().lower())
    return names


def check_tags(name, lineno, body, declared, problems):
    """Checks one //** comment block's @tag(...) brackets and @link targets."""
    # PasDoc's escaped brackets are not brackets
    plain = body.replace('@(', '').replace('@)', '')
    for tm in re.finditer(r'@(\w+)\(', plain):
        depth, i = 1, tm.end()
        while i < len(plain) and depth:
            if plain[i] == '(':
                depth += 1
            elif plain[i] == ')':
                depth -= 1
            i += 1
        if depth:
            problems.append((name, lineno, 'tag', f'unbalanced @{tm.group(1)}('))
    for lm in re.finditer(r'@link\(([^)\s]+)', plain):
        target = lm.group(1).split('.')[-1].lower()
        if target not in declared and target not in KNOWN_EXTERNAL:
            problems.append((name, lineno, 'link', f'@link({lm.group(1)}) not found'))


def check_file(f, text, declared, problems):
    name = str(f.relative_to(ROOT)) if f.is_relative_to(ROOT) else f.name
    raw = text.encode('utf-8')
    if raw.startswith(b'\xef\xbb\xbf'):
        raw = raw[3:]
        text = text[1:]
    for n, line in enumerate(raw.split(b'\n'), 1):
        if any(b > 127 for b in line):
            problems.append((name, n, 'ascii', 'not ASCII'))
    lines = text.split('\n')

    # //** blocks: tags and links
    i = 0
    while i < len(lines):
        if lines[i].lstrip().startswith('//**'):
            start = i
            body = []
            while i < len(lines) and lines[i].lstrip().startswith('//**'):
                body.append(lines[i].lstrip()[4:])
                i += 1
            check_tags(name, start + 1, '\n'.join(body), declared, problems)
        else:
            i += 1

    # The unit or program comment
    head = next((k for k, l in enumerate(lines) if re.match(r'^(unit|program)\s+\w+', l)), None)
    if head is not None:
        before = []
        k = head - 1
        while k >= 0 and lines[k].lstrip().startswith('//**'):
            before.append(lines[k])
            k -= 1
        if not any('@abstract' in b for b in before):
            problems.append((name, head + 1, 'unit', 'unit or program has no //** @abstract comment'))
    if f.suffix.lower() == '.dpr':
        return

    try:
        start = next(k for k, l in enumerate(lines) if re.match(r'^\s*interface\s*$', l, re.I))
        end = next(k for k, l in enumerate(lines) if re.match(r'^\s*implementation\s*$', l, re.I))
    except StopIteration:
        return

    in_brace = False
    in_uses = False
    paren_depth = 0
    class_depth = 0
    seen_member = False
    prev_was_field = False
    for k in range(start + 1, end):
        s = strip_strings(lines[k]).strip()
        if in_brace:
            if '}' in s:
                in_brace = False
            continue
        if s.startswith('{') and not s.startswith('{$'):
            if '}' not in s:
                in_brace = True
            continue
        if not s or s.startswith('{$') or re.match(r'^\[.*\]$', s):
            continue
        if s.startswith('//'):
            prev_was_field = False
            continue
        if re.match(r'^uses\b', s, re.I):
            in_uses = not s.endswith(';')
            continue
        if in_uses:
            if s.endswith(';'):
                in_uses = False
            continue
        if paren_depth > 0:
            paren_depth = max(0, paren_depth + s.count('(') - s.count(')'))
            continue
        if SECTION.match(s):
            seen_member = False
            prev_was_field = False
            continue
        if re.match(r'^end\b', s, re.I):
            class_depth = max(0, class_depth - 1)
            seen_member = False
            prev_was_field = False
            continue
        is_method = bool(DECL_KW.match(s))
        is_field = bool(FIELD.match(s)) and not is_method
        is_type = bool(TYPE_DECL.match(s)) and not is_method
        opens_class = bool(CLASS_START.match(s)) and not re.search(
            r'=\s*class\s+of\b|=\s*(class|interface)\s*(\([^)]*\))?\s*;\s*$', s, re.I)
        if not (is_method or is_field or is_type):
            prev_was_field = False
            continue
        if class_depth > 0:
            if is_method:
                seen_member = True
            elif is_field and seen_member:
                problems.append((name, k + 1, 'e2169',
                                 f'field after a method or property (E2169): {s[:60]}'))
        # The comment immediately before, skipping directives and attributes
        j = k - 1
        while j > start and (not lines[j].strip() or lines[j].strip().startswith('{$')
                             or re.match(r'^\[.*\]$', lines[j].strip())):
            j -= 1
        prev = lines[j].strip()
        if prev.startswith('//**') or prev.endswith('}') and not prev.startswith('{$'):
            pass
        elif is_field and prev_was_field:
            pass
        elif prev.startswith('//'):
            problems.append((name, k + 1, 'plain', f'plain // comment, not //**: {s[:60]}'))
        else:
            problems.append((name, k + 1, 'undoc', f'undocumented: {s[:70]}'))
        prev_was_field = is_field
        if opens_class:
            class_depth += 1
            seen_member = False
        paren_depth = max(0, s.count('(') - s.count(')'))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    summary = '--summary' in sys.argv
    texts = {f: f.read_text(encoding='utf-8', errors='replace') for f in project_files()}
    declared = declared_names(texts)
    problems = []
    for f in files_to_check(args):
        text = texts.get(f) or f.read_text(encoding='utf-8', errors='replace')
        check_file(f, text, declared, problems)
    if not problems:
        print('No problems found')
        return 0
    if summary:
        counts = Counter((p[0], p[2]) for p in problems)
        for fname in sorted({p[0] for p in problems}):
            parts = ', '.join(f'{kind} {counts[(fname, kind)]}'
                              for kind in ('ascii', 'unit', 'undoc', 'plain', 'tag', 'link', 'e2169')
                              if counts[(fname, kind)])
            print(f'{fname}: {parts}')
    else:
        for fname, lineno, _, message in problems:
            print(f'{fname}:{lineno}: {message}')
    return 1


if __name__ == '__main__':
    sys.exit(main())
