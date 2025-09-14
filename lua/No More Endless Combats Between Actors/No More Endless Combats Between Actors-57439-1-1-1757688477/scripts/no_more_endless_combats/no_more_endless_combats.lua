local self = require("openmw.self")
local recordId = self.recordId
local ai = require("openmw.interfaces").AI
local types = require("openmw.types")
local Actor = types.Actor
local async = require("openmw.async")
local core = require("openmw.core")

local saveTarget
local saveTime
local timeDelta
local activeTarget

-- Blacklist to exclude some actors from this mod.
-- (If you edit, write the ID of the NPC in lowercase, like the example below)
local blacklist = {
	--["fargoth"] = true,          -- Example. (To activate, remove the "--" at the begining of the line)
	--["vodunius nuccius"] = true,
}

local function onSave()
    return {
        ST = saveTime,
        STg = saveTarget,
    }
end

local function onLoad(data)
	if data then
		saveTime = data.ST
		saveTarget = data.STg
	end
end


local function noMoreEndlessCombats()

    if Actor.isDead(self) or blacklist[recordId] then -- Dead actors are excluded from this mod, of course.
        return
    end

--if self.recordId ~= "fargoth" and self.recordId ~= "zvodunius nuccius" then return end

	async:newUnsavableSimulationTimer(3, noMoreEndlessCombats) -- We check every 3s

	if not Actor.isInActorsProcessingRange(self) then return end -- The actor must be in the processing range

    activeTarget = ai.getActiveTarget("Combat")
    -- if not in combat, or in combat with player, he's not in the scope of this mod
    if not activeTarget or activeTarget.type == types.Player then
		saveTime = nil
		saveTarget = nil
		return
	end

	-- if it's a new combat, we memorize the time and the target
	if not saveTime then
		saveTime = core.getGameTime()
		saveTarget = activeTarget
		return
	end

	-- if the target has change, it's a new combat, so we memorize the time and the target
	if activeTarget ~= saveTarget then
		saveTime = core.getGameTime()
		saveTarget = activeTarget
		return
	end
	
	timeDelta = core.getGameTime() - saveTime
	-- if combat has begun recently (<12h), it's not time to stop combat yet.
	if timeDelta < 43200 then return end -- 43200 = 12h
	
	-- Here we know that combat lasts for a long time (>12h), so we stop it.
	ai.removePackages("Combat")
	saveTime = nil
	saveTarget = nil

end


return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
        onActive = noMoreEndlessCombats,
    }
}
