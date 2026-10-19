import os, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)))  # las pruebas corren desde shinybot/tests
import lupa.lua51 as L, time
src=open('../FRLG_ShinyBot.lua').read()
for mode in ['static','gift','roamer']:
    lua=L.LuaRuntime(); ls=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
    t=time.time()
    r=tuple(ls(open('mock_rng.lua').read(),'mock')(mode,0,True,True)(ls(src,'bot')))
    print(mode, 'err=',r[1],'frames=',r[2],'generated=',r[5],'loads=',r[8],'lastPID=%08X'%int(r[9]), '%.1fs'%(time.time()-t))
