local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local ui = require('openmw.ui')

local log = require("scripts.BMS.log")
local D = require('scripts.BMS.definition')
local S = require('scripts.BMS.settings')
local C = require("scripts.BMS.common")
local H = require("scripts.BMS.helpers")

I.Settings.registerPage {
    key = D.MOD_NAME,
    l10n = D.MOD_NAME,
    name = "name",
    description = C.getDescriptionIfOpenMWTooOld("description")
}

local state = {
    dispProgression = {}
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
local currentNpcBaseGold
local currentNpcSkills
local playerGold
local playerGoldChanges = {}
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
        if state.dispProgression[currentNpc.id] then
            -- Override the permanent disposition changes option actions
            currentNpc:sendEvent(D.events.modDisp, { disp = stats.disp.curr, player = self })
        end
        C.modStats(self, stats.mods.orig)
        currentNpc = nil
        currentNpcBaseGold = nil
        currentNpcSkills = nil
        playerGold = nil
        playerGoldChanges = {}
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
    stats.disp.orig = T.NPC.getBaseDisposition(currentNpc, self)
    stats.disp.curr = stats.disp.orig
end

local function getDispProg(dispDiff, prevProg)
    local prog
    local mercDiff = math.min(100, math.max(-100, currentNpcSkills.mercantile[C.buffType.barter] - stats.bases.orig.mercantile - stats.mods.orig.mercantile))
    if dispDiff > 0 then
        local goldDiff = playerGoldChanges[1] - playerGoldChanges[2]
        local gainFactor = goldDiff < 0 and S.dispScalingStorage:get("dispScalingMaxBuyGain") or S.dispScalingStorage:get("dispScalingMaxSellGain")
        local skillFactor = 1 - (mercDiff + 100) / 400
        local goldFactor = math.min(1, math.abs(goldDiff) / math.max(S.dispScalingStorage:get("dispScalingMinBaseGold"), currentNpcBaseGold))
        local dispFactor = 1 - stats.disp.curr / 100
        prog = dispDiff * gainFactor * skillFactor * goldFactor * dispFactor
        log(string.format("Merc Diff = %d, Gold diff = %d, Disposition progression = diff %d x gain %d x skill %.3f x gold %.3f x disp %.3f = %.3f (+%.3f = %.3f)",
                mercDiff, goldDiff, dispDiff, gainFactor, skillFactor, goldFactor, dispFactor, prog, prevProg, prog + prevProg))
    else
        local lossFactor = S.dispScalingStorage:get("dispScalingMaxLoss")
        local skillFactor = 0.5 + (mercDiff + 100) / 400
        local dispFactor = (stats.disp.curr / 100) ^ 2
        prog = dispDiff * lossFactor * skillFactor * dispFactor
        log(string.format("Merc Diff = %d, Disposition progression = diff %d x loss %d x skill %.3f x disp %.3f = %.3f (+%.3f = %.3f)",
                mercDiff, dispDiff, lossFactor, skillFactor, dispFactor, prog, prevProg, prog + prevProg))
    end
    return prog
end

-- Detect dynamic stat changes (only useful when the game is unpaused during dialogues)
local function checkStatsDiff()
    if not I.UI.getMode() then
        log("No UI mode, the dialogue is exiting, we won't update the modifiers")
        return
    end
    local newMods = C.getMods(self)
    local modsDiff, modsHasDiff = C.getStatsDiff(stats.mods.curr, newMods)
    local newBases = C.getBases(self)
    local basesDiff, basesHasDiff = C.getStatsDiff(stats.bases.curr, newBases)
    local newDisp = currentNpc and T.NPC.getBaseDisposition(currentNpc, self) or stats.disp.curr
    local dispDiff = newDisp - stats.disp.curr
    local dispHasDiff = dispDiff ~= 0

    if not modsHasDiff and not basesHasDiff and not dispHasDiff then return end

    if ongoingOperation then
        log("PC stats changed during the current operation")
    end
    if modsHasDiff then
        log(string.format("PC modifiers diff detected: %s (%s -> %s)",
                H.statsToString(modsDiff), H.statsToString(stats.mods.curr), H.statsToString(newMods)))
        -- restore original mods altered by the dynamic change
        C.applyModsDiff(stats.mods.orig, modsDiff)
        C.modStats(self, stats.mods.orig)
        newMods = stats.mods.orig
    end
    if basesHasDiff then
        log(string.format("PC base diff detected: %s (%s -> %s)",
                H.statsToString(basesDiff), H.statsToString(stats.bases.curr), newBases))
    end
    if dispHasDiff then
        log(string.format("PC/NPC base disposition diff detected: %d (%d -> %d)", dispDiff, stats.disp.curr, newDisp))
        if S.dispScalingStorage:get("dispScalingEnabled") then
            if operation.mod.kind == C.buffType.barter then
                state.dispProgression[currentNpc.id] = state.dispProgression[currentNpc.id] or { object = currentNpc, value = 0 }
                local prog = state.dispProgression[currentNpc.id]
                local progDiff = getDispProg(dispDiff, prog.value)
                local oldProgValue = prog.value
                prog.value = prog.value + progDiff
                newDisp = stats.disp.curr + math.floor(prog.value)
                prog.value = prog.value % 1
                if progDiff > 0 then
                    log(string.format("Increased PC/NPC base disposition: %.3f + %.3f = %.3f",
                            stats.disp.curr + oldProgValue, progDiff, newDisp + prog.value))
                else
                    log(string.format("Decreased PC/NPC base disposition: %.3f - %.3f = %.3f",
                            stats.disp.curr + oldProgValue, -progDiff, newDisp + prog.value))
                end
                currentNpc:sendEvent(D.events.modDisp, {
                    disp = newDisp + prog.value,
                    player = self,
                    notify = S.dispScalingStorage:get("dispScalingNotify"),
                    progDiff = progDiff,
                })
            end
        end
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
local function modStats(data)
    checkStatsDiff()
    ongoingOperation = false
    checkOperation()
    if not currentNpc then return end
    if ongoingOperation then
        -- Player's stats have changed, we need to recompute all stats
        return
    end
    C.modStats(self, data.pcMods)
    stats.mods.curr = data.pcMods
    currentNpcSkills = data.npcSkills

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
    if not S.globalStorage:get("enabled") then return end
    if data.oldMode == data.newMode then
        log(string.format("The UI mode %s has been refreshed", data.oldMode))
        return
    end

    log(string.format("UI mode changed from %s to %s (%s)", data.oldMode, data.newMode, data.arg))
    local op = {}
    if not currentNpc and data.arg and data.arg.type == T.NPC and (data.newMode == "Dialogue" or supportedUiModes[data.newMode]) then
        local npcRecord = T.NPC.record(data.arg)
        if hasSupportedService(npcRecord) then
            currentNpc = data.arg
            currentNpcBaseGold = npcRecord.baseGold
            initStats()
            log(string.format("Detected merchant '%s' (%s)", npcRecord.name, npcRecord.id))
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

local function notify(msg)
    ui.showMessage(msg, { showInDialogue = false })
end

local function fixObjects()
    local dataLists = { dispositionProgresses = state.dispProgression }
    for key, dataList in pairs(dataLists) do
        local invalidCt, changedIdCt = 0, 0
        for id, data in pairs(dataList) do
            if C.isObjectInvalid(data.object) then
                invalidCt = invalidCt + 1
                dataList[id] = nil
            elseif id ~= data.object.id then
                changedIdCt = changedIdCt + 1
                dataList[id] = nil
                dataList[data.object.id] = data
            end
        end
        if invalidCt + changedIdCt > 0 then
            log(string.format("Cleared %d invalid references and fixed %d changed IDs for %s", invalidCt, changedIdCt, key))
        end
    end
end

local function checkTransactions()
    if not currentNpc then return end
    if not playerGold or not playerGold:isValid() then
        playerGold = self.type.inventory(self):find("gold_001")
    end
    local playerGoldCount = playerGold and playerGold.count or 0
    if #playerGoldChanges == 0 then
        playerGoldChanges[1] = playerGoldCount
    else
        if playerGoldChanges[1] ~= playerGoldCount then
            table.insert(playerGoldChanges, 1, playerGoldCount)
        end
    end
end

local function onFrame()
    if not currentNpc or ongoingOperation then return end

    -- Handle operations in onFrame because there may be multiple UI mode changes per frame (e.g. training)
    checkTransactions()
    checkStatsDiff()
    checkOperation()
end

local function onSave()
    state.saveVersion = D.saveVersion
    return state
end

local function onLoad(data)
    if data then
        state = data
        log(string.format("Loading BMS save v%s...", state.saveVersion))
    end
    fixObjects()
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [D.events.notify] = notify,
        [D.events.modPcStats] = modStats,
    }
}
