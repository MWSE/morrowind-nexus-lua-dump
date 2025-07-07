
I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
MODNAME = "EasySpeechcraft"

local storage = require('openmw.storage')
playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
local settings = require("scripts.EasySpeechcraft_settings")



currentNPC= nil
oldDisposition = nil
oldGold = nil

disableSkillUsedHandler = false

I.SkillProgression.addSkillUsedHandler(function(skillid, params)
	if not currentNPC or not playerSection:get("enabled") then
		return
	end
    if skillid == 'speechcraft' then
		local newDisposition = types.NPC.getBaseDisposition( currentNPC, self)
		local newFight = types.Actor.stats.ai.fight(currentNPC).modified 	


		
		if newDisposition > oldDisposition then
			local goldItem = types.Actor.inventory(self):find('gold_001')
			local goldAmount = goldItem and goldItem.count or 0
			
			if oldGold - goldAmount == 10 then
				if playerSection:get("Bribe10exp") > 0 then
					print("EasySpeechcraft: awarding exp for bribing "..oldGold - goldAmount)
					--temporary_gold_change = temporary_gold_change + 10*BRIBE_MULTIPLIER
					I.SkillProgression.skillUsed('mercantile', {skillGain=playerSection:get("Bribe10exp"), useType = 1, scale = nil})
				end
				if playerSection:get("Dispo10modifier") > 0 then
					minDispositions[currentNPC.id] = (minDispositions[currentNPC.id] or 0) + playerSection:get("Dispo10modifier")
				end
			elseif oldGold - goldAmount == 100 then
				if playerSection:get("Bribe100exp") > 0 then
					print("EasySpeechcraft: awarding exp for bribing "..oldGold - goldAmount)
					--temporary_gold_change = temporary_gold_change + 100*BRIBE_MULTIPLIER
					I.SkillProgression.skillUsed('mercantile', {skillGain=playerSection:get("Bribe100exp"), useType = 1, scale = nil})
				end
				if playerSection:get("Dispo100modifier") > 0 then
					minDispositions[currentNPC.id] = (minDispositions[currentNPC.id] or 0) + playerSection:get("Dispo100modifier")
				end
			elseif oldGold - goldAmount == 1000 then
				if playerSection:get("Dispo1000modifier") > 0 then
					print("EasySpeechcraft: awarding exp for bribing "..oldGold - goldAmount)
					--temporary_gold_change = temporary_gold_change + 1000*BRIBE_MULTIPLIER
					I.SkillProgression.skillUsed('mercantile', {skillGain=playerSection:get("Dispo1000modifier"), useType = 1, scale = nil})
				end
				if playerSection:get("Dispo1000modifier") > 0 then
					minDispositions[currentNPC.id] = (minDispositions[currentNPC.id] or 0) + playerSection:get("Dispo1000modifier")
				end
			else
				if playerSection:get("DispoFlatterModifier") > 0 then
					minDispositions[currentNPC.id] = (minDispositions[currentNPC.id] or 0) + playerSection:get("DispoFlatterModifier")
				end
			--	print("EasySpeechcraft: awarding exp for intimidating/persuading")
			--	I.SkillProgression.skillUsed('mercantile', {skillGain=3, useType = 1, scale = nil})
			end
			
			oldGold = goldAmount
		end
		if newFight <= oldFight then
			local mercantile = types.NPC.stats.skills.mercantile(self).modified*playerSection:get("MercantileDispoMult")
			local speechcraft = types.NPC.stats.skills.speechcraft(self).modified*playerSection:get("SpeechcraftDispoMult")
			local personality = types.NPC.stats.attributes.personality(self).modified*playerSection:get("PersonalityDispoMult")
			local luck = types.NPC.stats.attributes.luck(self).modified*playerSection:get("LuckDispoMult")
			minDisposition = (minDispositions[currentNPC.id] or 0) + speechcraft + personality + luck + mercantile
			
			newDisposition2 = math.max(newDisposition,minDisposition)
			if newDisposition2 > newDisposition then
				print("EasySpeechcraft: setting disposition "..newDisposition.." -> "..newDisposition2.." (min:"..minDisposition..")")
				currentNPC:sendEvent("EasySpeechcraft_setDisposition",{self,math.min(100,newDisposition2)})
			end
			newDisposition = newDisposition2
		else
			print("fight",oldFight,"->",newFight)		
		end
		oldDisposition = newDisposition
		oldFight = newFight
		lastDispositions[currentNPC.id] = newDisposition
    end
end)

