local core = require('openmw.core')
local self = require('openmw.self')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local ui = require('openmw.ui')

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')
local mCompat = require('scripts.BMS.util.compatibility')

if not mCompat.check(
        { "FtRP_Merchants.ESP", "For_the_Right_Price.ESP" },
        {}
) then return end

local mS = require('scripts.BMS.config.settings')
local mC = require("scripts.BMS.common")
local mH = require("scripts.BMS.util.helpers")

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = mC.getDescriptionIfOpenMWTooOld("description")
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

local npc
local npcBaseGold
local npcSkills
local npcScriptAttached = false
local pcGold
local pcGoldChanges = {}
local operation
local opQueue = {}
local ongoingOp = false

local stats = {
    mods = { orig = nil, curr = nil },
    bases = { orig = nil, curr = nil },
    baseDisp = { orig = nil, curr = nil },
    currDisp = { orig = nil, curr = nil },
}

local function checkOperation()
    if not npcScriptAttached or ongoingOp or #opQueue == 0 then return end
    operation = table.remove(opQueue, 1)
    local currNpc = npc
    local op = operation
    if operation.mod.type == mC.operationType.restore then
        if state.dispProgression[npc.id] then
            -- Override the permanent disposition changes option actions
            npc:sendEvent(mDef.events.modDisp, { disp = stats.baseDisp.curr, player = self })
        end
        mC.modStats(stats.mods.orig)
        npc = nil
        npcBaseGold = nil
        npcSkills = nil
        npcScriptAttached = false
        pcGold = nil
        pcGoldChanges = {}
        operation = nil
        opQueue = {}
    else
        ongoingOp = true
    end
    currNpc:sendEvent(mDef.events.modStats, op)
end

-- Save player's original and current stats
-- Original stats will be updated if we detect dynamic changes (e.g. expired buff)
local function initStats()
    stats.mods.orig = mC.getMods(self)
    stats.mods.curr = stats.mods.orig
    stats.bases.orig = mC.getBases(self)
    stats.bases.curr = stats.bases.orig
    stats.baseDisp.orig = T.NPC.getBaseDisposition(npc, self)
    stats.baseDisp.curr = stats.baseDisp.orig
    stats.currDisp.orig = T.NPC.getDisposition(npc, self)
    stats.currDisp.curr = stats.currDisp.orig
end

local function getDispProg(dispDiff, prevProg)
    local prog = 0
    local mercDiff = math.min(100, math.max(-100, npcSkills.mercantile[mC.buffType.barter] - stats.bases.orig.mercantile - stats.mods.orig.mercantile))
    if dispDiff > 0 then
        if #pcGoldChanges > 1 then
            local goldDiff = pcGoldChanges[1] - pcGoldChanges[2]
            pcGoldChanges = { pcGoldChanges[1] }
            local gainFactor = goldDiff < 0 and mS.dispScalingStorage:get("dispScalingMaxBuyGain") or mS.dispScalingStorage:get("dispScalingMaxSellGain")
            local skillFactor = 1 - (mercDiff + 100) / 400
            local goldFactor = math.min(1, math.abs(goldDiff) / math.max(mS.dispScalingStorage:get("dispScalingMinBaseGold"), npcBaseGold))
            local dispFactor = 1 - stats.baseDisp.curr / 100
            prog = dispDiff * gainFactor * skillFactor * goldFactor * dispFactor
            log(string.format("Merc Diff = %d, Gold diff = %d, Disposition progression = diff %d x gain %d x skill %.3f x gold %.3f x disp %.3f = %.3f (+%.3f = %.3f)",
                    mercDiff, goldDiff, dispDiff, gainFactor, skillFactor, goldFactor, dispFactor, prog, prevProg, prog + prevProg))
        else
            print(string.format("Disposition increased with \"%s\" without any gold transaction!"))
        end
    else
        local lossFactor = mS.dispScalingStorage:get("dispScalingMaxLoss")
        local skillFactor = 0.5 + (mercDiff + 100) / 400
        local dispFactor = (stats.baseDisp.curr / 100) ^ 2
        prog = dispDiff * lossFactor * skillFactor * dispFactor
        log(string.format("Merc Diff = %d, Disposition progression = diff %d x loss %d x skill %.3f x disp %.3f = %.3f (+%.3f = %.3f)",
                mercDiff, dispDiff, lossFactor, skillFactor, dispFactor, prog, prevProg, prog + prevProg))
    end
    return prog
