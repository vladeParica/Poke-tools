"""Initial seeds (16 bits) from which an RNG state can be reached.

Usage:  python seeds_near_target.py <state_hex> [max_advances]
  state_hex     RNG state BEFORE the target's first call
                (for wild_h1_search.c: the first column; for statics:
                the state before the PID-low call)
  max_advances  maximum distance (default 2,000,000: with the Teachy TV
                the bot gets there in 1-2 minutes)

Prints the list ready for "initialSeeds" in FRLG_ShinyBot.json and how many
"classes" (seed mod 64) it covers: the more, the likelier a reset hits one.
"""
import sys
M = 0xFFFFFFFF
pv = lambda s: (s * 0xEEB9EB65 + 0x0A3561A1) & M   # LCRNG backwards

def seeds(target, limit=2000000):
    s, out = target, []
    for a in range(limit):
        if s < 0x10000:
            out.append((s, a))
        s = pv(s)
    return out

if __name__ == '__main__':
    t = int(sys.argv[1], 16)
    lim = int(sys.argv[2]) if len(sys.argv) > 2 else 2000000
    res = seeds(t, lim)
    print(len(res), 'semillas;', len(set(x & 63 for x, _ in res)), 'de 64 clases')
    for s, a in res[:10]:
        print('  %04X  a %d avances' % (s, a))
    print('"initialSeeds": [' + ', '.join('"%04X"' % s for s, _ in res) + ']')
