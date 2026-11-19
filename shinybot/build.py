"""Generates FRLG_ShinyBot.lua (CRLF, for Windows) from src/bot_body.lua (ADR-0015).
Usage:  python shinybot/build.py
"""
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shared'))
from buildlib import build  # noqa: E402
build('shinybot/src/bot_body.lua', 'FRLG_ShinyBot.lua')
