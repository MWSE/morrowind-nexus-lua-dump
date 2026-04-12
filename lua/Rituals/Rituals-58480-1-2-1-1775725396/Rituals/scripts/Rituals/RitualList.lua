---Ritual template WIP
--[[

local ritual = {
  name = Ritual name/title
  id = unique identifier used for logic
  category = category id. can only have one ritual active of given category
  desc = Ritual description that will appear in ui
  soulPower = amount of soul power needed to complete ritual
  maxSouls = max amount of souls you can use (so you cant use 100 rat souls or something if needed)
  ingredients = {
    {name,recordId,amount,consumed},
  }
  
  -- effect description used for simplicity that will appear in the ui
  effectsDesc = {
    string,
  }
  
  --list of abilities that will apply. 0 to be forever, duration in seconds of gameTime
  effects = {
    {effect,duration,type}
  }
  customFunction = function(circle GameObject)
  -- global only for now
  customEvent = {name="Event name",data={event data}}
  
  -- gonna happen when overwriting category, isPermanent gotta be true
  -- right now doesnt work with effects table
  onDelete = event
  isPermanent = bool
}

-- how to denote if ingredient is used up on ritual?
]]--

local custom = require('scripts.Rituals.CustomRitualFunctions')

local day = 86400
local hour = 3600
local minute = 60

local function Ingredient(id,name,amount,consumed)
  return {
    id = id:lower(),
    name = name,
    amount = amount,
    consumed = consumed,
    type = nil,
    patterns = nil,
  }
end

local function SoulIngredient(name,amount,consumed,patterns,soulTypes)
  return {
    id = nil,
    name = name,
    amount = amount,
    consumed = consumed,
    type = nil,
    patterns = patterns,
    soulTypes = soulTypes,
  }
end

--matching entire types
--if patterns not nil matches them instead of direct id
--if patterns nil then just matches the entire type
-- for now its either patterns or type cant do both NOT ANYMORE THE FUTURE IS NOW
local function TypeIngredient(name,amount,consumed,type,patterns)
  return {
    id = nil,
    name = name,
    amount = amount,
    consumed = consumed,
    type = type,
    patterns = patterns,
  }
end

---TODO: Actualy implement this
--applies for (hopefuly) anything with effect, ie ingredients,potions,scrolls?
local function IngredientWithEffect(name,amount,consumed,type,patterns,reqEffect)
  return {
    id = nil,
    name = name,
    amount = amount,
    consumed = consumed,
    type = type,
    patterns = patterns,
    reqEffect = reqEffect,
  }
end

-- type = ability/spell
-- spells have their own duration so this one is ignored
local function Effect(id,duration,type)
  return {
    id = id,
    duration = duration,
    type = type,
  }
end

local ritualList = {}

--STATS
ritualList['r_fortify_magicka'] = {
  name = "Ritual of Fortify Magicka",
  id = "r_fortify_magicka",
  category = "r_fortify_stat_temp",
  desc = "Magicka surrounds us and flows through all living things, it is the energy of all living things. It takes time to learn its secrets. True mastery can not be replaced with anything else. However, there are ways to temporarily increase the ability to wield it. This is one of them. To help harness the powers flowing from Aetherius, one needs correct materials, with strong enough magical properties. Daedra's Hearts have great magical potential and so do frost salts. Combine them together with an emerald to bind the powers. To finish the ritual, a powerful soul, preferably of a magically inclined creature, is needed. After obtaining all the necessary ingredients, inscribe a circle of magicka and distribute the ingredients. Set six candles around it. They will grant increased magical capabilities, but beware, as it is only temporary. The effects of such ritual could last up to one day.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",2,true),
    Ingredient("ingred_frost_salts_01","Frost Salts",2,true),
    Ingredient("ingred_emerald_01","Emerald",1,true),
    Ingredient("r_ritual_candle_blue","Ritual blue candle",6,false),
  },
  effectsDesc = {
     "Fortify magicka: 100 pts for one day",
  },
  effects = {
    Effect("r_ritual_foritfy_magicka",day,"ability")
  },
}
  
ritualList['r_fortify_fatigue'] = {
  name = "Ritual of Fortify Fatigue",
  id = "r_fortify_fatigue",
  category = "r_fortify_stat_temp",
  desc = "Who knew joining the mage's guild would involve so much running? This is going to kill me. I was supposed to be a scholar, not an errand boy, but they instead made me collect every damn plant in Vvardenfel! I think I can fix this. Better write it down.\nsome racer plumes,\nnix hound meat,\nbunch of candles, regular ones will do.\nA soul, too. Something fast? Cliff racer maybe, no something more powerful...",
  soulPower = 150,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("ingred_racer_plumes_01","Racer Plumes",3,true),
    Ingredient("ingred_hound_meat_01","Hound Meat",2,true),
    Ingredient("r_ritual_candle","Ritual candle",6,false),
  },
  effectsDesc = {
     "Fortify fatigue: 100 pts for two days",
  },
  effects = {
    Effect("r_ritual_fortify_fatigue",day*2,"ability")
  },
}
  
