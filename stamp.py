#!/usr/bin/env python3
"""Отмечает, что гипотеза только что отработала. Пишет только время, ничего больше."""
import json, os, sys
from datetime import datetime, timezone
HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "runs.json")
which = sys.argv[1]
try:
    d = json.load(open(STATE))
except Exception:
    d = {}
d[which] = datetime.now(timezone.utc).isoformat(timespec="seconds")
json.dump(d, open(STATE, "w"), indent=1, sort_keys=True)
print(f"отмечено: {which} = {d[which]}")
