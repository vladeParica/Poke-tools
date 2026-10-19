import json,re
import os, urllib.request
H=os.path.dirname(os.path.abspath(__file__))
P=os.path.join(H,'..','..','trainbot','tools','pret_cache')+os.sep
os.makedirs(P,exist_ok=True)
for loc,rem in (('species_info.h','src/data/pokemon/species_info.h'),('wild_encounters.json','src/data/wild_encounters.json')):
    if not os.path.exists(P+loc):
        urllib.request.urlretrieve('https://raw.githubusercontent.com/pret/pokefirered/master/'+rem,P+loc)
s=open(P+'species_info.h').read()
Y={}
for m in re.finditer(r'\[(SPECIES_\w+)\]\s*=\s*\{(.*?)\n    \}',s,re.S):
    b=m.group(2)
    try: Y[m.group(1)]=[int(re.search(r'\.evYield_'+k+r'\s*=\s*(\d+)',b).group(1)) for k in ('HP','Attack','Defense','SpAttack','SpDefense','Speed')]
    except: pass
ST=['PS','At','Df','AtE','DfE','Vel']
RATES=[20,20,10,10,10,10,5,5,4,4,1,1]
d=json.load(open(P+'wild_encounters.json'))
res={k:[] for k in range(6)}
for g in d['wild_encounter_groups']:
    for e in g['encounters']:
        lab=e['base_label']; ver='FR' if lab.endswith('FireRed') else ('LG' if lab.endswith('LeafGreen') else '?')
        lm=e.get('land_mons')
        if not lm: continue
        mons=lm['mons']
        for k in range(6):
            pure=0; comp={}
            for r,mon in zip(RATES,mons):
                y=Y.get(mon['species'],[0]*6)
                if y[k]>0 and sum(y)==y[k]:
                    pure+=r*y[k]; n=mon['species'][8:].title(); comp[n]=comp.get(n,0)+r
            if pure>0:
                lv=sum(m['min_level'] for m in mons)/len(mons)
                res[k].append((pure/100,ver,e['map'][4:],round(lv),comp))
for k in range(6):
    print('==',ST[k])
    seen=set()
    for v,ver,mp,lv,comp in sorted(res[k],key=lambda x:-x[0]):
        key=(mp,)
        if key in seen: continue
        seen.add(key)
        print(f"  {v:.2f} EV/encuentro  {ver} {mp} Nv~{lv}  " + ', '.join(f'{n} {p}%' for n,p in sorted(comp.items(),key=lambda x:-x[1])))
        if len(seen)>=5: break
