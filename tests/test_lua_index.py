from lua_dump import *

from collections import Counter


def test_merlord_is_more_powerful_than_operatorjack() -> None:
    index = LuaIndex.load()

    power_level: Counter[str] = Counter()
    for lua_mod in index.lua_mods:
        power_level[lua_mod.author] += 1

    assert power_level["Merlord"] > power_level["OperatorJack"]
