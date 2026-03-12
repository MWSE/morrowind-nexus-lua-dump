local self  = require("openmw.self")
local types = require("openmw.types")
local ui    = require("openmw.ui")
local core  = require("openmw.core")

local shared         = require("scripts.felms_blessing_shared")
local KILL_THRESHOLD = shared.KILL_THRESHOLD
local INT_THRESHOLD  = shared.INT_THRESHOLD
local PLAYER_FACTION = shared.PLAYER_FACTION
local PLAYER_EXCLUDED_FACTIONS = shared.PLAYER_EXCLUDED_FACTIONS
local MSG            = shared.MSG
local PROGRESS_MSG   = shared.PROGRESS_MSG


local AXE_TYPES = {
    [types.Weapon.TYPE.AxeOneHand] = true,
    [types.Weapon.TYPE.AxeTwoHand] = true,
}

local killCount = 0
local isBlessed = false

local function checkBlessing()
    if isBlessed then return end
    local intel = types.Actor.stats.attributes.intelligence(self.object).modified
    if intel >= INT_THRESHOLD then return end
    local rank = types.NPC.getFactionRank(self.object, PLAYER_FACTION)
    if not rank or rank == 0 then return end
    if types.NPC.isExpelled(self.object, PLAYER_FACTION) then return end
    for faction in pairs(PLAYER_EXCLUDED_FACTIONS) do
        local r = types.NPC.getFactionRank(self.object, faction)
        if r and r > 0 then return end
    end
    if killCount < KILL_THRESHOLD then
        ui.showMessage(PROGRESS_MSG .. killCount .. " / " .. KILL_THRESHOLD)
        return
    end
    isBlessed = true
    core.sendGlobalEvent("AxeBlessing_Granted", { player = self.object })
    ui.showMessage(MSG)
end

return {
    engineHandlers = {
        onSave = function()
            return { kills = killCount, blessed = isBlessed }
        end,
        onLoad = function(data)
            killCount = data and data.kills or 0
            isBlessed = data and data.blessed or false
        end,
    },
    eventHandlers = {
        AxeKill = function(data)
            if not data or not data.weaponType then return end
            if not AXE_TYPES[data.weaponType] then return end
            killCount = killCount + 1
            checkBlessing()
        end,
    },
}