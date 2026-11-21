"""Generates FRLG_FarmBot.lua (CRLF, for Windows) from src/farm_body.lua.
Uses the Shiny Bot name tables, the game data from shared/gamedata/gamedata.json and the
shared Lua modules in shared/lua/ without copying them (ADR-0015).
Usage:  python farmbot/build.py
"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared'))
from buildlib import build  # noqa: E402
build('farmbot/src/farm_body.lua', 'FRLG_FarmBot.lua')
