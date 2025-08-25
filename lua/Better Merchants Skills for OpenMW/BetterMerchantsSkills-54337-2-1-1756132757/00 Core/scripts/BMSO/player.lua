local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')

local D = require('scripts.BMSO.definition')
local S = require('scripts.BMSO.settings')
local C = require("scripts.BMSO.common")

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
local modOperation
local ongoingModification = false
local stats = {
    mods = { orig = nil, curr = nil, diff = nil, hasDiff = false },
    bases = { orig = nil, curr = nil, diff = nil, hasDiff = false },
    disp = { orig = nil, curr = nil, diff = nil, hasDiff = false },
}

local function isServiceSupported(servicesOffered)
    for service in pairs(supportedServices) do
        if servicesOffered[service] then
            return true
        end
    end
    return false
end

local function requestModStats(operation)
    if not currentNpc then return end
    ongoingModification = true
    currentNpc:sendEvent(D.events.modStats, operation)
end

local function initStats()
    stats.mods.orig = C.getMods(self)
    stats.mods.curr = stats.mods.orig
    stats.bases.orig = C.getBases(self)
    stats.bases.curr = stats.bases.orig
    stats.disp.orig = T.NPC.getDisposition(currentNpc, self)
    stats.disp.curr = stats.disp.orig
end

local function handleStatsDiff()
    local newMods = C.getMods(self)
    stats.mods.diff, stats.mods.hasDiff = C.getStatsDiff(stats.mods.curr, newMods)
    local newBases = C.getBases(self)
    stats.bases.diff, stats.bases.hasDiff = C.getStatsDiff(stats.bases.curr, newBases)
    local newDisp = currentNpc and T.NPC.getDisposition(currentNpc, self) or stats.disp.curr
    stats.disp.diff = newDisp - stats.disp.curr
    stats.disp.hasDiff = (stats.disp.diff ~= 0)

    if not stats.mods.hasDiff and not stats.bases.hasDiff and not stats.disp.hasDiff then
        return false
    end

    if stats.mods.hasDiff then
        C.log(string.format("PC modifiers diff detected: %s (%s -> %s)",
                C.statsToString(stats.mods.diff), C.statsToString(stats.mods.curr), C.statsToString(newMods)))
        -- restore original mods altered by the dynamic change
        C.applyModsDiff(stats.mods.orig, stats.mods.diff)
        C.modStats(self, stats.mods.orig)
        newMods = stats.mods.orig
    end
    if stats.bases.hasDiff then
        C.log(string.format("PC base diff detected: %s (%s -> %s)",
                C.statsToString(stats.bases.diff), C.statsToString(stats.bases.curr), newBases))
    end
    if stats.disp.hasDiff then
        C.log(string.format("PC disposition diff detected: %d (%d -> %d)", stats.disp.diff, stats.disp.curr, newDisp))
    end

    stats.mods.curr = newMods
    stats.bases.curr = newBases
    stats.disp.curr = newDisp
    requestModStats({
        restoreStats = { pcMods = stats.mods.orig },
        computeStats = true,
        mod = modOperation,
    })

    return true
end

local function modStats(data)
    ongoingModification = false
    if handleStatsDiff() then
        C.log("PC stats changed during the current operation")
        return
    end
    C.modStats(self, data.mods)
    stats.mods.curr = data.mods

    if modOperation and modOperation.refreshUiMode then
        -- the uiModeChanged event handler is triggered only once when doing multiple changes within the same frame
        I.UI.removeMode(modOperation.refreshUiMode)
        I.UI.addMode(modOperation.refreshUiMode, { target = currentNpc })
    end
end

local function uiModeChanged(data)
    if not S.storage:get("enabled") then return end
    if data.oldMode == data.newMode then
        C.log(string.format("The UI mode %s has been refreshed", data.oldMode))
        return
    end

    C.log(string.format("UI mode changed from %s to %s (%s)", data.oldMode, data.newMode, data.arg))
    if data.arg and data.arg.type == T.NPC and not data.oldMode and data.newMode == "Dialogue" then
        local npcRecord = T.NPC.record(data.arg)
        if isServiceSupported(npcRecord.servicesOffered) then
            currentNpc = data.arg
            initStats()
            C.log(string.format("Detected merchant '%s' (%s)", npcRecord.name, npcRecord.id))
            modOperation = { type = C.operationType.buff, kind = C.buffType.persuasion }
            requestModStats({
                player = self,
                saveStats = true,
                computeStats = true,
                mod = modOperation,
            })
        end
    elseif currentNpc and supportedUiModes[data.newMode] then
        modOperation = {
            type = C.operationType.buff,
            kind = data.newMode == "Barter" and C.buffType.barter or C.buffType.service,
            refreshUiMode = uiModesToRefresh[data.newMode] and data.newMode or nil
        }
        requestModStats({
            mod = modOperation,
        })
    elseif currentNpc and supportedUiModes[data.oldMode] then
        modOperation = { type = C.operationType.buff, kind = C.buffType.persuasion }
        requestModStats({
            mod = modOperation,
        })
    elseif currentNpc and data.oldMode == "Dialogue" and not data.newMode then
        requestModStats({
            mod = { type = C.operationType.restore },
        })
        currentNpc = nil
        modOperation = nil
    elseif data.newMode == "MainMenu" then
        core.sendGlobalEvent(D.events.updateSettings)
    end
end

local function onFrame()
    if currentNpc and not ongoingModification then
        handleStatsDiff()
        return
    end
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
