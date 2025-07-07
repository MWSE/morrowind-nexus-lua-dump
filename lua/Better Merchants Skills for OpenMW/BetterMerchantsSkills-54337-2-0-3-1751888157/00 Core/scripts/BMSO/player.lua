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
local buffOperation
local lastDisposition
local lastUpdateTime = 0

local function isServiceSupported(servicesOffered)
    for service in pairs(supportedServices) do
        if servicesOffered[service] then
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
    if data.arg and data.arg.type == T.NPC and not data.oldMode and data.newMode == "Dialogue" then
        local npcRecord = T.NPC.record(data.arg)
        if isServiceSupported(npcRecord.servicesOffered) then
            currentNpc = data.arg
            lastDisposition = T.NPC.getDisposition(currentNpc, self)
            C.log(string.format("Detected merchant '%s' (%s)", npcRecord.name, npcRecord.id))
            buffOperation = { type = C.operationType.buff, kind = C.buffType.persuasion }
            currentNpc:sendEvent(D.events.handleStats, {
                { type = C.operationType.saveStats, player = self },
                { type = C.operationType.computeStats },
                buffOperation,
            })
        end
    elseif currentNpc and supportedUiModes[data.newMode] then
        buffOperation = {
            type = C.operationType.buff,
            kind = data.newMode == "Barter" and C.buffType.barter or C.buffType.service,
            refreshUiMode = uiModesToRefresh[data.newMode] and data.newMode or nil
        }
        currentNpc:sendEvent(D.events.handleStats, { buffOperation })
    elseif currentNpc and supportedUiModes[data.oldMode] then
        buffOperation = { type = C.operationType.buff, kind = C.buffType.persuasion }
        currentNpc:sendEvent(D.events.handleStats, { buffOperation })
    elseif currentNpc and data.oldMode == "Dialogue" and not data.newMode then
        currentNpc:sendEvent(D.events.handleStats, { { type = C.operationType.restore } })
        currentNpc = nil
        buffOperation = nil
        lastDisposition = nil
        lastUpdateTime = 0
    elseif data.newMode == "MainMenu" then
        core.sendGlobalEvent(D.events.updateSettings)
    end
end

local function modStats(buffs)
    C.buffStats(self, buffs)

    if buffOperation and buffOperation.refreshUiMode then
        -- the uiModeChanged event handler is triggered only once when doing multiple changes within the same frame
        I.UI.removeMode(buffOperation.refreshUiMode)
        I.UI.addMode(buffOperation.refreshUiMode, { target = currentNpc })
    end
end

local function refreshStats()
    currentNpc:sendEvent(D.events.handleStats, {
        { type = C.operationType.computeStats },
        buffOperation,
    })
end

I.SkillProgression.addSkillLevelUpHandler(function(_, _)
    if not currentNpc then return end
    refreshStats()
    lastDisposition = T.NPC.getDisposition(currentNpc, self)
end)

local function onFrame(deltaTime)
    if not currentNpc then return end
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 0.5 then return end
    lastUpdateTime = 0

    local disposition = T.NPC.getDisposition(currentNpc, self)
    if disposition == lastDisposition then return end
    lastDisposition = disposition

    refreshStats()
end

return {
    engineHandlers = {
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [D.events.modStats] = modStats,
    }
}
