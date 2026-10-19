import lupa.lua51 as L, os, sys, tempfile, json, shutil
here=os.path.dirname(os.path.abspath(__file__))
src=open(os.path.join(here,'..','FRLG_TrainBot.lua')).read()
mock=open(os.path.join(here,'mock_train.lua')).read()
def run(scen, cfg, route=None, show=False):
    d=tempfile.mkdtemp()
    old=os.getcwd(); os.chdir(d)
    open('FRLG_TrainBot.json','w').write(json.dumps(cfg))
    if route: open('FRLG_TrainRoute.txt','w').write(route)
    lua=L.LuaRuntime()
    ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    r=tuple(ls(mock,'mock')(scen)(ls(src,'bot')))
    routeTxt=open('FRLG_TrainRoute.txt').read() if os.path.exists('FRLG_TrainRoute.txt') else ''
    log=open('logs/train_log.txt').read() if os.path.exists('logs/train_log.txt') else ''
    os.chdir(old); shutil.rmtree(d)
    err,frame,battles,fought,ran,heals,learn,evs,lvl,printed,events,pos,growl=r
    print(f"[{scen}] err={err.split(chr(10))[0][:90]} frame={frame} battles={battles} fought={fought} ran={ran} heals={heals} learn={learn} evs={evs} lvl={lvl} pos={pos} growl={growl}")
    if show:
        print('--- print ---'); print(printed[-1500:]); print('--- log ---'); print(log[-1500:]); print('--- events ---'); print(events[-800:])
    return r, routeTxt
if __name__=='__main__':
    show='-v' in sys.argv
    base={"evs":{"atk":6},"healBelow":40}
    run('evs', base, show=show)
    r,route=run('record', base, show=show)
    print('ruta:', route[:300])
    run('pokerus', {"evs":{"atk":5},"healBelow":40}, route=route, show=show)
    run('pokerus', {"evs":{"atk":6},"healBelow":40}, route=route, show=show)
    run('level', {"evs":None,"targetLevel":8,"healBelow":40}, route=route, show=show)
    run('nolearn', {"evs":{"atk":2,"spe":3},"healBelow":40,"avoidSpecies":["Pidgey"]}, route=route, show=show)
