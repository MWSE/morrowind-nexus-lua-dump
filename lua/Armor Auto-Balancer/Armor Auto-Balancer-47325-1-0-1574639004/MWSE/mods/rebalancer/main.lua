--[[
	Armor_AutoRebalance.esp
	by Siltocyn
--]]
local DEBUG = false

local function round_multi(val, roundTo) -- round to nearest x place
	return (val - roundTo * 0.5) + (roundTo - ((val + roundTo * 0.5) % roundTo));
end

local function clean_round(value) -- rounds to a clean looking value
	if value < 90 then return math.round(value)
	elseif value < 450 then return round_multi(value, 10);
	elseif value < 900 then return round_multi(value, 50);
	elseif value < 4500 then return round_multi(value, 100);
	elseif value < 10000 then return round_multi(value, 500);
	else return round_multi(value, 1000); end
end

-- adjust gmsts to account for new armor weights
local function set_gmsts(arm_slot)
	-- multipliers
	tes3.findGMST(996).value = 0.59 -- fLightMaxMod: light armor
	tes3.findGMST(997).value = 1.45 -- fMedMaxMod: medium armor
	-- base weight for each armor arm_slot
	tes3.findGMST(989).value = arm_slot[0][1] -- iHelmWeight: helm
	tes3.findGMST(990).value = arm_slot[2][1] -- iPauldronWeight: pauldron
	tes3.findGMST(991).value = arm_slot[1][1] -- iCuirassWeight: cuirass
	tes3.findGMST(992).value = arm_slot[6][1] -- iGauntletWeight: gauntlet
	tes3.findGMST(993).value = arm_slot[4][1] -- iGreavesWeight: greaves
	tes3.findGMST(994).value = arm_slot[5][1] -- iBootsWeight: boots
	tes3.findGMST(995).value = arm_slot[8][1] -- iShieldWeight: shield
end

-- determine material of armor using id or mesh path
local function find_material(armor, data, seq)
	local str
	for _, material in ipairs(seq) do -- search by mesh & id
		str = string.byte(material) ~= 95 and material:lower() or string.sub(material:lower(), 2)
		if (string.find(armor.mesh:lower(), str) ~= nil) or (string.find(armor.id:lower(), str) ~= nil) then 
		return material end
	end
end

-- calculate new values for armor piece
local function rebalance(armor, material, data)
	local prev, str
	local mat = material
	material = data[material]
	-- check if slot exists
	if data.arm_slot[armor.slot] == nil then
		if (DEBUG) then mwse.log("________________________________________\n" .. armor.name .. "        " .. mat ..
		"\n unknown slot: " .. data.arm_slot[armor.slot]) end -- DEBUG
		return
	end
	if (DEBUG) then -- store old values
		prev = "\nOLD  || w " .. math.round(armor.weight) .. " -- v " .. math.round(armor.value) .. " -- ec " .. math.round(armor.enchantCapacity) .. " -- mc " .. math.round(armor.maxCondition) .. " -- ar " .. math.round(armor.armorRating)
	end
	
	-- apply new values
	if type(material[1]) == "table" then mwse.log(material[1][1]) end
	armor.weight = math.round(data.arm_slot[armor.slot][1] * material[1]) -- weight
	armor.maxCondition = math.round(data.arm_slot[armor.slot][4] * material[4]) -- max condition
	if (string.find(armor.mesh:lower(), "towershield") ~= nil) then armor.armorRating = math.round(data.arm_slot[armor.slot][5] * (material[5] * 1.1)) -- tower shields 10% more AR than shields
	else armor.armorRating =math.round(data.arm_slot[armor.slot][5] * material[5]) end -- armor rating
	-- check if enchanted and marked as such
	if (armor.enchantment == nil) or (material[6] ~= nil) then -- NOT enchanted
		armor.enchantCapacity = math.ceil(data.arm_slot[armor.slot][3] * material[3]) -- enchant capacity
		armor.value = clean_round(data.arm_slot[armor.slot][2] * material[2]) -- value
		if (DEBUG) and (armor.enchantment ~= nil) then str = "[E] " end -- DEBUG - enchanted and marked
	else -- enchanted: ignore value, ignore enchant cap if it would be lowered
		if (DEBUG) then str = "[!E] " end -- DEBUG - enchanted but not marked
		armor.enchantCapacity = math.max(armor.enchantCapacity, math.round(data.arm_slot[armor.slot][3] * material[3]))
	end
	if (DEBUG) then -- log value changes
		str = "________________________________________\n" .. (str or "") .. armor.name .. "        " .. mat  .. "\n" .. armor.id .. "        " .. armor.mesh .. "        " .. armor.slot -- header
		str = str .. prev -- old values
		str = str .. "\nNEW || w " .. math.round(armor.weight) .. " -- v " .. math.round(armor.value) .. " -- ec " .. math.round(armor.enchantCapacity) .. " -- mc " .. math.round(armor.maxCondition) .. " -- ar " .. math.round(armor.armorRating) -- new values
		mwse.log(str)
	end
end

-- parse through data table and apply new values to armor
local function parse_data(data)
	mwse.log("beginning armor rebalance...")
	local material
	-- create ordered sequence for data table
	-- prevents detecting generic names over specific names (e.g. indoril before indoril_almalexia)
	local seq = {}
	for k in pairs(data) do
		seq[#seq + 1] = k
	end
	local sort_func = function( a,b ) return a > b end
	table.sort( seq, sort_func )
	-- iterate through all armor objects
	for armor in tes3.iterateObjects(tes3.objectType.armor) do
		-- compare armor id with materials in table
		material = find_material(armor, data, seq)
		if (material ~= nil) and (data[material] ~= nil) then -- material of armor found, rebalance
			rebalance(armor, material, data)
		elseif (DEBUG) then mwse.log("________________________________________\n " .. armor.name .. ": armor data not found! \n id: " .. armor.id .. "        mesh: " .. armor.mesh) end -- DEBUG
	end
	mwse.log("armor rebalance complete!")
end

-- INITIALIZATION
function initialized(e)
	local data = require("rebalancer.data");
	-- parse through data, applying new armor values
	mwse.log("Initialized Armor AutoBalancer v1.0")
	parse_data(data)
	set_gmsts(data.arm_slot)
end
event.register("initialized", initialized)
