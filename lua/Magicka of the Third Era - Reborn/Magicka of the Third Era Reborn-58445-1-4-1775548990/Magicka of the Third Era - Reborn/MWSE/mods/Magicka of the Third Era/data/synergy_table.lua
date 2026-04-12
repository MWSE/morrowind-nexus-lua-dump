--                                                             Synergies
-- Synergies are generalized and stored in this fairly readable, json-like format. You can have as many as you wish! Although having too many might cause lag for the first calculation. Not sure how efficient lua is.
-- "effects_required" is not really needed right now, but I might want to optimize this and so use them to filter stuff early, not sure if it needed. Probably not.
-- "rules" is an array of arrays. Each of these arrays is a rule. Which is a set of requirements. All of these requirements have to work for a single effect.
-- basically, for each array in rule there must be an effect that fits all of the conditions.
-- condition format: {field = ..., value = ..., sign = ...}
-- "field" values : everything that's collected when we pass the spell array to multi-effect formula.
-- "value" is self explanatory
-- "sign" values : "equal", "not equal", "greater", "greater or equal", "less", "less or equal"
-- "benefit" values: so far only "cost_discount", which reduces cost by a percentage
-- "cost_discount" value is multiplied by (cheapest relevant / total cost), so result discount can't be greater than cost_discount / N, where N is amount of required effects.
-- Discount is applied to actual cost, which is the lowest of "sum of effects" and "weighed" cost. But of course, "sum of effects" cost is unsynergetic by itself.
-- These can stack if you hit many synergies with one spell, but they will get less impactful by themselves.
-- If there are several effects that apply the condition (e.g. fire damage for 5 secs and fire damage for 10 secs in example below), lowest one takes priority.
-- It's very unlikely to happen and not profitable to player to build spells this way, but just so you know.
-- Effects that get skipped in advanced formula (const_cost, targeted levitation and such) won't work for synergies

local synergy_table = {}

