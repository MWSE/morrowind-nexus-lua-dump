local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")

local public = {}

public.registerMainQuest = function(questID)
	common.questType[questID] = "main" 
end
public.registerGuildQuest = function(questID)
	common.questType[questID] = "guild"
end
public.registerTaskQuest = function(questID)
	common.questType[questID] = "task"
end
public.registerNoXPQuest = function(questID) --quests registered as noXP will not grant XP upon completion
	common.questType[questID] = "noXP"
end

public.registerBossMonster = function(id)
	common.bossMonsters[id] = true
end

public.unregisterBossMonster = function(id)
	common.bossMonsters[id] = nil
end

--registers a custom guild quest object ID header
public.registerGuildHeader = function(IDHeader)
	if not table.find(public.guildQuestIDHeaders, IDHeader) then
		table.insert(common.guildQuestIDHeaders, IDHeader)
	end
end


--checks if the given quest is a guild quest, and registers it if necessary
local function checkForGuildQuest(questID)
	
	if string.multifind(questID, common.guildQuestIDHeaders, 1, false) then
		if not common.questType[questID] then
			public.registerGuildQuest(questID)
		end
		return true
	end
	return false
end

public.getQuestType = function(ID)
	if not common.questType[ID] then
		checkForGuildQuest(ID)
	end
	return common.questType[ID] or "side"
end

return public