ritualList['r_fortify_health'] = {
  name = "Ritual of Fortify Health",
  id = "r_fortify_health",
  category = "r_fortify_stat_temp",
  desc = "I have seen many careless mages perish. Too stubborn and full of themselves. As they focus on the mind, they often forget their body. One strike could mean a difference between life and death. This ritual will help. It will augment vitality, albeit temporarily. Perform this rite before delving in dangerous dungeons.\nRequired ingredients:\nFour pieces of scrap metal - they are sturdy and survived long after the demise of their makers,\nCorkbulb Root: 3 - strength drawn from the soil itself.\nCandles: 6 - preferably red, to signify the vitality.\nLastly a soul of a powerful and enduring beast. This is the most important step. Bind the vitality of the beast to you using this ritual. However, as time passes, the essence of the soul seeps, and with enough time the effects will perish completely. It will last a day at most, enough to explore dangerous locations.",
  soulPower = 250,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("ingred_scrap_metal_01","Scrap Metal",4,true),
    Ingredient("ingred_corkbulb_root_01","Corkbulb Root",3,true),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Fortify health: 100 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_health",day,"ability")
  },
}

--STATS permanent
--p for permanent
ritualList['r_fortify_magicka_p'] = {
  name = "Ritual of Fortify Magicka (permanent)",
  id = "r_fortify_magicka_p",
  category = "r_fortify_stat_p",
  desc = "I have learned how one can strengthen their connection with the Aetherius. This scroll contains its details. Atronachs are beings of pure magical energy. They manifest it as different elements. This suggests that their connection to magical forces is strong. It can be exploited. One can harness a fraction of their powers, infuse their own magical reserves by sapping theirs. I have prepared a ritual to do just that. First, flame, frost and storm atronachs must be soul-trapped. However, that is not enough. More filled soulgems are needed, of any kind, given that they are powerful enough together. Place all the soul gems in the ritual circle. To manipulate their forces, an equally powerful staff is needed - a Daedric Staff. With its help, atronach powers can be bound to staff wielder.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 85,
  ingredients = {
    SoulIngredient("Soul of Flame Atronach",1,true,{"^misc_soulgem_"},{"atronach_flame"}),
    SoulIngredient("Soul of Frost Atronach",1,true,{"^misc_soulgem_"},{"atronach_frost"}),
    SoulIngredient("Soul of Storm Atronach",1,true,{"^misc_soulgem_"},{"atronach_storm"}),
    Ingredient("daedric staff","Daedric staff",1,false),
    Ingredient("r_ritual_candle_blue","Ritual blue candle",6,false),
  },
  effectsDesc = {
     "Fortify magicka: 100 pts",
  },
  effects = {
    Effect("r_ritual_foritfy_magicka",0,"ability")
  },
}

ritualList['r_fortify_fatigue_p'] = {
  name = "Ritual of Fortify Fatigue (permanent)",
  id = "r_fortify_fatigue_p",
  category = "r_fortify_stat_p",
  desc = "My apprentice gave me an interesting journal after his return from the ruins I sent him to. It contained some novice mage ramblings. He devised a ritual to grant more stamina. This idea caught my attention. It can clearly be improved. To achieve better results, souls are needed. Cliff racers and Winged Twilights both show exceptional endurance. I have never seen a cliff racer resting on the ground. Next, parts from beasts of burden, guars and kagouti are required. After setting up the ritual circle, with the help of a powerful staff, one can increase his stamina, permanently. I am surprised that no one came up with that yet, not even me...",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 85,
  ingredients = {
    SoulIngredient("Soul of Cliff Racer",1,true,{"^misc_soulgem_"},{"cliff racer"}),
    Ingredient("ingred_guar_hide_01","Guar Hide",1,true),
    Ingredient("ingred_kagouti_hide_01","Kagouti Hide",1,true),
    Ingredient("daedric staff","Daedric staff",1,false),
    SoulIngredient("Soul of Winged Twilight",1,true,{"^misc_soulgem_"},{"winged twilight"}),
    Ingredient("r_ritual_candle","Ritual candle",6,false),
  },
  effectsDesc = {
     "Fortify fatigue: 200 pts",
  },
  effects = {
    Effect("r_ritual_foritfy_fatigue",0,"ability")
  },
}

