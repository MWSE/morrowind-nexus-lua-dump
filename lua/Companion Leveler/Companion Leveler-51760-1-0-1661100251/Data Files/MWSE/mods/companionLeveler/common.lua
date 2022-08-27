local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")


local this = {}


----Mod Data------------------------------------------------------------------------------------------------------------------
function this.getModData(npcRef)
    log = logger.getLogger("Companion Leveler")
	log:trace("Checking saved Mod Data.")
    if not npcRef.data.companionLeveler then
		if npcRef.object.objectType ~= tes3.objectType.creature then
			log:info("NPC Mod Data not found, setting to base Mod Data values.")
        	npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["class"] = npcRef.object.class.name, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } }
		else
			if npcRef.object.type == 0 then
				log:info("Normal type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Normal", ["norlevel"] = npcRef.object.level, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if npcRef.object.type == 1 then
				log:info("Daedra type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Daedra", ["norlevel"] = 1, ["daelevel"] = npcRef.object.level, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if npcRef.object.type == 2 then
				log:info("Undead type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Undead", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = npcRef.object.level, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if npcRef.object.type == 3 then
				log:info("Humanoid type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Humanoid", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = npcRef.object.level, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if (string.endswith(npcRef.object.name, "Sphere") or string.endswith(npcRef.object.name, "Centurion") or string.endswith(npcRef.object.name, "Fabricant") or string.startswith(npcRef.object.name, "Centurion")) then
				log:info("Centurion type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Centurion", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = npcRef.object.level, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if string.startswith(npcRef.object.name, "Spriggan") then
				log:info("Spriggan type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Spriggan", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = npcRef.object.level, ["goblevel"] = 1, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if (string.startswith(npcRef.object.name, "Goblin") or string.startswith(npcRef.object.name, "Warchief")) then
				log:info("Goblin type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Goblin", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = npcRef.object.level, ["domlevel"] = 1, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
			if (string.startswith(npcRef.object.name, "Guar") or string.endswith(npcRef.object.name, "Guar") or string.startswith(npcRef.object.name, "Corky") or string.startswith(npcRef.object.name, "Pack Rat")) then
				log:info("Domestic type detected.")
				npcRef.data.companionLeveler = { ["level"] = npcRef.object.level, ["type"] = "Domestic", ["norlevel"] = 1, ["daelevel"] = 1, ["undlevel"] = 1, ["humlevel"] = 1, ["cenlevel"] = 1, ["sprlevel"] = 1, ["goblevel"] = 1, ["domlevel"] = npcRef.object.level, ["summary"] = "No Summary.", ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["attModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillMods"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["skillModsMax"] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, ["abilities"] = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false } }
			end
		end
		npcRef.modified = true
	else
		log:trace("Saved Mod Data found.")
    end
    return npcRef.data.companionLeveler
end

----Companion Check-------------------------------------------------------------------------------------------------------------
function this.validCompanionCheck(mobileActor)
    log = logger.getLogger("Companion Leveler")
	log:trace("Checking " .. mobileActor.object.name .. "...")
	if (mobileActor == tes3.mobilePlayer) then
		return false
	end
	if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
		return false
	end
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end
	local fishCheck = string.endswith(mobileActor.object.name, "Slaughterfish")
    if fishCheck == true then
        log:debug("" .. mobileActor.object.name .. " ends with Slaughterfish, invalid companion!")
        return false
    end
	return true
end

return this