local function onFrame(dt)
	--if I.UI.getMode() then
	--
	----if current_vendor_npc then
	----	if not I.UI.getMode() then
	----		current_vendor_npc = nil
	----		return
	----	end
	--	--for detecting bribe
	--	
	--	player_gold_old2 = player_gold_old
	--	local goldItem = types.Actor.inventory(self):find('gold_001')
	--	local goldAmount = goldItem and goldItem.count or 0
	--	--gold changes after barter mode is closed
	--	local now = core.getRealTime()
	--	if I.UI.getMode() == "Barter" then
	--		lastBarterModeTime = now
	--	end
	--	if not player_gold_old then
	--		player_gold_old = goldAmount
	--	elseif goldAmount ~= player_gold_old then
	--		if now - lastBarterModeTime < 0.1 then
	--			temporary_gold_change = temporary_gold_change + math.abs(goldAmount - player_gold_old)
	--		end
	--		player_gold_old = goldAmount
	--	end
	--end
end

--local function FixMerc_NPCActivated (npc)
--	if npc.recordId ~= "scamp_creeper" and npc.recordId ~= "mudcrab_unique" then
--		current_vendor_npc = npc
--	end
--
--end

local function UiModeChanged(data)
	if not playerSection:get("enabled") then
		currentNPC = nil
		return
	end
	--print("uimodeChanged",data.oldMode,data.newMode,data.arg)
	if data.newMode == "Barter" or data.oldMode == "Barter" then --going back from barter, arg is nil?
		return
	end
	if data.newMode == "Dialogue" and data.arg and types.NPC.objectIsInstance(data.arg) and not currentNPC then
		currentNPC = data.arg
		
		local goldItem = types.Actor.inventory(self):find('gold_001')
		local goldAmount = goldItem and goldItem.count or 0
		oldGold = goldAmount
		oldFight = types.Actor.stats.ai.fight(currentNPC).modified 	
			local mercantile = types.NPC.stats.skills.mercantile(self).modified*playerSection:get("MercantileDispoMult")
			local speechcraft = types.NPC.stats.skills.speechcraft(self).modified*playerSection:get("SpeechcraftDispoMult")
			local personality = types.NPC.stats.attributes.personality(self).modified*playerSection:get("PersonalityDispoMult")
			local luck = types.NPC.stats.attributes.luck(self).modified*playerSection:get("LuckDispoMult")
			minDisposition = (minDispositions[currentNPC.id] or 0) + speechcraft + personality + luck + mercantile
		
		oldDisposition = types.NPC.getDisposition( currentNPC, self)
		if lastDispositions[currentNPC.id] then
			print("EasySpeechcraft: setting disposition "..oldDisposition.." -> "..math.min(100,lastDispositions[currentNPC.id]).." (last value)")
			currentNPC:sendEvent("EasySpeechcraft_setDisposition",{self,math.min(100,lastDispositions[currentNPC.id])})
			oldDisposition = lastDispositions[currentNPC.id]
		elseif minDisposition > oldDisposition then
			print("EasySpeechcraft: setting disposition "..oldDisposition.." -> "..minDisposition.." (min)")
			currentNPC:sendEvent("EasySpeechcraft_setDisposition",{self,math.min(100,minDisposition)})
			oldDisposition = minDisposition
		end
		
	elseif not data.newMode then
		currentNPC = nil
	end
end

local function onLoad(data)
	if data then
		minDispositions = data.minDispositions or {}
		lastDispositions = data.lastDispositions or {}
	else
		minDispositions = {}
		lastDispositions = {}
	end
end

local function onSave()
    return {
        minDispositions = minDispositions,
        lastDispositions = lastDispositions
    }
end


return {
	engineHandlers = { 
		onFrame = onFrame,
		onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
	}
}