ritualList['r_fortify_health_p'] = {
  name = "Ritual of Fortify Health (permanent)",
  id = "r_fortify_health_p",
  category = "r_fortify_stat_p",
  desc = "Not long ago, some graceless adventurer begged me to make them more sturdy. Finally, I have caved in because of his intransigent nagging. At least I made him collect all the required ingredients himself. I hoped he would perish obtaining them, but no. He did collect it all - souls of an Ogrim and a Golden Saint. During the ritual, I convinced him to use his fancy daedric helmet to complete the ritual. Finally, after finishing the ritual, granting him unnatural vitality, the adventurer left. I need to lock my tower next time to prevent more fools from barging in.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 85,
  ingredients = {
    SoulIngredient("Soul of Ogrim",1,true,{"^misc_soulgem_"},{"ogrim"}),
    SoulIngredient("Soul of Golden Saint",1,true,{"^misc_soulgem_"},{"golden saint"}),
    TypeIngredient("Any piece of daedric armor",1,true,"Armor",{"^daedric"}),
    Ingredient("daedric staff","Daedric staff",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Fortify fatigue: 200 pts",
  },
  effects = {
    Effect("r_ritual_foritfy_fatigue",0,"ability")
  },
}


--ATTRIBUTES
ritualList['r_fortify_strength'] = {
  name = "Ritual of Fortify Strength",
  id = "r_fortify_strength",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform a strength-infusing ritual, its effects last up to a day. Required items: two pieces of raw ebony ore, one of the strongest materials in Tamriel. One bottle of sujamma, known for its strengthening effect. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_raw_ebony_01","Raw Ebony",2,true),
    Ingredient("potion_local_liquor_01","Sujamma",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify strength: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_strength",day,"ability")
  },
}

ritualList['r_fortify_intelligence'] = {
  name = "Ritual of Fortify Intelligence",
  id = "r_fortify_intelligence",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform an intelligence-infusing ritual. Its effects last up to a day. Required items: Three pieces of bonemeal, containing the wisdom of ancestors. Two enchanted scrolls. One ruby to bind knowledge. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_bonemeal_01","Bonemeal",3,true),
    Ingredient("ingred_ruby_01","Ruby",1,true),
    TypeIngredient("Any scroll",2,true,nil,{"^sc_"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify intelligence: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_intelligence",day,"ability")
  },
}

ritualList['r_fortify_willpower'] = {
  name = "Ritual of Fortify Willpower",
  id = "r_fortify_willpower",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform a willpower-infusing ritual. Its effects last up to a day. Required items: Three scrib jellies. A bottle of Flin. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_scrib_jelly_01","Scrib Jelly",3,true),
    Ingredient("Potion_Cyro_Whiskey_01","Flin",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify willpower: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_willpower",day,"ability")
  },
}

ritualList['r_fortify_agility'] = {
  name = "Ritual of Fortify Agility",
  id = "r_fortify_agility",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform an agility-infusing ritual. Its effects last up to a day. Required items: Ectoplasm times two. Fire salts. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_ectoplasm_01","Ectoplasm",2,true),
    Ingredient("ingred_fire_salts_01","Fire Salts",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Agility: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_agility",day,"ability")
  },
}

ritualList['r_fortify_speed'] = {
  name = "Ritual of Fortify Speed",
  id = "r_fortify_speed",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform a speed-infusing ritual. Its effects last up to a day. Required items: Two hides of Kagouti. Moon sugar. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_kagouti_hide_01","Kagouti Hide",2,true),
    Ingredient("ingred_moon_sugar_01","Moon Sugar",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Speed: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_speed",day,"ability")
  },
}

ritualList['r_fortify_endurance'] = {
  name = "Ritual of Fortify Endurance",
  id = "r_fortify_endurance",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform an endurance-infusing ritual. Its effects last up to a day. Required items: One Daedra Heart. Hide from any animal or daedra, two times. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    TypeIngredient("Any hide or skin",2,true,nil,{"hide_01$","skin_01$","leather_01$"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Endurance: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_endurance",day,"ability")
  },
}

ritualList['r_fortify_personality'] = {
  name = "Ritual of Fortify Personality",
  id = "r_fortify_personality",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform an personality-infusing ritual. Its effects last up to a day. Required items: Three heather. Telvanni bug musk. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_heather_01","Heather",3,true),
    Ingredient("potion_t_bug_musk_01","Telvanni Bug Musk",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Personality: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_personality",day,"ability")
  },
}

ritualList['r_fortify_luck'] = {
  name = "Ritual of Fortify Luck",
  id = "r_fortify_luck",
  category = "r_fortify_attrib_temp",
  desc = "The following are instructions on how to perform a luck-infusing ritual. Its effects last up to a day. Required items: Two Hackle-Lo leaves. Two Corkbulb roots. A diamond. Set of six candles. Draw a ritual circle and set the candles around it. Place all the items within the circle to begin the ritual.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_hackle-lo_leaf_01","Hackle-Lo Leaf",2,true),
    Ingredient("ingred_corkbulb_root_01","Corkbulb Root",2,true),
    Ingredient("ingred_diamond_01","Diamond",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Luck: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_fortify_luck",day,"ability")
  },
}

--ATTRIBUTES permanent
ritualList['r_fortify_strength_p'] = {
  name = "Ritual of Fortify Strength (permanent)",
  id = "r_fortify_strength_p",
  category = "r_fortify_attrib_p",
  desc = "Strength isn't usually associated with magic. However, that doesn't mean that magic cannot improve it. There is an easier way of doing it, at least for a mage. During a ritual, souls of powerful daedra, such as Deadroths or Clannfears, can be manipulated, using a sufficiently attuned staff, to the caster's benefit. The soul's strength can be bound to the caster using raw ebony.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    Ingredient("ingred_raw_ebony_01","Raw Ebony",1,true),
    SoulIngredient("Soul of Daedroth",1,true,{"^misc_soulgem_"},{"daedroth"}),
    SoulIngredient("Soul of Clannfear",1,true,{"^misc_soulgem_"},{"clannfear"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify strength: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_strength",0,"ability")
  },
}

ritualList['r_fortify_intelligence_p'] = {
  name = "Ritual of Fortify Intelligence (permanent)",
  id = "r_fortify_intelligence_p",
  category = "r_fortify_attrib_p",
  desc = "The mage guild approved rituals aren't good enough. There are better ways to augment skills, but it's not in 'their interest' to reveal that. To get more permanent results, powerful souls should be used. For example, dremora lords are known for their high intelligence and magical prowess. So are bonewalkers. Using those souls in a ritual will allow for much more permanent effects.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    SoulIngredient("Soul of Bonelord",1,true,{"^misc_soulgem_"},{"bonelord"}),
    SoulIngredient("Soul of Dremora Lord",1,true,{"^misc_soulgem_"},{"dremora_lord"}),
    TypeIngredient("Any scroll",1,true,nil,{"^sc_"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify intelligence: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_intelligence",0,"ability")
  },
}

ritualList['r_fortify_willpower_p'] = {
  name = "Ritual of Fortify Willpower (permanent)",
  id = "r_fortify_willpower_p",
  category = "r_fortify_attrib_p",
  desc = "Everyone knows that enchanting is a potent tool. It allows us to improve armor, weapons, create powerful scrolls. But what if one were to enchant himself? The benefits could be equally useful. After capturing the soul of a Golden Saint, it can be used in a ritual. Paired with skillful manipulation by a staff, the caster could be enchanted the same way that armor is. In this case, the soul of the Golden Saint should grant the caster strengthened willpower...",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    SoulIngredient("Soul of Golden Saint",1,true,{"^misc_soulgem_"},{"golden saint"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify willpower: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_willpower",0,"ability")
  },
}

ritualList['r_fortify_agility_p'] = {
  name = "Ritual of Fortify Agility (permanent)",
  id = "r_fortify_agility_p",
  category = "r_fortify_attrib_p",
  desc = "I have refined the ritual granting the swiftness of a rogue to result in more permanent effects. With the improved formula, comes greater cost. Daedric souls are necessary to perform it. Demon spawn such as Scamps or Hungers is perfect for this application. One can finesse those souls inside a ritual circle to obtain their swiftness and agility.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    SoulIngredient("Soul of Hunger",1,true,{"^misc_soulgem_"},{"hunger"}),
    SoulIngredient("Soul of Scamp",1,true,{"^misc_soulgem_"},{"scamp"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Agility: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_agility",0,"ability")
  },
}

ritualList['r_fortify_speed_p'] = {
  name = "Ritual of Fortify Speed (permanent)",
  id = "r_fortify_speed_p",
  category = "r_fortify_attrib_p",
  desc = "Can't believe it! My racing guar lost yet again! That dumb beast cannot be relied on! My retainers spent so much time and resources training him! There is only one thing I can still do. If he loses again, I will make shoes out of him! I can increase his speed in a ritual. I will need to infuse a few bottles of skooma with the soul of a winged twilight. Then feed it all the skooma. If this does not help, I don't know what will...",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    Ingredient("potion_skooma_01","Skooma",3,true),
    SoulIngredient("Soul of Winged Twilight",1,true,{"^misc_soulgem_"},{"winged twilight"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Speed: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_speed",0,"ability")
  },
}

ritualList['r_fortify_endurance_p'] = {
  name = "Ritual of Fortify Endurance (permanent)",
  id = "r_fortify_endurance_p",
  category = "r_fortify_attrib_p",
  desc = "This research note documents a ritual which boosts the physical endurance of the caster. To be able to perform it, the souls of a dremora and an Ogrim must be captured. Using a daedric or ebony staff in the ritual circle on the souls will bind their endurance to the caster.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    SoulIngredient("Soul of Dremora",1,true,{"^misc_soulgem_"},{"dremora"}),
    SoulIngredient("Soul of Ogrim",1,true,{"^misc_soulgem_"},{"ogrim"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Endurance: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_endurance",0,"ability")
  },
}

ritualList['r_fortify_personality_p'] = {
  name = "Ritual of Fortify Personality (permanent)",
  id = "r_fortify_personality",
  category = "r_fortify_attrib_p",
  desc = "I was always fascinated by how the Telvanni Bug Musk works. I have spent countless hours researching it. There is a ritual that can be performed which grants its power, permanently. Five bottles of the bug musk are needed together with scrib jelly. A powerful soul is also needed, like the Golden Saint...",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    Ingredient("potion_t_bug_musk_01","Telvanni Bug Musk",5,true),
    SoulIngredient("Soul of Scrib",1,true,{"^misc_soulgem_"},{"scrib"}),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Personality: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_personality",0,"ability")
  },
}

ritualList['r_fortify_luck_p'] = {
  name = "Ritual of Fortify Luck (permanent)",
  id = "r_fortify_luck_p",
  category = "r_fortify_attrib_p",
  desc = "This is so unlucky, my fifth apprentice has died! I need to start performing some kind of luck rituals on them. After speaking with a fellow wizard, I came up with the ritual, which requires all sorts of gems: diamonds, emeralds, rubies and pearls. Using them during the ritual, together with a cup of moon sugar, will surely turn luck around.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    Ingredient("ingred_diamond_01","Diamond",1,true),
    Ingredient("ingred_emerald_01","Emerald",1,true),
    Ingredient("ingred_pearl_01","Pearl",1,true),
    Ingredient("ingred_ruby_01","Ruby",1,true),
    Ingredient("ingred_moon_sugar_01","Moon Sugar",1,true),
    TypeIngredient("Daedric or ebony staff",1,false,nil,{"daedric staff","ebony staff"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Luck: 20 pts",
  },
  effects = {
    Effect("r_ritual_fortify_luck",0,"ability")
  },
}

ritualList['r_fortify_attack'] = {
  name = "Ritual of Fortify Attack",
  id = "r_fortify_attack",
  category = "r_fortify_attack",
  desc = "The ritual contained on this scroll will greatly aid any spellswords. It will make your swings hit harder and thrust pierce deeper. A ritual is necessary to perform, before the battle. It will need two hearts - one of the daedra, the other of a ghoul. Place a weapon in the circle, between the hearts. Use the daedric dagger on them to begin the ritual. The forces will infuse your attacks and consume both of the hearts, together with the weapon.",
  soulPower = 250,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("ingred_ghoul_heart_01","Ghoul Heart",1,true),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    TypeIngredient("Any weapon",1,true,"Weapon",nil),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Fortify Attack: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_fortify_attack",day,"ability")
  },
}

ritualList['r_resist_normal_weapons'] = {
  name = "Ritual of Resist Normal Weapons",
  id = "r_resist_normal_weapons",
  category = "r_resist_normal_weapons",
  desc = "One often wonders about the creatures impervious to normal weapons. What if I told you I found a way to replicate that by performing a ritual? To obtain similar powers, one must gather ectoplasm and gravedust - gathered from the very beings, which power we crave. Next, a daedra heart is necessary, as well as the soul of any manner of ghost. Using those ingredients during a ritual will grant the power of resisting normal weapons...",
  soulPower = 250,
  maxSouls = 0,
  difficulty = 45,
  ingredients = {
    Ingredient("ingred_ectoplasm_01","Ectoplasm",3,true),
    Ingredient("ingred_gravedust_01","Gravedust",3,false),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    SoulIngredient("Soul of a ghost",1,true,{"^misc_soulgem_"},{"ghost","bonelord",}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Resist Normal Weapons: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_resist_normal_weapons",day,"ability")
  },
}

ritualList['r_resist_fire'] = {
  name = "Ritual of Resist Fire",
  id = "r_resist_fire",
  category = "r_resist_element",
  desc = "This series of scrolls is meant to help overcome various elements. This particular one will focus on the element of fire. To increase fire resistance, a ritual can be performed with the following ingredients: Soul of a Flame Atronach, two fire salts, fire petals and a daedra heart...",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_fire_petal_01","Fire Petal",1,true),
    Ingredient("ingred_fire_salts_01","Fire Salts",2,true),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    SoulIngredient("Soul of Flame Atronach",1,true,{"^misc_soulgem_"},{"atronach_flame"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Resist Fire: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_resist_fire",day,"ability")
  },
}

ritualList['r_resist_frost'] = {
  name = "Ritual of Resist Frost",
  id = "r_resist_frost",
  category = "r_resist_element",
  desc = "This series of scrolls is meant to help overcome various elements. This particular one will focus on the element of frost. To increase frost resistance, a ritual can be performed with the following ingredients: Soul of a Frost Atronach, three frost salts and a daedra heart...",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_frost_salts_01","Frost Salts",3,true),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    SoulIngredient("Soul of Frost Atronach",1,true,{"^misc_soulgem_"},{"atronach_frost"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Resist Frost: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_resist_frost",day,"ability")
  },
}

ritualList['r_resist_shock'] = {
  name = "Ritual of Resist Shock",
  id = "r_resist_shock",
  category = "r_resist_element",
  desc = "This series of scrolls is meant to help overcome various elements. This particular one will focus on the element of storm. To increase shock resistance, a ritual can be performed with the following ingredients: Soul of a Storm Atronach, three void salts and a daedra heart...",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_void_salts_01","Void Salts",3,true),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    SoulIngredient("Soul of Storm Atronach",1,true,{"^misc_soulgem_"},{"atronach_storm"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Resist Shock: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_resist_shock",day,"ability")
  },
}

ritualList['r_resist_poison'] = {
  name = "Ritual of Resist Poison",
  id = "r_resist_poison",
  category = "r_resist_element",
  desc = "This series of scrolls is meant to help overcome various elements. This entry is an extra, covering poison resistance. It can be achieved by performing a ritual using: Three black Lichen, three Scathecraw and the soul of a Bull Netch...",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_black_lichen_01","Black Lichen",3,true),
    Ingredient("ingred_scathecraw_01","Scathecraw",3,true),
    SoulIngredient("Soul of Bull Netch",1,true,{"^misc_soulgem_"},{"netch_bull"}),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Resist Poison: 20 pts for a day",
  },
  effects = {
    Effect("r_ritual_resist_poison",day,"ability")
  },
}

ritualList['r_restore_attrib'] = {
  name = "Ritual of Restore Attributes",
  id = "r_restore_attrib",
  category = "r_restore_attrib",
  desc = "Similar to enchanting, daedra souls can be used to enhance potions. Using any kind of proper restore potion in a ritual with daedra souls and one daedra heart can be used to amplify the power of the potion, reinvigorating the caster more effectively than the potion alone.",
  soulPower = 250,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    TypeIngredient("Any quality restore potion",1,true,"Potion",{"^p_restore_(.+)_([qe])$"}),
    TypeIngredient("Any source of light",6,false,"Light",nil),
  },
  effectsDesc = {
     "Restore all attributes by 50 pts",
  },
  effects = {
    Effect("r_ritual_restore_attrib",0,"spell")
  },
}

ritualList['r_repair_gear'] = {
  name = "Ritual of Repair Gear",
  id = "r_repair_gear",
  category = "r_repair_gear",
  desc = "A proficient mage does not require the services of a smith, as magic can be used, to a much higher degree, to repair any gear. Using the power of captured souls, the condition of equipment can be mended to a much higher degree than any smith is capable of. Using too much soul-power might have unintended consequences. Because of this, the amount of souls used in the ritual should be carefully considered.",
  soulPower = 0,
  maxSouls = 0,
  difficulty = 40,
  ingredients = {
    TypeIngredient("Any source of light",6,false,"Light",nil),
  },
  effectsDesc = {
     "Repair gear 2 pts for each pt of soul",
  },
  effects = {
  },
  customFunction = custom.ritualRepairGear
}

ritualList['r_create_tele'] = {
  name = "Create Teleportation Circle",
  id = "r_create_tele",
  category = "r_create_tele",
  desc = "Transmutes ritual circle into circle of teleportation. Allowing to travel to dfiferent teleportation circles.",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("r_ritual_candle_blue","Ritual blue candle",6,false),
  },
  effectsDesc = {
     "Create Circle of Teleportation",
  },
  effects = {
  },
  customFunction = custom.createTeleporter
}

ritualList['r_skill_gain'] = {
  name = "Ritual of Forbidden Knowledge",
  id = "r_skill_gain",
  category = "r_skill_gain",
  desc = "This ritual will make honing your skills more effective, giving quicker results. You will need to gather void salts, daedra heart and books, no less than five. Draw the ritual circle and set the candles around it. Stack the books within the ritual circle and spread the void salts over them. After that, place the heart on top of them and the ritual will begin.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 60,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_void_salts_01","Void Salts",4,true),
    TypeIngredient("Any books",5,false,"Book",nil),
    Ingredient("r_ritual_candle_blue","Ritual blue candle",6,false),
  },
  effectsDesc = {
     "Increase all skill gains by 20%",
  },
  effects = {
  },
  customFunction = custom.skillGain
}

