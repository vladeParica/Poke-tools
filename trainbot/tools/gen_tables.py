"""Genera trainbot/src/train_tables.lua con datos de pret/pokefirered:
ataques, especies (tipos y EVs que dan), tabla de tipos, ataques por nivel,
nombres de objetos y habilidades, y genero.
Descarga los archivos necesarios de GitHub a tools/pret_cache/ la primera vez.
Uso:  python trainbot/tools/gen_tables.py
"""
import os, re, urllib.request
H = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(H, 'pret_cache') + os.sep
OUT = os.path.join(H, '..', 'src', 'train_tables.lua')
BASE = 'https://raw.githubusercontent.com/pret/pokefirered/master/'
FILES = {
    'moves.h': 'include/constants/moves.h',
    'battle_move_effects.h': 'include/constants/battle_move_effects.h',
    'species.h': 'include/constants/species.h',
    'items.h': 'include/constants/items.h',
    'abilities.h': 'include/constants/abilities.h',
    'battle_moves.h': 'src/data/battle_moves.h',
    'move_names.h': 'src/data/text/move_names.h',
    'species_info.h': 'src/data/pokemon/species_info.h',
    'battle_main.c': 'src/battle_main.c',
    'learnsets.h': 'src/data/pokemon/level_up_learnsets.h',
    'learnset_ptrs.h': 'src/data/pokemon/level_up_learnset_pointers.h',
    'src_data_items.json': 'src/data/items.json',
    'src_data_text_abilities.h': 'src/data/text/abilities.h',
}
os.makedirs(CACHE, exist_ok=True)
for local, remote in FILES.items():
    if not os.path.exists(CACHE + local):
        print('descargando', remote)
        urllib.request.urlretrieve(BASE + remote, CACHE + local)
P=CACHE
def defs(fn,prefix):
    d={}
    for m in re.finditer(r'#define\s+('+prefix+r'\w+)\s+(\S+)',open(P+fn).read()):
        v=m.group(2)
        try: d[m.group(1)]=int(v,0)
        except: 
            if v in d: d[m.group(1)]=d[v]
    return d
MV=defs('moves.h','MOVE_'); EF=defs('battle_move_effects.h','EFFECT_'); SP=defs('species.h','SPECIES_')
TY={'TYPE_'+n:i for i,n in enumerate('NORMAL FIGHTING FLYING POISON GROUND ROCK BUG GHOST STEEL MYSTERY FIRE WATER GRASS ELECTRIC PSYCHIC ICE DRAGON DARK'.split())}
src=open(P+'battle_moves.h').read()
moves={}
for m in re.finditer(r'\[(MOVE_\w+)\]\s*=\s*\{(.*?)\n    \}',src,re.S):
    b=m.group(2); g=lambda k: re.search(r'\.'+k+r'\s*=\s*([^,]+),',b).group(1).strip()
    moves[MV[m.group(1)]]=(int(g('power')),TY[g('type')],int(g('accuracy')),EF[g('effect')],int(g('pp')),int(g('priority')))
names={}
for m in re.finditer(r'\[(MOVE_\w+)\]\s*=\s*_\("([^"]*)"\)',open(P+'move_names.h').read()):
    names[MV[m.group(1)]]=m.group(2).replace('$','')
sp={}
s=open(P+'species_info.h').read()
for m in re.finditer(r'\[(SPECIES_\w+)\]\s*=\s*\{(.*?)\n    \}',s,re.S):
    if m.group(1) not in SP: continue
    b=m.group(2)
    t=re.search(r'\.types\s*=\s*\{(\w+),\s*(\w+)\}',b)
    if not t: continue
    ev=[int(re.search(r'\.evYield_'+k+r'\s*=\s*(\d+)',b).group(1)) for k in ('HP','Attack','Defense','Speed','SpAttack','SpDefense')]
    sp[SP[m.group(1)]]=(TY[t.group(1)],TY[t.group(2)],*ev)
eff=re.search(r'gTypeEffectiveness\[\d+\]\s*=\s*\{(.*?)\};',open(P+'battle_main.c').read(),re.S).group(1)
trip=[]
toks=[x.strip() for x in eff.replace('\n',' ').split(',') if x.strip()]
mul={'TYPE_MUL_NO_EFFECT':0,'TYPE_MUL_NOT_EFFECTIVE':5,'TYPE_MUL_SUPER_EFFECTIVE':20}
for i in range(0,len(toks),3):
    a,b,c=toks[i:i+3]
    if a=='TYPE_FORESIGHT' or a=='TYPE_ENDTABLE': trip.append('-1'); continue  # separator
    trip.append('%d,%d,%d'%(TY[a],TY[b],mul[c]))
out=['-- Generado desde pret/pokefirered (gen_tables.py)']
out.append('local TT_MOVE = {')
for i in sorted(moves):
    if i==0: continue
    p,t,a,e,pp,pr=moves[i]
    out.append('[%d]={%d,%d,%d,%d,%d,%d,"%s"},'%(i,p,t,a,e,pp,pr,names.get(i,'?').replace('"','')))
