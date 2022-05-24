from lua_dump import *

from collections import Counter


def test_no_duplicate_mod_ids():
    index = LuaIndex.load()

    counter: Counter[int] = Counter()
    for lua_mod in index.lua_mods:
        counter[lua_mod.mod_id] += 1

    assert all(count == 1 for count in counter.values())