ritualList['r_mana_regen'] = {
  name = "Ritual of Mana Regeneration",
  id = "r_mana_regen",
  category = "r_mana_regen",
  desc = "This ritual allows you to absorb the surrounding magicka at a much greater pace than normal. To perform it you will need three different types of magical salts - fire, frost and void. To commence the ritual, a heart of daedra is also necessary...",
  soulPower = 400,
  maxSouls = 0,
  difficulty = 75,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_void_salts_01","Void Salts",2,true),
    Ingredient("ingred_fire_salts_01","Fire Salts",2,true),
    Ingredient("ingred_frost_salts_01","Frost Salts",2,true),
    Ingredient("r_ritual_candle_blue","Ritual blue candle",6,false),
  },
  effectsDesc = {
     "Regenerate magicka: 1pt for quarter of a day.",
  },
  effects = {
    Effect('r_mana_regen',day/4,'ability')
  },
}

ritualList['r_summon_trader'] = {
  name = "Ritual of Summoning",
  id = "r_summon_trader",
  category = "r_summon_trader",
  desc = "With sufficient offering, summon a dremora from oblivion itself. This creature holds vast knowledge. You might be able to learn something from it.",
  soulPower = 0,
  maxSouls = 0,
  difficulty = 60,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    TypeIngredient("Gold",3000,true,nil,{"gold"}),
  },
  effectsDesc = {
     "Summons a dremora vendor",
  },
  effects = {
  },
  customFunction = custom.summonVendor,
  known = true,
}

