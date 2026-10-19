import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_train as R
_,route=R.run('record', {"evs":{"atk":6},"healBelow":40})
R.run('level', {"evs":None,"targetLevel":13,"healBelow":40,"wantedMoves":["Ember","Metal Claw","Scratch","Flamethrower"]}, route=route, show=True)
R.run('level', {"evs":None,"targetLevel":11,"healBelow":40,"wantedMoves":["Scratch","Ember","Growl","Leer"]}, route=route)
R.run('level', {"evs":None,"targetLevel":9,"healBelow":40,"wantedMoves":["Flamethrower","Surf","Ember","Scratch","Leer"]}, route=route, show=True)
