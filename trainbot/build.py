"""Generates FRLG_TrainBot.lua (CRLF, for Windows) from src/train_body.lua.
Game data comes from shared/gamedata/gamedata.json (tools/gamedata/gamedata.py, ADR-0015).
Usage:  python trainbot/build.py
"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared'))
from buildlib import build  # noqa: E402
build('trainbot/src/train_body.lua', 'FRLG_TrainBot.lua')