end

-- Detect dynamic stat changes (only useful when the game is unpaused during dialogues)
local function checkStatsDiff()
    local newMods = mC.getMods(self)
    local modsDiff, modsHasDiff = mC.getStatsDiff(stats.mods.curr, newMods)
    local newBases = mC.getBases(self)
    local basesDiff, basesHasDiff = mC.getStatsDiff(stats.bases.curr, newBases)

    -- Don't update disposition on dialogue exit, because OpenMW tries to restore the previous value
    local checkDisp = I.UI.getMode()
    local newBaseDisp, baseDispDiff, newCurrDisp, currDispDiff = 0, 0, 0, 0
    if checkDisp then
        newBaseDisp = npc and T.NPC.getBaseDisposition(npc, self) or stats.baseDisp.curr
        baseDispDiff = newBaseDisp - stats.baseDisp.curr
        newCurrDisp = npc and T.NPC.getDisposition(npc, self) or stats.currDisp.curr
        currDispDiff = newCurrDisp - stats.currDisp.curr
    end

    if not modsHasDiff and not basesHasDiff and baseDispDiff == 0 and currDispDiff == 0 then return end

    if ongoingOp then
        log("PC stats changed during the current operation")
    end
    if modsHasDiff then
        log(string.format("PC modifiers diff detected: %s (%s -> %s)",
                mH.statsToString(modsDiff), mH.statsToString(stats.mods.curr), mH.statsToString(newMods)))
        -- restore original mods altered by the dynamic change
        mC.applyModsDiff(stats.mods.orig, modsDiff)
        mC.modStats(stats.mods.orig)
        newMods = stats.mods.orig
    end
    if basesHasDiff then
        log(string.format("PC base diff detected: %s (%s -> %s)",
                mH.statsToString(basesDiff), mH.statsToString(stats.bases.curr), newBases))
    end
    if baseDispDiff ~= 0 then
        log(string.format("PC/NPC base disposition diff detected: %d (%d -> %d)", baseDispDiff, stats.baseDisp.curr, newBaseDisp))
        if operation.mod.kind == mC.buffType.barter
                and mS.dispScalingStorage:get("dispScalingEnabled") then
            state.dispProgression[npc.id] = state.dispProgression[npc.id] or { object = npc, value = 0 }
            local prog = state.dispProgression[npc.id]
            local progDiff = getDispProg(baseDispDiff, prog.value)
            if progDiff ~= 0 then
                local oldProgValue = prog.value
                prog.value = prog.value + progDiff
                newBaseDisp = stats.baseDisp.curr + math.floor(prog.value)
                prog.value = prog.value % 1
                if progDiff > 0 then
                    log(string.format("Increased PC/NPC base disposition: %.3f + %.3f = %.3f",
                            stats.baseDisp.curr + oldProgValue, progDiff, newBaseDisp + prog.value))
                else
                    log(string.format("Decreased PC/NPC base disposition: %.3f - %.3f = %.3f",
                            stats.baseDisp.curr + oldProgValue, -progDiff, newBaseDisp + prog.value))
                end
                npc:sendEvent(mDef.events.modDisp, {
                    disp = newBaseDisp + prog.value,
                    player = self,
                    notify = mS.dispScalingStorage:get("dispScalingNotify"),
                    progDiff = progDiff,
                })
            end
        end
    end
    if currDispDiff ~= 0 then
        log(string.format("PC/NPC current disposition diff detected: %d (%d -> %d)", currDispDiff, stats.currDisp.curr, newCurrDisp))
    end

    stats.mods.curr = newMods
    stats.bases.curr = newBases
    if checkDisp then
        stats.baseDisp.curr = newBaseDisp
        stats.currDisp.curr = newCurrDisp
    end
    -- Player's stats have changed, let's restore stats, and redo the last operation
    -- Insert as first operation in case a new operation was added during the same frame
    table.insert(opQueue, 1, {
        restoreStats = { pcMods = stats.mods.orig },
        computeStats = true,
        mod = operation.mod,
    })