ritualList['r_drain_corpse'] = {
  name = "Corpse Siphon",
  id = "r_drain_corpse",
  category = "r_drain_corpse",
  desc = "Ritual enables drawing energy and magical reserves from a recently deceased being. Stronger mystics are able to extract more.",
  soulPower = 0,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
    Ingredient("daedric dagger","Daedric dagger",1,false),
  },
  actors = {
    {id=nil,name="Any dead being",type=nil,patterns=nil,consumed=true,count=1,dead=true}
  },
  effectsDesc = {
     "Absorbs %.2f%% fatigue and magicka from corpse.",
  },
  effectsEval = {
    {id = 1,eval = custom.evalMysticism},
  },
  effects = {
  },
  customFunction = custom.absorbStats,
}

ritualList['r_prepare_spell'] = {
  name = "Prepare spell",
  id = "r_prepare_spell",
  category = "r_prepare_spell",
  desc = "Prepare currently selected spell before casting it. If the spell cost is greater than the magicka reserves, the rest will be paid in blood. Prepared spell will always succeed and not cost any magicka. Only one spell can be prepared at a time and used during one day.",
  soulPower = 20,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
  },
  effectsDesc = {
     "Prepares a single spell.",
  },
  effects = {
  },
  customFunction = custom.prepareSpell,
  customValidate = custom.canCastToday,
}

