local soulGemLib = {}
local sephInterop = require("seph.npcSoulTrapping.interop")

soulGemLib.table = {
	["Misc_SoulGem_Petty"] = true,
	["Misc_SoulGem_Lesser"] = true,
	["Misc_SoulGem_Common"] = true,
	["Misc_SoulGem_Greater"] = true,
	["Misc_SoulGem_Grand"] = true,
	["Misc_SoulGem_Azura"] = true
}

soulGemLib.blackSoulCreature = {
	["worm lord"] = true,
	lich = true,
	lich_relvel = true,
	lich_barilzar = true,
	lich_profane_unique = true
}

-- soulGemLib.dummySouls = {
-- }

--[[
    Wrapper around tes3.addSoulGem()
	Registers a custom soulGemLib into the framework
	If params.default is set to false, default soul capture will be prevented
]]

soulGemLib.register = function(params)
	if params.default == false then
		soulGemLib.table[params.gem] = false
	else
		soulGemLib.table[params.gem] = true
	end
	tes3.addSoulGem{item=params.gem}
end

-- soulGemLib.addExtraData = function(params)
-- 	local gem = params.gem
-- 	local soul = params.soul
-- 	local data = params.data
-- 	local inventory = params.reference.inventory or params.reference.object.inventory
-- 	for _, stack in pairs(inventory) do
-- 		if stack.object.id == gem or (not gem and soulGemLib.table[stack.object.id] ~= nil) then
-- 			if stack.variables and stack.variables[1].soul then
-- 				for i = 1, #stack.variables do
-- 					if stack.variables[i].soul == soul and not stack.variables[i].data.soulGemLib then
-- 						stack.variables[i].data = data
-- 						return true
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end


soulGemLib.getData = function(params)
	local gem = params.gem
	local soul = params.soul
	local value = params.value
	local inventory = params.reference.inventory or params.reference.object.inventory
	if type(soul) == "string" then
		soul = tes3.getObject(soul)
	end
	for _, stack in pairs(inventory) do
		if stack.object.id == gem or (not gem and soulGemLib.table[stack.object.id] ~= nil) then
			if stack.variables and stack.variables[1].soul then
				if not soul and not value then
					return {gem=stack.object.id, itemData=stack.variables[1]}
				else
					for i = 1, #stack.variables do
						if soul then
							if stack.variables[i].soul == soul then
								return {gem=stack.object.id, itemData=stack.variables[i]}
							end
						elseif stack.variables[i].soul.soul == value then
							return {gem=stack.object.id, itemData=stack.variables[i]}
						end
					end
				end
			end
		end
	end
end

soulGemLib.countEmpty = function(params)
	if not params.reference then return 0 end
	local gem = params.gem
	local inventory = params.reference.object.inventory
	for _, stack in pairs(inventory) do
		if stack.object.id == gem then
			if not stack.variables then
				return stack.count
			elseif stack.count > #stack.variables then
				return stack.count - #stack.variables
			end
		end
	end
	return 0
end

--[[
    Capture a soul of an actor to a specified gem
]]

soulGemLib.captureSoul = function(params)
	local reference = params.reference
	local position = params.position
	local gem = params.gem
	local soul = params.soul
	local text = params.text
	if not soulGemLib.countEmpty{reference=reference, gem=gem} then return false end
	if type(soul) == "string" then
		soul = tes3.getObject(soul)
	end
	tes3.removeItem{reference = reference, item = gem, count = 1, playSound = false}
	tes3.addItem{reference = tes3.player, item = gem, soul = soul, playSound = false}
	if position then
		tes3.createVisualEffect{
			effect = "VFX_Soul_Trap",
			position = position,
			repeatCount = 1
		}
	end
	if text then
		tes3.messageBox(tes3.findGMST(tes3.gmst.sSoultrapSuccess).value)
	end
end

