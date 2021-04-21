-- Blood Diversity
local defaultConfig = {
	modEnabled = true,
	arcticBlood = 5,
	ashCreatureBlood = 1,
	crustaceanBlood = 5,
	corprusBlood = 0,
	dwemerBlood = 2,
	daedraBlood = 3,
	elementalBlood = 7,
	fabricantBlood = 2,
	fishBlood = 0,
	ghostBlood = 4,
	goblinBlood = 0,
	insectBlood = 6,
	kwamaBlood = 6,
	mammalBlood = 0,
	netchBlood = 5,
	reptileBlood = 0,
	skeletalBlood = 1,
	specialBlood = 7,
	undeadBlood = 0,
	vampireBlood = 1,
}

local config = mwse.loadConfig("Blood Diversity", defaultConfig)

-- For vampirism we'll use the spell tick event to remove/add as needed.
local function onVampirismTick(e)
	if config.modEnabled then
		local object = e.target.object
		if (e.sourceInstance.state == tes3.spellState.ending) then
			return
		else
			object.blood = config.vampireBlood
		end
	end
end

local function onGhostTick(e)
	if config.modEnabled and config.ghostBlood then
		local object = e.target.object
		if (e.sourceInstance.state == tes3.spellState.ending) then
			return
		else
			object.blood = config.ghostBlood
		end
	end
end

local function onInitialized(e)
	-- Our data doesn't need to be global. It can be garbage collected 
	local data = require("Blood Diversity.data")

	-- For creatures, we only need to do this once at the start.
	if config.modEnabled then
		for object in tes3.iterateObjects(tes3.objectType.creature) do
			local arctic = data.arcticBlood[object.mesh:lower()]
			local ash = data.ashBlood[object.mesh:lower()]
			local crustacean = data.crustaceanBlood[object.mesh:lower()]
			local corprus = data.corprusBlood[object.mesh:lower()]
			local dwemer = data.dwemerBlood[object.mesh:lower()]
			local daedra = data.daedraBlood[object.mesh:lower()]
			local elemental = data.elementalBlood[object.mesh:lower()]
			local fabricant = data.fabricantBlood[object.mesh:lower()]
			local fish = data.fishBlood[object.mesh:lower()]
			local ghost = data.ghostBlood[object.mesh:lower()]
			local goblin = data.goblinBlood[object.mesh:lower()]
			local insect = data.insectBlood[object.mesh:lower()]
			local kwama = data.kwamaBlood[object.mesh:lower()]
			local mammal = data.mammalBlood[object.mesh:lower()]
			local netch = data.netchBlood[object.mesh:lower()]
			local reptile = data.reptileBlood[object.mesh:lower()]
			local skeletal = data.skeletalBlood[object.mesh:lower()]
			local special = data.specialBlood[object.mesh:lower()]
			local undead = data.undeadBlood[object.mesh:lower()]
			if (arctic) then
				object.blood = config.arcticBlood
			elseif (ash) then
				object.blood = config.ashCreatureBlood
			elseif (crustacean) then
				object.blood = config.crustaceanBlood
			elseif (corprus) then
				object.blood = config.corprusBlood
			elseif (dwemer) then
				object.blood = config.dwemerBlood
			elseif (daedra) then
				object.blood = config.daedraBlood
			elseif (elemental) then
				object.blood = config.elementalBlood
			elseif (fabricant) then
				object.blood = config.fabricantBlood
			elseif (fish) then
				object.blood = config.fishBlood
			elseif (ghost) then
				object.blood = config.ghostBlood
			elseif (goblin) then
				object.blood = config.goblinBlood
			elseif (insect) then
				object.blood = config.insectBlood
			elseif (kwama) then
				object.blood = config.kwamaBlood
			elseif (mammal) then
				object.blood = config.mammalBlood
			elseif (netch) then
				object.blood = config.netchBlood
			elseif (reptile) then
				object.blood = config.reptileBlood
			elseif (skeletal) then
				object.blood = config.skeletalBlood
			elseif (special) then
				object.blood = config.specialBlood
			elseif (undead) then
				object.blood = config.undeadBlood
			end
		end
	end

	-- Handle vampires.
	event.register("spellTick", onVampirismTick, { filter = tes3.getObject("vampire attributes") })
	-- Handle Ghost NPCs.
	event.register("spellTick", onGhostTick, { filter = tes3.getObject("ghost ability") })

	mwse.log("Initialized Blood Diversity")
end
event.register("initialized", onInitialized)

-- MCM