-- For example, this is a synergy that requires 2 components. Both are Fire Damage, both are Ranged, both have Radius of 5 or greater. One must have duration of 1, other must have it >= 5.
synergy_table[1] = {
  name = "Fireball",
  effects_required = {14},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"},
      {field = "radius", value = 5, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 1, sign = "equal"},
      {field = "radius", value = 5, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[2] = {
  name = "Chromatic Blast",
  effects_required = {14, 15, 16},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "min", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

synergy_table[3] = {
  name = "Armor Melter",
  effects_required = {14, 38},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 38, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[4] = {
  name = "Traveller's Respite",
  effects_required = {8, 77},
  rules = {
    {
      {field = "id", value = 77, sign = "equal"},
      {field = "duration", value = 60, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 8, sign = "equal"},
      {field = "duration", value = 60, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[5] = {
  name = "Calling of Fire",
  effects_required = {4, 114},
  rules = {
    {
      {field = "id", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 114, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[6] = {
  name = "Calling of Ice",
  effects_required = {6, 115},
  rules = {
    {
      {field = "id", value = 6, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 115, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[7] = {
  name = "Calling of Storm",
  effects_required = {5, 116},
  rules = {
    {
      {field = "id", value = 5, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 116, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[8] = {
  name = "Bound Suit",
  effects_required = {127, 128, 129, 131},
  rules = {
    {
      {field = "id", value = 127, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 128, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 129, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 131, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.0
  }
}

synergy_table[9] = {
  name = "Daedric Duelist",
  effects_required = {121, 130},
  rules = {
    {
      {field = "id", value = 121, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 130, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[10] = {
  name = "Daedric Berserk",
  effects_required = {117, 123},
  rules = {
    {
      {field = "id", value = 117, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 123, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[11] = {
  name = "Ultimate Detection",
  effects_required = {64, 65, 66},
  rules = {
    {
      {field = "id", value = 64, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 65, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 66, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.0
  }
}

synergy_table[12] = {
  name = "Cruel Wound",
  effects_required = {22, 23},
  rules = {
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    },
    {
      {field = "id", value = 23, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[13] = {
  name = "Chromatic Shield",
  effects_required = {4, 5, 6},
  rules = {
    {
      {field = "id", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 5, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 6, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

synergy_table[14] = {
  name = "Wintry Chill",
  effects_required = {16, 17},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"}
    },
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "attribute", value = 4, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.7
  }
}

synergy_table[15] = {
  name = "Muscle Damage",
  effects_required = {15, 17},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    },
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "attribute", value = 3, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.6
  }
}

synergy_table[16] = {
  name = "Ghost Form",
  effects_required = {42, 98},
  rules = {
    {
      {field = "id", value = 42, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 98, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[17] = {
  name = "Energy Drain",
  effects_required = {86, 88},
  rules = {
    {
      {field = "id", value = 86, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 7, sign = "greater or equal"}
    },
    {
      {field = "id", value = 88, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 7, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[18] = {
  name = "Evaporate Weapon",
  effects_required = {15, 37},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "min", value = 40, sign = "greater or equal"}
    },
    {
      {field = "id", value = 37, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

synergy_table[19] = {
  name = "Weakening Poison Field",
  effects_required = {17, 27},
  rules = {
    {
      {field = "id", value = 17, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "attribute", value = 0, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

-- based on scroll. these effects will be uneven if you use the same duration, so discount will be big (no point in having longer invisibility than levitation)
synergy_table[20] = {
  name = "Windform",
  effects_required = {10, 39},
  rules = {
    {
      {field = "id", value = 10, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "min", value = 120, sign = "greater or equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    },
    {
      {field = "id", value = 39, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.85
  }
}

-- based on scroll. Has many weird effects, so high discount.
synergy_table[21] = {
  name = "Soulrot",
  effects_required = {22, 27, 45},
  rules = {
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "attribute", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 22, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "attribute", value = 5, sign = "equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "min", value = 15, sign = "greater or equal"}
    },
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"},
      {field = "duration", value = 3, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.32
  }
}

-- based on scroll. Suboptimal with almost useless effect, large discount
synergy_table[22] = {
  name = "Black Storm",
  effects_required = {15, 24},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 2, sign = "less or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 5, sign = "greater or equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 24, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.5
  }
}

-- based on scroll. Huge synergies due to awkward effects. Not really expecting player to use this unless it's uber cheap.
synergy_table[23] = {
  name = "Baleful Suffering",
  effects_required = {7, 37, 38, 47},
  rules = {
    {
      {field = "id", value = 7, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 37, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 38, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 47, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1.6
  }
}

-- based on scroll. Reasonable. Restore part can be used as a regen. Can be used as a big targeted buff.
synergy_table[24] = {
  name = "Warrior's Blessing",
  effects_required = {75, 77, 117},
  rules = {
    {
      {field = "id", value = 75, sign = "equal"},
      {field = "duration", value = 2, sign = "greater or equal"}
    },
    {
      {field = "id", value = 77, sign = "equal"},
      {field = "duration", value = 2, sign = "greater or equal"}
    },
    {
      {field = "id", value = 117, sign = "equal"},
      {field = "min", value = 15, sign = "greater or equal"}
    },
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

-- based on scroll
synergy_table[25] = {
  name = "Hoptoad",
  effects_required = {9, 11},
  rules = {
    {
      {field = "id", value = 9, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 11, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.4
  }
}

-- based on scroll. Also uneven effects here
synergy_table[26] = {
  name = "Psychic Prison",
  effects_required = {45, 58},
  rules = {
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 58, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.65
  }
}

-- based on scroll. Bad scaling and AOE might be not practical.
synergy_table[27] = {
  name = "Illnea's Breath",
  effects_required = {16, 45},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 45, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"},
      {field = "radius", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.75
  }
}

synergy_table[28] = {
  name = "Amphibious Form",
  effects_required = {0, 1},
  rules = {
    {
      {field = "id", value = 0, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    },
    {
      {field = "id", value = 1, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.45
  }
}

-- probably not very good if you can cast stronger separate buffs, but for low magicka pool might be fine
synergy_table[29] = {
  name = "Fighting Form",
  effects_required = {79},
  rules = {
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 3, sign = "equal"}
    },
    {
      {field = "id", value = 79, sign = "equal"},
      {field = "attribute", value = 4, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1
  }
}

synergy_table[30] = {
  name = "Shadow Crawler",
  effects_required = {39, 43},
  rules = {
    {
      {field = "id", value = 39, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    },
    {
      {field = "id", value = 43, sign = "equal"},
      {field = "duration", value = 20, sign = "greater or equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[31] = {
  name = "Tiring Frost (Melee)",
  effects_required = {16, 25},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    },
    {
      {field = "id", value = 25, sign = "equal"},
      {field = "rangeType", value = 1, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.3
  }
}

synergy_table[32] = {
  name = "Tiring Frost (Ranged)",
  effects_required = {16, 25},
  rules = {
    {
      {field = "id", value = 16, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    },
    {
      {field = "id", value = 25, sign = "equal"},
      {field = "rangeType", value = 2, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.24
  }
}

synergy_table[33] = {
  name = "Warming Fire",
  effects_required = {14, 91},
  rules = {
    {
      {field = "id", value = 14, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 91, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[34] = {
  name = "Cooling Frost",
  effects_required = {15, 90},
  rules = {
    {
      {field = "id", value = 15, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 90, sign = "equal"},
      {field = "rangeType", value = 0, sign = "equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.8
  }
}

synergy_table[35] = {
  name = "Exposing Poison",
  effects_required = {27, 31},
  rules = {
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 31, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.5
  }
}

synergy_table[36] = {
  name = "Fatal Wound",
  effects_required = {23, 27},
  rules = {
    {
      {field = "id", value = 23, sign = "equal"},
      {field = "duration", value = 1, sign = "equal"},
      {field = "min", value = 40, sign = "greater or equal"}
    },
    {
      {field = "id", value = 27, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.4
  }
}

-- Enhanced Detection synergies -- not documented!

synergy_table[37] = {
  name = "Detect Creature",
  effects_required = {64, 338},
  rules = {
    {
      {field = "id", value = 64, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 338, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.75
  }
}

synergy_table[38] = {
  name = "Necromancer's Feast",
  effects_required = {339, 340},
  rules = {
    {
      {field = "id", value = 339, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 340, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.75
  }
}

synergy_table[39] = {
  name = "Thief's Detection",
  effects_required = {66, 342},
  rules = {
    {
      {field = "id", value = 66, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 342, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 0.75
  }
}

synergy_table[40] = {
  name = "Detect Abnormalities",
  effects_required = {336, 337, 340},
  rules = {
    {
      {field = "id", value = 336, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 337, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    },
    {
      {field = "id", value = 340, sign = "equal"},
      {field = "duration", value = 10, sign = "greater or equal"}
    }
  },
  benefit = {
    type = "cost_discount",
    value = 1
  }
}

return synergy_table