soulGemLib.releaseSoul = function(params)
	local reference = params.reference
	local position = params.position
	local gem = params.gem
	local soul = params.soul
	local value = params.value
	local restoreGem = params.restoreGem
	local inventory = params.reference.inventory or params.reference.object.inventory
	local data = soulGemLib.getData(params)
	if not data then
		return false
	end
	local itemData = data.itemData
	if not gem then 
		gem = data.gem 
	end
	if not itemData or not itemData.data then
		return false
	end
	if restoreGem == nil and ( gem == "Misc_SoulGem_Azura" or gem == "NC_SoulGem_AzuraB" ) then
		restoreGem = true
	end
	data = itemData.data
	tes3.transferItem{from = reference.id, to = "todd", item = gem, itemData = itemData, count = 1, playSound = false, limitCapacity = false}
	if restoreGem then
		tes3.addItem{reference = reference, item = gem, count = 1, playSound = false}
	end
	return itemData
end

local function onTooltipDrawn(e)
	if not e.itemData or not e.itemData.data.soulGemLib then
		return
	end
	local child = e.tooltip:findChild(-1216)
	child.text = string.gsub(child.text, "%(.*%)", "("..e.itemData.data.soulGemLib.name..")")
end

-- local function preventDefaultCapture(e)
-- 	if tes3.menuMode() then return end
-- 	if soulGemLib.blackSoulCreature[e.actor.id] then
-- 		e.value = 0
-- 		return false
-- 	end
-- 	for gem, default in pairs(soulGemLib.table) do
-- 		if default == false then
-- 			local count = soulGemLib.countEmpty{reference = tes3.player, gem = gem}
-- 			if count > 0 then
-- 				tes3.removeItem{reference=tes3.player, item=gem, count = count, playSound=false}
-- 				timer.start{
-- 					duration = 0.1,
-- 					callback = function()
-- 						tes3.addItem{reference=tes3.player, item=gem, count = count, playSound=false}
-- 					end
-- 				}
-- 			end
-- 		end
-- 	end
-- end

-- local function initDummySouls()
-- 	n = 0
-- 	while n < 16 do
-- 		value = 100 + n*50
-- 		soulGemLib.dummySouls[value] = "NC_Soul"..tostring(n)
-- 		n = n + 1
-- 	end
-- end

local function restoreBlackAzura(e)
	local azuraBlackCount  = tes3.getItemCount{ reference = tes3.player, item = "NC_SoulGem_AzuraB" }
	timer.delayOneFrame(function()
		if tes3.getItemCount{ reference = tes3.player, item = "NC_SoulGem_AzuraB" } < azuraBlackCount then
			tes3.addItem{reference=tes3.player, item="NC_SoulGem_AzuraB"} 
		end
	end)
end

local function onMenuEnchantment(e)
	local button = e.element:findChild("MenuEnchantment_Buybutton")
	button:registerBefore("mouseClick", restoreBlackAzura)
end

local function onMenuInventorySelect(e)
	local azuraBlack = tes3.getObject("NC_SoulGem_AzuraB")
	local scrollpane = e.element:findChild("MenuInventorySelect_scrollpane")
	scrollpane = scrollpane:findChild("PartScrollPane_pane")
	for _, block in pairs(scrollpane.children) do
		local item =  block:findChild("MenuInventorySelect_item_brick")
		if item.text == azuraBlack.name then
			block:registerBefore("mouseClick", restoreBlackAzura)
		end
	end
end

local function onInitialized(e)
	for creatureID, _ in pairs(soulGemLib.blackSoulCreature) do
		sephInterop.addCreatureException(creatureID)
	end
	sephInterop.addBlackSoulGem("nc_soulgem_azurab")
end



--event.register("uiObjectTooltip", onTooltipDrawn)
--event.register("calcSoulValue", preventDefaultCapture)
event.register("uiActivated", onMenuInventorySelect, { filter = "MenuInventorySelect" })
event.register("uiActivated", onMenuEnchantment, { filter = "MenuEnchantment" })
event.register("initialized", onInitialized)

return soulGemLib