local function registerMCM()
	local template = mwse.mcm.createTemplate("Blood Diversity")
	template.onClose = function(self)
		mwse.saveConfig("Blood Diversity", config)
		onInitialized(e)
	end
	
	local page = template:createSideBarPage()
	page.label = "Settings"
	page.description = "Blood Diversity\n\nBlood Diversity provides new blood types for the creatures of Morrowind, Tribunal, Bloodmoon, the Official Plugins, and a variety of mods based on real-world and lore considerations."
	page.noScroll = false
	
	local category = page:createCategory("")
	
	local enableButton = category:createOnOffButton({
		label = "Enable Blood Diversity",
		description = "Enable Blood Diversity\n\nDetermines whether the mod is enabled and enemy blood types are altered.\n\nDefault: On",
		variable = mwse.mcm:createTableVariable{id = "modEnabled", table = config},
	})
	
	local arcticCreaturesDropdown = category:createDropdown({
		label = "Arctic Creatures",
		description = "Arctic Creatures\n\nDetermines the blood type for northerly creatures such as Rieklings, Grahl, and Karstaag.\n\nDefault: Blue Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "arcticBlood", table = config}
	})
	
	local arcticCreaturesDropdown = category:createDropdown({
		label = "Ash Creatures",
		description = "Ash Creatures\n\nDetermines the blood type for devoted creatures of the Sixth House such as Ash Zombies and Ascended Sleepers.\n\nDefault: Grey Dust",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "ashCreatureBlood", table = config}
	})
	
	local crustaceanDropdown = category:createDropdown({
		label = "Crustacean Creatures",
		description = "Crustacean Creatures\n\nDetermines the blood type for aquatic creatures such as Mudcrabs and Dreugh.\n\nDefault: Blue Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "crustaceanBlood", table = config}
	})
	
	local corprusDropdown = category:createDropdown({
		label = "Corprus Victims",
		description = "Corprus Victims\n\nDetermines the blood type for creatures inflicted with the divine disease such as Corprus Stalkers and Yagrum Bagarn.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "corprusBlood", table = config}
	})
	
	local dwemerDropdown = category:createDropdown({
		label = "Dwemer Constructs",
		description = "Dwemer Constructs\n\nDetermines the blood type for dwarven animunculi such as the Centurion Sphere and Steam Centurion.\n\nDefault: Gold Sparks",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "dwemerBlood", table = config}
	})
	
	local daedraDropdown = category:createDropdown({
		label = "Daedra",
		description = "Daedra\n\nDetermines the blood type for creatures of Oblivion such as Dremora and Scamps.\n\nDefault: Black Ichor",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "daedraBlood", table = config}
	})
	
	local elementalDropdown = category:createDropdown({
		label = "Elemental Creatures",
		description = "Elemental Creatures\n\nDetermines the blood type for creatures with natural properties such as Atronachs and Spriggans.\n\nDefault: Elemental Energy",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "elementalBlood", table = config}
	})
	
	local fabricantDropdown = category:createDropdown({
		label = "Fabricants",
		description = "Fabricants\n\nDetermines the blood type for the animunculi of Sotha Sil.\n\nDefault: Gold Sparks",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "fabricantBlood", table = config}
	})
	
	local fishDropdown = category:createDropdown({
		label = "Fish",
		description = "Fish\n\nDetermines the blood type for aquatic creatures such as Slaughterfish.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "fishBlood", table = config}
	})
	
	local ghostDropdown = category:createDropdown({
		label = "Ghosts",
		description = "Ghosts\n\nDetermines the blood type for undead creatures such as Ancestral Ghosts as well as NPC ghosts.\n\nDefault: Green Ectoplasm",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "ghostBlood", table = config}
	})
	
	local goblinDropdown = category:createDropdown({
		label = "Goblins",
		description = "Goblins\n\nDetermines the blood type for Malacath-associated creatures such as Goblins.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "goblinBlood", table = config}
	})
	
	local insectDropdown = category:createDropdown({
		label = "Insects",
		description = "Insects\n\nDetermines the blood type for insectoid creatures such as the Nix-Hound and Shalk.\n\nDefault: Orange Hemolymph",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "insectBlood", table = config}
	})
	
	local kwamaDropdown = category:createDropdown({
		label = "Kwama",
		description = "Kwama\n\nDetermines the blood type for Kwama forms such as the Kwama Warrior and Scrib.\n\nDefault: Orange Hemolymph",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "kwamaBlood", table = config}
	})
	
	local mammalDropdown = category:createDropdown({
		label = "Mammals",
		description = "Mammals\n\nDetermines the blood type for mammalian beasts such as Bears and Wolves.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "mammalBlood", table = config}
	})
	
	local netchDropdown = category:createDropdown({
		label = "Netch",
		description = "Netch\n\nDetermines the blood type for Bull and Betty Netches.\n\nDefault: Blue Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "netchBlood", table = config}
	})
	
	local reptilsDropdown = category:createDropdown({
		label = "Reptiles",
		description = "Reptiles\n\nDetermines the blood type for reptilian beasts such as the Guar and Kagouti.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "reptileBlood", table = config}
	})
	
	local skeletalDropdown = category:createDropdown({
		label = "Skeletal Creatures",
		description = "Skeletal Creatures\n\nDetermines the blood type for undead creatures such as the Lich and Skeleton.\n\nDefault: Grey Dust",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "skeletalBlood", table = config}
	})
	
	local specialDropdown = category:createDropdown({
		label = "Special Creatures",
		description = "Special Creatures\n\nDetermines the blood type for creatures touched by the divine such as Dagoth Ur and Vivec.\n\nDefault: Elemental Energy",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "specialBlood", table = config}
	})
	
	local undeadDropdown = category:createDropdown({
		label = "Undead Creatures",
		description = "Undead Creatures\n\nDetermines the blood type for zombie-like undead such as the Bonewalkers and Bonewolves.\n\nDefault: Red Blood",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "undeadBlood", table = config}
	})
	local vampireDropdown = category:createDropdown({
		label = "Vampires",
		description = "Vampires\n\nDetermines the blood type for NPCs infected with vampirism.\n\nDefault: Grey Dust",
		options = {
			{label = "Red Blood", value = 0},
			{label = "Grey Dust", value = 1},
			{label = "Gold Sparks", value = 2},
			{label = "Black Ichor", value = 3},
			{label = "Green Ectoplasm", value = 4},
			{label = "Blue Blood", value = 5},
			{label = "Orange Hemolymph ", value = 6},
			{label = "Elemental Energy", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "vampireBlood", table = config}
	})
	
	mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)