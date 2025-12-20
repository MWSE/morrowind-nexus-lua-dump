-- only "quasi exteriors" with sky
-- higher priority = gets picked instead of other matches

-- same as fallback:
QUASI_EXTERIOR_CLIMATE_SOURCES = {
	{
		match = "mournhold",
		climate = "urban",
		temperature = 26,
		priority = 10
	},
	{
		match = "gramfeste",
		climate = "urban",
		temperature = 26,
		priority = 10
	}
}

-- starwind:
if G_STARWIND_INSTALLED then
-- TATOOINE - Desert planet, scorching days, freezing nights (classic desert)
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, deep sea", -- note: actually just a normal exterior level
		climate = "ashland", -- sense: geothermal caves / night: volcanic (heat retention)
		temperature = 32,
		priority = 50
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, beast's lair", -- note: no cave at all
		climate = "ashland", -- sense: creature body heat / night: volcanic
		temperature = 30,
		priority = 50
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, the hidden stash", -- note: not really sheltered
		climate = "ashland", -- sense: sheltered but still desert / night: ashland
		temperature = 33,
		priority = 50
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, arena",
		climate = "urban", -- sense: structure with crowds / night: urban (slight warmth)
		temperature = 38,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, swoop racetrack", -- note: empty level?
		climate = "ashland", -- sense: built structure / night: urban
		temperature = 37,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, rodian district",
		climate = "urban", -- sense: settlement / night: urban
		temperature = 36,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, sand hole",
		climate = "ashland", -- sense: exposed pit / night: ashland (cold)
		temperature = 38,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, death canyon",
		climate = "ashland", -- sense: barren canyon / night: ashland
		temperature = 40,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, sandreach", --note: actually a city
		climate = "urban", -- sense: open dunes / night: ashland
		temperature = 39,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, sandriver", --note: actually a city
		climate = "urban", -- sense: dry riverbed / night: ashland
		temperature = 38,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, expanse",
		climate = "ashland", -- sense: vast desert / night: ashland
		temperature = 40,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine, dune sea",
		climate = "ashland", -- sense: endless dunes / night: ashland
		temperature = 41,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "tatooine",
		climate = "ashland", -- sense: desert planet / night: ashland (freezing nights)
		temperature = 38,
		priority = 10
	})

-- HOTH - Ice planet
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "hoth",
		climate = "arctic", -- sense: ice world / night: arctic
		temperature = -28,
		priority = 10
	})

-- DANTOOINE - Temperate grasslands, rolling plains
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, sea",
		climate = "coast", -- sense: coastal waters / night: coast (slight warmth)
		temperature = 18,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, meditation site",
		climate = "temperate", -- sense: peaceful grove / night: temperate
		temperature = 20,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, estate grounds",
		climate = "temperate", -- sense: cultivated land / night: temperate
		temperature = 19,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, valley of the jedi",
		climate = "grassland", -- sense: sacred valley / night: grassland
		temperature = 18,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, ballast",
		climate = "coast", -- sense: weight/anchor, near water / night: coast
		temperature = 17,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, hunting grounds",
		climate = "grassland", -- sense: open savanna / night: grassland
		temperature = 21,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine, dantari wilds",
		climate = "grassland", -- sense: untamed plains / night: grassland
		temperature = 19,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dantooine",
		climate = "grassland", -- sense: pastoral plains / night: grassland
		temperature = 20,
		priority = 10
	})

-- TARIS - Ecumenopolis (city-planet), urban sprawl
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, the promised land",
		climate = "temperate", -- sense: hidden paradise / night: temperate (natural)
		temperature = 22,
		priority = 50
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, across the wall",
		climate = "grassland", -- sense: beyond civilization / night: grassland
		temperature = 18,
		priority = 50
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, sith headquarters",
		climate = "urban", -- sense: climate-controlled fortress / night: urban
		temperature = 21,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, upper city apartments",
		climate = "urban", -- sense: wealthy district / night: urban
		temperature = 22,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, upper city north",
		climate = "urban", -- sense: affluent area / night: urban
		temperature = 22,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, upper city south",
		climate = "urban", -- sense: affluent area / night: urban
		temperature = 22,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, central plaza",
		climate = "urban", -- sense: city center / night: urban
		temperature = 23,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, ruined plaza",
		climate = "urban", -- sense: decayed urban / night: urban (rubble retains some heat)
		temperature = 19,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris, remnants",
		climate = "urban", -- sense: post-bombardment ruins / night: urban
		temperature = 17,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "taris",
		climate = "urban", -- sense: city-planet / night: urban (heat island effect)
		temperature = 21,
		priority = 10
	})

-- NAR SHADDAA - Smuggler's Moon, polluted urban hellscape
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "nar shaddaa, obsheeda plaza",
		climate = "urban", -- sense: commercial hub / night: urban
		temperature = 26,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "nar shaddaa, peyuska plaza",
		climate = "urban", -- sense: market square / night: urban
		temperature = 26,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "nar shaddaa, quanun alley",
		climate = "urban", -- sense: cramped back alley / night: urban
		temperature = 25,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "nar shaddaa, makacheesa market",
		climate = "urban", -- sense: busy market / night: urban
		temperature = 27,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "nar shaddaa",
		climate = "urban", -- sense: industrial moon / night: urban (pollution traps heat)
		temperature = 26,
		priority = 10
	})

