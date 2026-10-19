import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_train as R
_,route=R.run('record', {"evs":{"atk":6},"healBelow":40})
R.run('level', {"evs":None,"targetLevel":11,"healBelow":40}, route=route, show=False)
R.run('level', {"evs":None,"targetLevel":9,"healBelow":40,"learnMoves":"never"}, route=route)
R.run('level', {"evs":None,"targetLevel":9,"healBelow":40,"learnMoves":"ask","askTimeout":5}, route=route, show=True)
R.run('level', {"evs":None,"targetLevel":11,"healBelow":40,"keepMoves":["Growl","Leer"]}, route=route)
