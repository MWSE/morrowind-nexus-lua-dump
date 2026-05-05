local storage = require("openmw.storage")
local self = require("openmw.self")
local mDef = require("scripts.SC.config.definition")

local sessionSection = storage.playerSection("SC_session")
sessionSection:setLifeTime(storage.LIFE_TIME.GameSession)

local state = {
    profileId = nil,
    lastCellKey = nil,
}

local GUILD_GUIDE_POLL_INTERVAL = 0.5
local guildGuidePollAccumulator = 0

local function cellId(cell)
    if cell == nil then return "nil" end
    local ok, id = pcall(function() return cell.id end)
    if ok and id then return tostring(id) end
    return tostring(cell)
end

local function isGuildGuideCell(key)
    if not key then return false end
    key = string.lower(key)
    return string.find(key, "guild of mages", 1, true) ~= nil
end

local function incrementTravel()
    if not state.profileId then return end
    local section = storage.playerSection(state.profileId)
    section:set("travelCount", (section:get("travelCount") or 0) + 1)
end

local function ensureProfileId()
    if state.profileId then return true end
    local playthroughId = sessionSection:get("playthroughId")
    if not playthroughId or playthroughId == "" then return false end
    state.profileId = string.format("%s_%s", mDef.MOD_NAME, playthroughId)
    return true
end

local function onInit()
    state.profileId = nil
    state.lastCellKey = nil
    guildGuidePollAccumulator = 0
end

local function onLoad()
    state.profileId = nil
    state.lastCellKey = nil
    guildGuidePollAccumulator = 0
end

local function onUpdate(deltaTime)
    if not deltaTime or deltaTime == 0 then return end
    guildGuidePollAccumulator = guildGuidePollAccumulator + deltaTime
    if guildGuidePollAccumulator < GUILD_GUIDE_POLL_INTERVAL then return end
    guildGuidePollAccumulator = guildGuidePollAccumulator - GUILD_GUIDE_POLL_INTERVAL
    if not ensureProfileId() then return end

    local cell = self.object.cell
    if not cell then return end
    local currentKey = cellId(cell)

    if state.lastCellKey == nil then
        state.lastCellKey = currentKey
        return
    end

    if currentKey ~= state.lastCellKey then
        if isGuildGuideCell(state.lastCellKey) and isGuildGuideCell(currentKey) then
            incrementTravel()
        end
        state.lastCellKey = currentKey
    end
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onLoad,
        onUpdate = onUpdate,
    },
}
