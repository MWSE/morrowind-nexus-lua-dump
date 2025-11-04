local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')

local D = require('scripts.BMS.definition')
local S = require('scripts.BMS.settings')
local C = require("scripts.BMS.common")

I.Settings.registerPage {
    key = D.MOD_NAME,
    l10n = D.MOD_NAME,
    name = "name",
    description = C.getDescriptionIfOpenMWTooOld("description")
}

local supportedServices = {
    Barter = true,
    Enchanting = true,
    Repair = true,
    Spellmaking = true,
    Spells = true,
    Training = true,
    Travel = true,
}

local supportedUiModes = {
    Barter = true,
    SpellCreation = true,
    Enchanting = true,
    MerchantRepair = true,
    SpellBuying = true,
    Training = true,
    Travel = true,
}

local uiModesToRefresh = {
    MerchantRepair = true,
    SpellBuying = true,
    Training = true,
    Travel = true,
}

local currentNpc
local operation
local requestOperation = false
local ongoingOperation = false

local stats = {
    mods = { orig = nil, curr = nil },
    bases = { orig = nil, curr = nil },
    disp = { orig = nil, curr = nil },
}

local function setOperation(op)
    operation = op
    requestOperation = true
end

local function checkOperation()
    if not requestOperation then return end
    requestOperation = false
    currentNpc:sendEvent(D.events.modStats, operation)
    if operation.mod.type == C.operationType.restore then
        C.modStats(self, stats.mods.orig)
        currentNpc = nil
        operation = nil
    else
        ongoingOperation = true
    end
end

-- Save player's original and current stats
-- Original stats will be updated if we detect dynamic changes (e.g. expired buff)
local function initStats()
    stats.mods.orig = C.getMods(self)
    stats.mods.curr = stats.mods.orig
    stats.bases.orig = C.getBases(self)
    stats.bases.curr = stats.bases.orig
    stats.disp.orig = T.NPC.getDisposition(currentNpc, self)
    stats.disp.curr = stats.disp.orig
end

-- Detect dynamic stat changes (only useful when the game is unpaused during dialogues)
local function checkStatsDiff()
    local newMods = C.getMods(self)
    local modsDiff, modsHasDiff = C.getStatsDiff(stats.mods.curr, newMods)
    local newBases = C.getBases(self)
    local basesDiff, basesHasDiff = C.getStatsDiff(stats.bases.curr, newBases)
    local newDisp = currentNpc and T.NPC.getDisposition(currentNpc, self) or stats.disp.curr
    local dispDiff = newDisp - stats.disp.curr
    local dispHasDiff = dispDiff ~= 0

    if not modsHasDiff and not basesHasDiff and not dispHasDiff then return end

    if ongoingOperation then
        C.log("PC stats changed during the current operation")
    end
    if modsHasDiff then
        C.log(string.format("PC modifiers diff detected: %s (%s -> %s)",
                C.statsToString(modsDiff), C.statsToString(stats.mods.curr), C.statsToString(newMods)))
        -- restore original mods altered by the dynamic change
        C.applyModsDiff(stats.mods.orig, modsDiff)
        C.modStats(self, stats.mods.orig)
        newMods = stats.mods.orig
    end
    if basesHasDiff then
        C.log(string.format("PC base diff detected: %s (%s -> %s)",
                C.statsToString(basesDiff), C.statsToString(stats.bases.curr), newBases))
    end
    if dispHasDiff then
        C.log(string.format("PC disposition diff detected: %d (%d -> %d)", dispDiff, stats.disp.curr, newDisp))
    end

    stats.mods.curr = newMods
    stats.bases.curr = newBases
    stats.disp.curr = newDisp
    -- Player's stats have changed, let's restore stats and redo the last operation
    setOperation({
        restoreStats = { pcMods = stats.mods.orig },
        computeStats = true,
        mod = operation.mod,
    })
end

-- Update player stats, end of the operation
-- Won't be called when ending the dialogue and restoring stats
local function modStats(mods)
    checkStatsDiff()
    ongoingOperation = false
    checkOperation()
    if not currentNpc then return end
    if ongoingOperation then
        -- Player's stats have changed, we need to recompute all stats
        return
    end
    C.modStats(self, mods)
    stats.mods.curr = mods

    if operation.mod.refreshUiMode then
        -- the uiModeChanged event handler is triggered only once when doing multiple changes within the same frame
        I.UI.removeMode(operation.mod.refreshUiMode)
        I.UI.addMode(operation.mod.refreshUiMode, { target = currentNpc })
    end
end

local function hasSupportedService(npcRecord)
    for service in pairs(supportedServices) do
        if npcRecord.servicesOffered[service] then
            return true
        end
    end
    return false
end

local function uiModeChanged(data)
    if not S.storage:get("enabled") then return end
    if data.oldMode == data.newMode then
        C.log(string.format("The UI mode %s has been refreshed", data.oldMode))
        return
    end

    C.log(string.format("UI mode changed from %s to %s (%s)", data.oldMode, data.newMode, data.arg))
    local op = {}
    if not currentNpc and data.arg and data.arg.type == T.NPC and (data.newMode == "Dialogue" or supportedUiModes[data.newMode]) then
        local npcRecord = T.NPC.record(data.arg)
        if hasSupportedService(npcRecord) then
            currentNpc = data.arg
            initStats()
            C.log(string.format("Detected merchant '%s' (%s)", npcRecord.name, npcRecord.id))
            op = {
                player = self,
                saveStats = true,
                computeStats = true,
            }
        end
    end
    if currentNpc then
        if supportedUiModes[data.newMode] then
            op.mod = {
                type = C.operationType.buff,
                kind = data.newMode == "Barter" and C.buffType.barter or C.buffType.service,
                refreshUiMode = uiModesToRefresh[data.newMode] and data.newMode or nil,
            }
        elseif data.newMode == "Dialogue" then
            op.mod = {
                type = C.operationType.buff,
                kind = C.buffType.persuasion,
            }
        elseif not data.newMode then
            op.mod = {
                type = C.operationType.restore,
            }
        end
        if op.mod then
            setOperation(op)
        end
    end

    if data.newMode == "MainMenu" then
        core.sendGlobalEvent(D.events.updateSettings)
    end
end

local function onFrame()
    if not currentNpc or ongoingOperation then return end

    -- Handle operations in onFrame because there may be multiple UI mode changes per frame (e.g. training)
    checkStatsDiff()
    checkOperation()
end

return {
    engineHandlers = {
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [D.events.modPcStats] = modStats,
    }
}
