"""Builds the release zip for one bot.

Usage:  python tools/package.py <bot>-v<X.Y> [--out dist]
        e.g. python tools/package.py farmbot-v1.0
        python tools/package.py farmbot   (current version; CI uses this as a dry run)

The zip holds everything a player needs, ready to unpack into one folder: the bot's
.lua and .json, its README and examples, the configurator and the license. The tag must
match the version the bot prints on start, so a release can't ship the wrong script.

Also writes <out>/release.env with the values the release workflow needs:
TITLE, PRERELEASE (true while the bot's README says it's experimental) and NOTES
(path to the CHANGELOG section for this tag, empty if there is none).
"""
import argparse
import os
import re
import shlex
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOTS = {
    'shinybot': ('FRLG_ShinyBot', 'Shiny Bot'),
    'trainbot': ('FRLG_TrainBot', 'Train Bot'),
    'farmbot': ('FRLG_FarmBot', 'Farm Bot'),
}
# Configurator files a player needs (no tests or build tools).
CONFIGURATOR = ['index.html', 'README.md', 'css', 'js', 'skins']


def fail(msg):
    print('error: ' + msg, file=sys.stderr)
    sys.exit(1)


def bot_version(bot, script):
    src = open(os.path.join(ROOT, bot, script + '.lua'), encoding='utf-8').read()
    m = re.search(r'print\("FRLG [A-Za-z ]+ v([0-9][0-9.]*)[ "]', src)
    if not m:
        fail('no version print found in %s/%s.lua' % (bot, script))
    return m.group(1)


def files_under(path):
    if os.path.isfile(path):
        yield path
        return
    for d, _, names in os.walk(path):
        for n in sorted(names):
            if n != '__pycache__' and not n.endswith('.pyc'):
                yield os.path.join(d, n)


def changelog_section(tag, bot, version):
    """The CHANGELOG section whose heading names this release, e.g. '## [farmbot v1.0]'."""
    text = open(os.path.join(ROOT, 'CHANGELOG.md'), encoding='utf-8').read()
    want = re.compile(r'^## \[(%s|%s v%s)\].*$' % (re.escape(tag), re.escape(bot), re.escape(version)), re.I | re.M)
    m = want.search(text)
    if not m:
        return ''
    end = re.compile(r'^## \[', re.M).search(text, m.end())
    return text[m.end():end.start() if end else len(text)].strip() + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('tag')
    ap.add_argument('--out', default=os.path.join(ROOT, 'dist'))
    args = ap.parse_args()

    m = re.fullmatch(r'([a-z]+)(?:-v([0-9][0-9.]*))?', args.tag)
    if not m or m.group(1) not in BOTS:
        fail('tag must look like <bot>-v<X.Y> with bot in %s' % ', '.join(BOTS))
    bot, version = m.groups()
    script, name = BOTS[bot]
    actual = bot_version(bot, script)
    version = version or actual
    if actual != version:
        fail('tag says v%s but %s/%s.lua prints v%s: update the version in src/ and rebuild'
             % (version, bot, script, actual))

    os.makedirs(args.out, exist_ok=True)
    top = 'poke-tools-%s-v%s' % (bot, version)
    zpath = os.path.join(args.out, top + '.zip')
    entries = [(os.path.join(ROOT, bot, script + '.lua'), script + '.lua'),
               (os.path.join(ROOT, bot, script + '.json'), script + '.json'),
               (os.path.join(ROOT, bot, 'README.md'), 'README.md'),
               (os.path.join(ROOT, 'LICENSE'), 'LICENSE')]
    examples = os.path.join(ROOT, bot, 'examples')
    if os.path.isdir(examples):
        entries += [(f, os.path.relpath(f, os.path.join(ROOT, bot))) for f in files_under(examples)]
    for part in CONFIGURATOR:
        base = os.path.join(ROOT, 'configurator', part)
        entries += [(f, os.path.relpath(f, ROOT)) for f in files_under(base)]

    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as z:
        for src, arc in entries:
            # Byte for byte: the .lua keeps its CRLF line endings for Windows.
            z.write(src, top + '/' + arc.replace(os.sep, '/'))

    readme = open(os.path.join(ROOT, bot, 'README.md'), encoding='utf-8').read()
    prerelease = '**Experimental.**' in readme
    notes = changelog_section(args.tag, bot, version)
    notes_path = ''
    if notes:
        notes_path = os.path.join(args.out, 'notes.md')
        open(notes_path, 'w', encoding='utf-8').write(notes)
    with open(os.path.join(args.out, 'release.env'), 'w', encoding='utf-8') as f:
        # Shell-quoted: the workflow reads this file with `source`.
        f.write('TITLE=%s\n' % shlex.quote('%s v%s' % (name, version)))
        f.write('PRERELEASE=%s\n' % ('true' if prerelease else 'false'))
        f.write('NOTES=%s\n' % shlex.quote(notes_path))

    print('%s  (%d files%s)' % (zpath, len(entries), ', pre-release' if prerelease else ''))


if __name__ == '__main__':
    main()