end

-- Update player stats, end of the operation
-- Won't be called when ending the dialogue and restoring stats
local function modStats(data)
    checkStatsDiff()
    ongoingOp = false
    checkOperation()
    if not npc then return end
    if ongoingOp then
        -- Player's stats have changed, we need to recompute all stats
        return
    end
    mC.modStats(data.pcMods)
    stats.mods.curr = data.pcMods
    npcSkills = data.npcSkills

    if operation.mod.refreshUiMode then
        -- the uiModeChanged event handler is triggered only once when doing multiple changes within the same frame
        I.UI.removeMode(operation.mod.refreshUiMode)
        I.UI.addMode(operation.mod.refreshUiMode, { target = npc })
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

local function configureOp(op, uiMode)
    if supportedUiModes[uiMode] then
        op.mod = {
            type = mC.operationType.buff,
            kind = uiMode == "Barter" and mC.buffType.barter or mC.buffType.service,
            refreshUiMode = uiModesToRefresh[uiMode] and uiMode or nil,
        }
    elseif uiMode == "Dialogue" then
        op.mod = {
            type = mC.operationType.buff,
            kind = mC.buffType.persuasion,
        }
    elseif not uiMode then
        op.mod = {
            type = mC.operationType.restore,
        }
    end
    if op.mod then
        table.insert(opQueue, op)
    end
end

local function uiModeChanged(data)
    if not mS.globalStorage:get("enabled") then return end
    if data.oldMode == data.newMode then
        log(string.format("The UI mode %s has been refreshed", data.oldMode))
        return
    end

    log(string.format("UI mode changed from %s to %s, target is %s", data.oldMode, data.newMode, data.arg))
    if npc then
        configureOp({}, data.newMode)
    elseif data.arg
            and data.arg.type == T.NPC
            and (data.newMode == "Dialogue" or supportedUiModes[data.newMode]) then
        local npcRecord = T.NPC.record(data.arg)
        if hasSupportedService(npcRecord) then
            log(string.format("Detected merchant '%s'", npcRecord.name, npcRecord.id))
            npc = data.arg
            npcBaseGold = npcRecord.baseGold
            initStats()
            local op = {
                player = self,
                saveStats = true,
                computeStats = true,
            }
            configureOp(op, data.newMode)
            core.sendGlobalEvent(mDef.events.attachNpcScript, { npc = data.arg, player = self })
        end
    end

    if data.newMode == "MainMenu" then
        core.sendGlobalEvent(mDef.events.updateSettings)
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
            if mC.isObjectInvalid(data.object) then
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
    if not pcGold or not pcGold:isValid() then
        pcGold = self.type.inventory(self):find("gold_001")
    end
    local playerGoldCount = pcGold and pcGold.count or 0
    if #pcGoldChanges == 0 then
        pcGoldChanges[1] = playerGoldCount
    else
        if pcGoldChanges[1] ~= playerGoldCount then
            table.insert(pcGoldChanges, 1, playerGoldCount)
        end
    end
end

local function onFrame()
    if not npc then return end

    checkTransactions()
    checkStatsDiff()
    -- Handle operations in onFrame because there may be multiple UI mode changes per frame (e.g. training)
    checkOperation()
end

local function onSave()
    state.saveVersion = mDef.saveVersion
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
        [mDef.events.notify] = notify,
        [mDef.events.onNpcScriptAttached] = function() npcScriptAttached = true end,
        [mDef.events.modPcStats] = modStats,
    }
}
