local world = require('openmw.world')
local cellData = require("scripts.quest_guider_lite.core.cellData")

local this = {}

this.skillName = {
	[0] = "Block",
	[1] = "Armorer",
	[2] = "Medium Armor",
	[3] = "Heavy Armor",
	[4] = "Blunt Weapon",
	[5] = "Long Blade",
	[6] = "Axe",
	[7] = "Spear",
	[8] = "Athletics",
	[9] = "Enchant",
	[10] = "Destruction",
	[11] = "Alteration",
	[12] = "Illusion",
	[13] = "Conjuration",
	[14] = "Mysticism",
	[15] = "Restoration",
	[16] = "Alchemy",
	[17] = "Unarmored",
	[18] = "Security",
	[19] = "Sneak",
	[20] = "Acrobatics",
	[21] = "Light Armor",
	[22] = "Short Blade",
	[23] = "Marksman",
	[24] = "Mercantile",
	[25] = "Speechcraft",
	[26] = "Hand to Hand"
}

this.attributeName = {
	[0] = "strength",
	[1] = "intelligence",
	[2] = "willpower",
	[3] = "agility",
	[4] = "speed",
	[5] = "endurance",
	[6] = "personality",
	[7] = "luck",
}

this.weather = {
	["clear"] = 0,
	["cloudy"] = 1,
	["foggy"] = 2,
	["overcast"] = 3,
	["rain"] = 4,
	["thunder"] = 5,
	["ash"] = 6,
	["blight"] = 7,
	["snow"] = 8,
	["blizzard"] = 9,
}


this.getObject = require("scripts.quest_guider_lite.core.getObject")


---@param id integer
---@return {name : string}
function this.getMagicEffect(id)
    return {name = string.format("magic effect: %d", id)}
end


---@param id string
---@return {name : string}
function this.findClass(id)
    return {name = string.format("class: %s", id)}
end


---@param params {topic : string}
---@return nil
function this.findDialogue(params)
	return nil
end


---@param id string
---@return nil
function this.getScript(id)
	return nil
end


---@param params {id : string?, name : string?, position : tes3vector3?, x : integer?, y : integer?}
function this.getCell(params)
	local func = function ()
		local cell
		if params.id then
			cell = world.getCellById(params.id)
		elseif params.name then
			cell = world.getCellByName(params.name)
		elseif params.position then
			local x = math.floor(params.position.x / 8192)
			local y = math.floor(params.position.y / 8192)
			cell = world.getExteriorCell(x, y)
		elseif params.x and params.y then
			cell = world.getExteriorCell(params.x, params.y)
		end

		return cell
	end

	local success, res = pcall(func)

	return success and res or nil
end


this.getCellData = cellData.getCellData


return this