-- MANAAN - Ocean world
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "manaan, melchior's reef",
		climate = "coast", -- sense: reef/shallows / night: coast
		temperature = 24,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "manaan, ignatious' reef",
		climate = "coast", -- sense: reef/shallows / night: coast
		temperature = 24,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "manaan, bazaar",
		climate = "coast", -- sense: floating market / night: coast
		temperature = 23,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "manaan, central",
		climate = "coast", -- sense: main platform / night: coast
		temperature = 23,
		priority = 30
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "manaan",
		climate = "coast", -- sense: ocean world / night: coast (ocean moderates temp)
		temperature = 23,
		priority = 10
	})

-- KORRIBAN - Ancient Sith tombs, harsh desert/wasteland
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "korriban",
		climate = "ashland", -- sense: barren tomb world / night: ashland (cold nights)
		temperature = 34,
		priority = 10
	})

-- SERENNO - Count Dooku's homeworld, refined but temperate
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "serenno, government district",
		climate = "urban", -- sense: administrative center / night: urban
		temperature = 18,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "serenno, market district",
		climate = "urban", -- sense: commercial area / night: urban
		temperature = 19,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "serenno, slums district",
		climate = "urban", -- sense: poor urban / night: urban (less heat retention)
		temperature = 16,
		priority = 40
	})
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "serenno",
		climate = "temperate", -- sense: aristocratic world / night: temperate
		temperature = 17,
		priority = 10
	})

-- M4-78 - Droid manufacturing planet
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "m4-78",
		climate = "volcanic", -- sense: industrial heat / night: volcanic (machinery warmth)
		temperature = 29,
		priority = 10
	})

-- GAMORR - Gamorrean homeworld, forests and swamps
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "gamorr",
		climate = "tropical", -- sense: humid forests / night: tropical (heat retention)
		temperature = 28,
		priority = 10
	})

-- DATHOMIR - Swamps, forests, witches
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "dathomir",
		climate = "tropical", -- sense: swampy jungle / night: tropical
		temperature = 27,
		priority = 10
	})

-- LOK - Barren, volcanic badlands
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "lok, graveridge",
		climate = "volcanic", -- sense: geothermal activity / night: volcanic
		temperature = 31,
		priority = 10
	})

-- SECRET COW LEVEL - (Diablo crossover!) Pastoral bovine paradise
	table.insert(QUASI_EXTERIOR_CLIMATE_SOURCES, {
		match = "secret cow level",
		climate = "grassland", -- sense: cow pasture / night: grassland
		temperature = 22,
		priority = 20
	})
end

--[[

cells in vanilla + TR with BEHAVES_LIKE_EXTERIOR:

Mournhold, Godsreach
Mournhold, Great Bazaar
Mournhold, Plaza Brindisi Dorom
Mournhold, Royal Palace: Courtyard
Mournhold, Temple Courtyard
T_Test_HF
T_Test_SHOTN
T_Test_TR
T_Test_TR
T_Test_Wolli

starwind:

Taris, Sith Headquarters: Level 2
Hoth, Wasteland
Dantooine, Meditation Site
Taris, Central Plaza: Outpost
The Secret Cow Level
Tatooine, Rodian District
Dantooine, Hunting Grounds
Serenno, Government District
Tatooine, Sand Hole
Dantooine, Estate Grounds
M4-78: Landing Arm
Gamorr, Ucksmug
Dathomir, Exterior
Lok, Graveridge
Taris, Upper City Apartments
Tatooine, Beast's Lair
Tatooine, The Hidden Stash
Taris, Remnants
Dantooine, Sea
Korriban
Taris, Upper City North
Taris
Dantooine
Taris, The Promised Land
Taris, Ruined Plaza: Medical Bay
Tatooine, Sandreach: Northwest Bay
Tatooine, Arena
Taris, Central Plaza: Capital Tower
Tatooine, Sandreach: Northeast Bay
Nar Shaddaa, Obsheeda Plaza
Tatooine, Expanse
Tatooine, Swoop Racetrack
The Outer Rim, Secret Cow Level
Nar Shaddaa, Peyuska Plaza
Taris, Central Plaza
Manaan, Melchior's Reef
Tatooine, Sandreach: South Bay
Taris, Ruined Plaza: Refugee Retreat
Taris, Upper City North: Marketplace
Taris, Sith Headquarters: OC Office
Serenno, Market District
Tatooine, Death Canyon
Taris, Central Plaza: Government Office D
Nar Shaddaa
Taris, Upper City South
Taris, Central Plaza: Government Office B
Tatooine
Dantooine, Valley of the Jedi
Nar Shaddaa, Quanun Alley
Manaan, Bazaar
Dantooine, Ballast
Taris, Ruined Plaza
Taris, Central Plaza: Capital Tower Upper Level
Dantooine, Dantari Wilds
Tatooine, Sandreach
Manaan, Ignatious' Reef
Tatooine, Dune Sea
Manaan, Central
Nar Shaddaa, Makacheesa Market
Taris, Ruined Plaza: Outpost
Tatooine, Sandriver
Taris, Central Plaza: Government Office C
Tatooine, Deep Sea
Taris, Sith Headquarters: Level 3
Serenno, Slums District
Taris, Central Plaza: Government Office A
Taris, Across the Wall

]]