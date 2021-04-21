local config = require("OEA.OEA8 Craft.config")
local H = {}

local lMod
local aMod
local iMod
local KeyTimeShift
local KeyTimeCtrl
local WorldTime
local AlchemyTime

local function ItemUpdate(e)
	local Append = " Potion"

	if (tes3.player.data.OEA8 == nil) then
		tes3.player.data.OEA8 = {}
	end

	if (config.Excise == false) then
		if (tes3.player.data.OEA8[e.item.id] ~= nil) then
			if (e.item.objectType == tes3.objectType.alchemy) then
				e.item.name = ("%s%s"):format(e.item.name, Append)
				tes3.player.data.OEA8[e.item.id] = nil
			end
		end
		return
	end

	local Length = string.len(e.item.name)

	if (e.item.objectType == tes3.objectType.alchemy) then
		if (string.sub(e.item.name, Length - 6, Length) == Append) then
			e.item.name = string.sub(e.item.name, 1, Length - 7)
			tes3.player.data.OEA8[e.item.id] = 1
		end
	end
end

local function OnPotion(e)
	if (config.SkillBuff == false) then
		return
	end

	for i=1, 8 do
		local effect = e.object.effects[i+1]
		if (not effect) or (effect.id == -1) then
			if (i > 1) then
				local skills = tes3.dataHandler.nonDynamicData.skills
				tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, skills[tes3.skill.alchemy + 1].actions[1] * (i-1) * (1 / 7))
			end
			break
		end
	end
end

local function AlchemyEnter(e)
	AlchemyTime = 1

	if (config.StatChange == true) then
		iMod = tes3.mobilePlayer.intelligence.base - tes3.mobilePlayer.intelligence.current
		lMod = tes3.mobilePlayer.luck.base - tes3.mobilePlayer.luck.current
		aMod = tes3.mobilePlayer.alchemy.base - tes3.mobilePlayer.alchemy.current

		if (iMod > 0) then
			iMod = 0
		end
		if (lMod > 0) then
			lMod = 0
		end
		if (aMod > 0) then
			aMod = 0
		end

		tes3.modStatistic({ reference = tes3.mobilePlayer, attribute = tes3.attribute.intelligence, value = iMod })
		tes3.modStatistic({ reference = tes3.mobilePlayer, attribute = tes3.attribute.luck, value = lMod })
		tes3.modStatistic({ reference = tes3.mobilePlayer, skill = tes3.skill.alchemy, value = aMod })
	end
end

local function MenuExit(e)
	AlchemyTime = 0

	if (aMod ~= nil) and (lMod ~= nil) and (iMod ~= nil) then
		tes3.modStatistic({ reference = tes3.mobilePlayer, attribute = tes3.attribute.intelligence, value = (0 - iMod) })
		tes3.modStatistic({ reference = tes3.mobilePlayer, attribute = tes3.attribute.luck, value = (0 - lMod) })
		tes3.modStatistic({ reference = tes3.mobilePlayer, skill = tes3.skill.alchemy, value = (0 - aMod) })
		aMod = nil
		lMod = nil
		iMod = nil
	end

	if (WorldTime ~= nil) then
		for i, apparatus in ipairs(WorldTime) do
			mwscript.removeItem({ reference = tes3.player, item = apparatus, count = 1 })
		end	
		WorldTime = nil
	end
end

local function KeyPress(e)
	if (e.keyCode == tes3.scanCode.leftShift) or (e.keyCode == tes3.scanCode.rightShift) then
		KeyTimeShift = 1
	end

	if (e.keyCode == tes3.scanCode.leftCtrl) or (e.keyCode == tes3.scanCode.rightCtrl) then
		KeyTimeCtrl = 1
	end
end

local function KeyRelease(e)
	if (e.keyCode == tes3.scanCode.leftShift) or (e.keyCode == tes3.scanCode.rightShift) then
		KeyTimeShift = 0
	end

	if (e.keyCode == tes3.scanCode.leftCtrl) or (e.keyCode == tes3.scanCode.rightCtrl) then
		KeyTimeCtrl = 0

		if (tes3.menuMode() == true) or ((AlchemyTime ~= nil) and (AlchemyTime == 1)) then
			tes3.player.data.OEA8.ApparatusList = nil
			WorldTime = nil	
			return
		end
		if (tes3.player.data.OEA8.ApparatusList == nil) then
			return
		end

		WorldTime = {}
		local Length = table.size(tes3.player.data.OEA8.ApparatusList)
		for i, apparatus in ipairs(tes3.player.data.OEA8.ApparatusList) do
			table.insert(WorldTime, apparatus)
			mwscript.addItem({ reference = tes3.player, item = apparatus, count = 1 })
			if (i == Length) then
				mwscript.equip({ reference = tes3.player, item = apparatus })
			end
		end
		tes3.player.data.OEA8.ApparatusList = nil			
	end
end


local function OnActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end

	if (AlchemyTime ~= nil) and (AlchemyTime == 1) then
		return false
	end

	if (e.target.baseObject.objectType ~= tes3.objectType.apparatus) then
		return
	end

	if (tes3.mobilePlayer.isSneaking == true) and ((KeyTimeCtrl == nil) or (KeyTimeCtrl == 0)) then
		return
	end

	if (config.World == false) then
		return
	end

	if (KeyTimeCtrl == nil) or (KeyTimeCtrl == 0) then
		if (KeyTimeShift ~= nil) and (KeyTimeShift == 1) then
			return
		end
		if (tes3.getOwner({ reference = e.target }) ~= nil) then
			tes3.triggerCrime({ 
				type = tes3.crimeType.theft, 
				value = (tes3.findGMST("fCrimeStealing").value * e.target.object.value),
				victim = tes3.getOwner({ reference = e.target })
			})
		end
		WorldTime = { [1] = e.target.baseObject.id }
		mwscript.addItem({ reference = tes3.player, item = e.target.baseObject.id, count = 1 })
		mwscript.equip({ reference = tes3.player, item = e.target.baseObject.id })
		return false
	elseif (KeyTimeCtrl ~= nil) and (KeyTimeCtrl == 1) then
		if (tes3.getOwner({ reference = e.target }) ~= nil) then
			tes3.triggerCrime({ 
				type = tes3.crimeType.theft, 
				value = (tes3.findGMST("fCrimeStealing").value * e.target.object.value),
				victim = tes3.getOwner({ reference = e.target })
			})
		end
		if (tes3.player.data.OEA8 == nil) then
			tes3.player.data.OEA8 = {}
		end
		if (tes3.player.data.OEA8.ApparatusList == nil) then
			tes3.player.data.OEA8.ApparatusList = {}
		end
		table.insert(tes3.player.data.OEA8.ApparatusList, e.target.baseObject.id)
		return false		
	end
end

event.register("uiActivated", AlchemyEnter, { filter = "MenuAlchemy" }, { priority = 10000 })
event.register("menuExit", MenuExit)
event.register("potionBrewed", OnPotion)
event.register("activate", OnActivate)
event.register("keyDown", KeyPress)
event.register("keyUp", KeyRelease)
event.register("itemTileUpdated", ItemUpdate)