ritualList['r_summon_scamp'] = {
  name = "Scamp Summoning",
  id = "r_summon_scamp",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Scamp",1,true,{"^misc_soulgem_"},{"scamp"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a scamp.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_scamp"},
  isPermanent = true,
}

ritualList['r_summon_atronach_flame'] = {
  name = "Flame Atronach Summoning",
  id = "r_summon_atronach_flame",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Flame Atronach",1,true,{"^misc_soulgem_"},{"atronach_flame"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a flame atronach.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_atronach_flame"},
  isPermanent = true,
}

ritualList['r_summon_atronach_frost'] = {
  name = "Frost Atronach Summoning",
  id = "r_summon_atronach_frost",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Frost Atronach",1,true,{"^misc_soulgem_"},{"atronach_frost"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a frost atronach.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_atronach_frost"},
  isPermanent = true,
}

ritualList['r_summon_atronach_storm'] = {
  name = "Storm Atronach Summoning",
  id = "r_summon_atronach_storm",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Storm Atronach",1,true,{"^misc_soulgem_"},{"atronach_storm"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a storm atronach.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_atronach_storm"},
  isPermanent = true,
}

ritualList['r_summon_clannfear'] = {
  name = "Clannfear Summoning",
  id = "r_summon_clannfear",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Clannfear",1,true,{"^misc_soulgem_"},{"clannfear"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Clannfear.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_clannfear"},
  isPermanent = true,
}

