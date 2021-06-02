local soundData = require("Character Sound Overhaul.data")

local this = {}
local tables = {
-- List of textures for footsteps, format: ["subfolder(s) of textures\\texture name with no extension"] = landTypes,
land = soundData.landTable,
-- List of meshes that will be ignored for footsteps, format: ["subfolder(s) of meshes\\mesh.nif"] = "",
ignore = soundData.ignoreList,
-- List of footstep sounds, for new ones, format: ["Sound ID"] = movementTypes,
foot = soundData.footMapping,
-- List of water movement sounds, for new ones, format: ["Sound ID"] = movementTypes,
water = soundData.waterMapping,
-- List of weapon use sounds, for new ones, format: ["Sound ID"] = actionTypes,
weapon = soundData.weaponMapping,
-- List of impact sounds, for new ones, format: ["Sound ID"] = impactTypes,
impact = soundData.impactMapping,
-- List of item use sounds, for new ones, format: ["Sound ID"] = itemTypes,
itemUse = soundData.itemUseMapping,
-- List of objects with specified sounds, for new item types, format: ["subfolder(s) of meshes\\mesh.nif"] = itemTypes,
item = soundData.itemMapping,
-- List of corpse containers to be given open/close sounds, format: ["subfolder(s) of meshes\\mesh.nif"] = "Body",
corpse = soundData.corpseMapping,
-- List of creatures to be given special impact sounds and/or open/close sounds, format: ["subfolder(s) of meshes\\mesh.nif"] = specialTypes,
creature = soundData.creatureTable,
}

this.landTypes = {
	carpet = "Carpet",
	dirt = "Dirt",
	grass = "Grass",
	gravel = "Gravel",
	ice = "Ice",
	metal = "Metal",
	mud = "Mud",
	sand = "Sand",
	snow = "Snow",
	stone = "Stone",
	water = "Water",
	wood = "Wood",
}

this.movementTypes = {
	footLeft = "FootLeft",
	footRight = "FootRight",
	jumpDown = "JumpDown",
}

this.actionTypes = {
	swing = "Swing",
	pull = "Pull",
	shoot = "Shoot",
	sheathe = "Sheathe",
	draw = "Draw",
}

this.impactTypes = {
	flesh = "Flesh",
	hand = "Hand",
	lightArmor = "Armor - Light",
	mediumArmor = "Armor - Medium",
	heavyArmor = "Armor - Heavy",
}

this.itemTypes = {
	book = "Book",
	clothing = "Clothing",
	gems = "Gems",
	generic = "Generic",
	gold = "Gold",
	ingredient = "Ingredient",
	jewelry = "Jewelry",
	lockpick = "Lockpick",
	potions = "Potions",
	repair = "Repair",
	scrolls = "Scrolls",
}

this.specialTypes = {
	metal = "Metal",
	ghost = "Ghost",
}

function this.addSoundData(id, category, soundType)
    tables[soundType][id] = category
    mwse.log("%s added to soundData", id)
end
return this


--[[ 
Format for Mods:
- ID can be for any soundID, mesh filepath, or texture filepath. Must be lowercase.
- Category hooks into the tables above, so the first value will be the name of the desired table, and the second the desired value within it.
	Anything getting added to ignoreList must have an empty category of: ""
	Anything getting added to corpseMapping must have a category of: "Body"
- Define your soundType so it's properly sorted, for instance 'soundType = land' to specify texture material type.


local cso = include("Character Sound Overhaul.interop")
local soundData = {
    { id = "___", category = cso.___.___, soundType = "___" },
}
local function initialized()
    if cso then
        for _, data in ipairs(soundData) do
            cso.addSoundData(data.id, data.category, data.soundType)
        end
    end
end
event.register("initialized", initialized)
]]