out.append('}')
out.append('local TT_SPEC = {')
for i in sorted(sp): out.append('[%d]={%s},'%(i,','.join(map(str,sp[i]))))
out.append('}')
out.append('local TT_EFF = {'+','.join(trip)+'}')
need=['EFFECT_LEVEL_DAMAGE','EFFECT_DRAGON_RAGE','EFFECT_SONICBOOM','EFFECT_SUPER_FANG','EFFECT_OHKO','EFFECT_EXPLOSION','EFFECT_DREAM_EATER','EFFECT_FOCUS_PUNCH','EFFECT_FALSE_SWIPE','EFFECT_SNORE','EFFECT_COUNTER','EFFECT_MIRROR_COAT','EFFECT_BIDE','EFFECT_PSYWAVE','EFFECT_ENDEAVOR','EFFECT_FUTURE_SIGHT','EFFECT_RECHARGE','EFFECT_MULTI_HIT','EFFECT_DOUBLE_HIT','EFFECT_TRIPLE_KICK','EFFECT_TWINEEDLE','EFFECT_RAZOR_WIND','EFFECT_SKY_ATTACK','EFFECT_SOLAR_BEAM','EFFECT_SKULL_BASH','EFFECT_SEMI_INVULNERABLE','EFFECT_SPIT_UP','EFFECT_HIDDEN_POWER','EFFECT_RETURN','EFFECT_FRUSTRATION','EFFECT_LOW_KICK','EFFECT_FLAIL','EFFECT_MAGNITUDE','EFFECT_PRESENT','EFFECT_ROLLOUT','EFFECT_FURY_CUTTER','EFFECT_ERUPTION','EFFECT_RECOIL','EFFECT_DOUBLE_EDGE','EFFECT_ABSORB','EFFECT_SNORE','EFFECT_TRAP','EFFECT_RAMPAGE','EFFECT_UPROAR','EFFECT_PURSUIT','EFFECT_REVENGE','EFFECT_SMELLINGSALT','EFFECT_FACADE','EFFECT_WEATHER_BALL','EFFECT_FAKE_OUT','EFFECT_SPIT_UP','EFFECT_VITAL_THROW','EFFECT_ALWAYS_HIT','EFFECT_SUPERPOWER','EFFECT_OVERHEAT','EFFECT_TRI_ATTACK','EFFECT_FLINCH_HIT']
out.append('local EF = {'+', '.join('%s=%d'%(n[7:],EF[n]) for n in dict.fromkeys(need) if n in EF)+'}')
missing=[n for n in need if n not in EF]
open(OUT,'w').write('\n'.join(out)+'\n')
print(len(moves),len(sp),len(trip),'missing',missing)
# Ataques por nivel (especie interna -> {nivel, ataque, nivel, ataque, ...})
ls=open(P+'learnsets.h').read()
sets={}
for m in re.finditer(r'static const u16 (s\w+LevelUpLearnset)\[\]\s*=\s*\{(.*?)\};',ls,re.S):
    sets[m.group(1)]=[(int(a),MV[b]) for a,b in re.findall(r'LEVEL_UP_MOVE\(\s*(\d+),\s*(MOVE_\w+)\)',m.group(2))]
lp=open(P+'learnset_ptrs.h').read()
learn={}
for a,b in re.findall(r'\[(SPECIES_\w+)\]\s*=\s*(s\w+LevelUpLearnset)',lp):
    if a in SP and SP[a]>0: learn[SP[a]]=sets[b]
with open(OUT,'a') as f:
    f.write('local TT_LEARN = {\n')
    for i in sorted(learn):
        f.write('[%d]={%s},\n'%(i,','.join('%d,%d'%(l,mv) for l,mv in learn[i])))
    f.write('}\n')
print('learnsets',len(learn))
# Nombres de objetos y habilidades, habilidades y genero por especie (modo inspeccion)
import json as _j
SC=CACHE
IT=defs('items.h','ITEM_')
items=_j.load(open(SC+'src_data_items.json'))['items']
AB=defs('abilities.h','ABILITY_')
an=dict(re.findall(r'\[(ABILITY_\w+)\]\s*=\s*_\("([^"]*)"\)',open(SC+'src_data_text_abilities.h').read()))
gx={}
for m in re.finditer(r'\[(SPECIES_\w+)\]\s*=\s*\{(.*?)\n    \}',open(P+'species_info.h').read(),re.S):
    if m.group(1) not in SP: continue
    b=m.group(2)
    a=re.search(r'\.abilities\s*=\s*\{(\w+),\s*(\w+)\}',b); g=re.search(r'\.genderRatio\s*=\s*([^,\n]+),',b)
    if not a or not g: continue
    gs=g.group(1).strip()
    if gs=='MON_MALE': gr=0
    elif gs=='MON_FEMALE': gr=254
    elif gs=='MON_GENDERLESS': gr=255
    else: gr=min(254,int(float(re.search(r'PERCENT_FEMALE\(([\d.]+)\)',gs).group(1))*255/100))
    gx[SP[m.group(1)]]=(AB.get(a.group(1),0),AB.get(a.group(2),0),gr)
with open(OUT,'a') as f:
    f.write('local TT_ITEMNAME = {'+','.join('[%d]="%s"'%(IT[x['itemId']],x['english'].replace('"','').replace('\\','')) for x in items if x['itemId'] in IT and IT[x['itemId']]>0)+'}\n')
    f.write('local TT_ABILNAME = {'+','.join('[%d]="%s"'%(AB[k],v) for k,v in an.items() if k in AB and AB[k]>0)+'}\n')
    f.write('local TT_SPECX = {'+','.join('[%d]={%d,%d,%d}'%(k,*v) for k,v in sorted(gx.items()))+'}\n')
print('items',len(items),'abil',len(an),'specx',len(gx))