ritualList['r_summon_daedroth'] = {
  name = "Daedroth Summoning",
  id = "r_summon_daedroth",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Daedroth",1,true,{"^misc_soulgem_"},{"daedroth"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Daedroth.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_daedroth"},
  isPermanent = true,
}

ritualList['r_summon_dremora'] = {
  name = "Dremora Summoning",
  id = "r_summon_dremora",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Dremora",1,true,{"^misc_soulgem_"},{"dremora"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Dremora.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_dremora"},
  isPermanent = true,
}

ritualList['r_summon_golden_saint'] = {
  name = "Golden Saint Summoning",
  id = "r_summon_golden_saint",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Golden Saint",1,true,{"^misc_soulgem_"},{"golden saint"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Golden Saint.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_golden saint"},
  isPermanent = true,
}

ritualList['r_summon_hunger'] = {
  name = "Hunger Summoning",
  id = "r_summon_hunger",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Hunger",1,true,{"^misc_soulgem_"},{"hunger"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Hunger.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_hunger"},
  isPermanent = true,
}

ritualList['r_summon_ogrim'] = {
  name = "Ogrim Summoning",
  id = "r_summon_ogrim",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Ogrim",1,true,{"^misc_soulgem_"},{"ogrim"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons an Ogrim.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_ogrim"},
  isPermanent = true,
}

ritualList['r_summon_winged_twilight'] = {
  name = "Winged Twilight Summoning",
  id = "r_summon_winged twilight",
  category = "r_summon",
  desc = "It is more costly and dangerous to summon daedra for a longer period of time, compared to temporary conjuration. First, to summon a daedra that will not try to murder you immediately, the soul of the chosen daedra must be trapped. Next, more souls are needed to bind the creature to your service. The sum of souls is usually larger than the one to be summoned. Lastly, a daedra heart is needed to be punctured by a daedric dagger during a ritual. After those steps, a daedra should be bound to serve, until it dies.",
  soulPower = 600,
  maxSouls = 0,
  difficulty = 70,
  ingredients = {
    SoulIngredient("Soul of Winged Twilight",1,true,{"^misc_soulgem_"},{"winged twilight"}),
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("daedric dagger","Daedric dagger",1,false),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Summons a Winged Twilight.",
  },
  effects = {
  },
  customEvent = 'R_Summon_Spawn',
  customEventArgs = {creature="r_s_winged twilight"},
  isPermanent = true,
}

ritualList['r_summon_recover'] = {
  name = "Teleport summoned daedra",
  id = "r_summon_recover",
  category = "r_summon_recover",
  desc = "This ritual is used to bring back your permanently summoned daedra. Useful if you manage to lose track of it.",
  soulPower = 20,
  maxSouls = 0,
  difficulty = 50,
  ingredients = {
  },
  effectsDesc = {
     "Teleports the daedra back to you.",
  },
  effects = {
  },
  customEvent = 'R_RecoverSummon',
  customEventArgs = {},
  known = true,
}

ritualList['r_daedric_upgrade'] = {
  name = "Ritual of Daedric Refinement",
  id = "r_daedric_upgrade",
  category = "r_daedric_upgrade",
  desc = "A powerful mage can create daedric equipment by infusing existing ebony equipment during a ritual. With the help of a daedra heart, armor or weapon can be infused with powerful souls to transmute the equipment into a daedric one.",
  soulPower = 800,
  maxSouls = 0,
  difficulty = 80,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    TypeIngredient("Any cursed item",1,true,nil,{"_cursed_"}),
    TypeIngredient("Ebony armor or weapon",1,true,{"Armor","Weapon"},{"ebony"}),
    Ingredient("r_ritual_candle_red","Ritual red candle",6,false),
  },
  effectsDesc = {
     "Infuses ebony equipment, turning it daedric.",
  },
  effects = {
  },
  customFunction = custom.daedricUpgrade,
}

ritualList['r_chameleon'] = {
  name = "Ritual of Chameleon",
  id = "r_chameleon",
  category = "r_chameleon",
  desc = "The ritual contained in this scroll will help with blending in the surroundings.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_moon_sugar_01","Moon Sugar",1,true),
    Ingredient("food_kwama_egg_01","Small Kwama Egg",2,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Chameleon: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_chameleon",day,"ability")
  },
}

ritualList['r_shield'] = {
  name = "Ritual of Shielding",
  id = "r_shield",
  category = "r_shield",
  desc = "This ritual will shield the caster from many forms of harm. It uses the strength of volcanic glass and ancient dwemer metal. The ritual will coat with a magical layer of armor, adding to the existing protection.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_raw_glass_01","Raw Glass",1,true),
    Ingredient("ingred_scrap_metal_01","Scrap Metal",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Shield: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_shield",day,"ability")
  },
}

ritualList['r_sanctuary'] = {
  name = "Ritual of Sanctuary",
  id = "r_sanctuary",
  category = "r_sanctuary",
  desc = "Performing ritual contained within this scroll will make the caster harder to hit.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_corkbulb_root_01","Corkbulb Root",2,true),
    Ingredient("ingred_diamond_01","Diamond",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Sanctuary: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_sanctuary",day,"ability")
  },
}

ritualList['r_water_breathing'] = {
  name = "Ritual of Water Breathing",
  id = "r_water_breathing",
  category = "r_water_breathing",
  desc = "This ritual was developed as a better alternative to breathing underwater for prolonged periods of time. The effects of the ritual last up to a day, making use of ordinary magic or potions redundant.",
  soulPower = 200,
  maxSouls = 0,
  difficulty = 35,
  ingredients = {
    Ingredient("ingred_daedras_heart_01","Daedra's Heart",1,true),
    Ingredient("ingred_russula_01","Luminous Russula",2,true),
    Ingredient("ingred_pearl_01","Pearl",1,true),
    TypeIngredient("Any source of light",6,false,"Light",nil)
  },
  effectsDesc = {
     "Water Breathing: 20 pts for one day",
  },
  effects = {
    Effect("r_ritual_water_breathing",day,"ability")
  },
}

--change weather rituals
--weather buffs

ritualList['dummy'] = {
  name = "dummy ritual",
  id = "dummy",
  category = "dummy",
  desc = "Dummy ritual for testing",
  soulPower = 0,
  difficulty = 50,
  maxSouls = 0,
  ingredients = {
  },
  effectsDesc = {
     "Does nothing :)",
  },
  effects = {
  },
}

return ritualList