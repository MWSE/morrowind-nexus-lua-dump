--[[
    Fair Trade - Player Script

    Owns the settings page and group (player section). Pushes a
    full snapshot to the global script on load and on every
    settings change.

    Detects barter and travel transactions by monitoring gold
    changes during Barter/Travel UI modes. Sends transaction events
    to the global script for all disposition/loyalty/regional/rebate
    logic.
]]

local core    = require('openmw.core')
local types   = require('openmw.types')
local self    = require('openmw.self')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local ui      = require('openmw.ui')
local I       = require('openmw.interfaces')

local MODNAME        = "FairTrade"
local L10N           = "FairTrade"
local SETTINGS_GROUP = "SettingsPlayer" .. MODNAME

-- After exiting barter, wait this long for the engine to apply
-- its +1 "vanilla leak" (the free disposition point vanilla grants
-- per transaction), then compare disposition once and, if it is
-- exactly 1 above the floor, subtract 1. We never touch it again
-- after that single correction — this guarantees persuasion,
-- intimidation, or other mods' disposition changes applied during
-- dialogue are never clobbered.
local LEAK_SETTLE_DELAY     = 0.0   -- neutralize on the very next frame after barter closes
local LEAK_WATCH_WINDOW     = 1.25  -- short high-frequency watch window to hide the vanilla +1 blip
local LEAK_MAX_CORRECTION   = 1     -- never correct more than this in a session

-- -----------------------------------------------------------------
-- Settings registration (player section)
-- -----------------------------------------------------------------

I.Settings.registerPage {
    key         = MODNAME,
    l10n        = L10N,
    name        = "settings_page_name",
    description = "settings_page_desc",
}

I.Settings.registerGroup {
    key              = SETTINGS_GROUP,
    page             = MODNAME,
    l10n             = L10N,
    name             = "settings_group_general",
    description      = "settings_group_general_desc",
    permanentStorage = true,
    settings = {
        { key = "enabled", renderer = "checkbox", default = true,
          name = "setting_enabled", description = "setting_enabled_desc" },
        { key = "showMessages", renderer = "checkbox", default = true,
          name = "setting_showMessages", description = "setting_showMessages_desc" },
        { key = "showTravelDispositionMessages", renderer = "checkbox", default = false,
          name = "setting_showTravelDispositionMessages", description = "setting_showTravelDispositionMessages_desc" },
        { key = "debugLogging", renderer = "checkbox", default = false,
          name = "setting_debugLogging", description = "setting_debugLogging_desc" },

        { key = "dispScale", renderer = "number", default = 1.0,
          name = "setting_dispScale", description = "setting_dispScale_desc",
          argument = { min = 0.1, max = 5.0 } },
        { key = "buyMultiplier", renderer = "number", default = 1.0,
          name = "setting_buyMultiplier", description = "setting_buyMultiplier_desc",
          argument = { min = 0.0, max = 3.0 } },
        { key = "sellMultiplier", renderer = "number", default = 0.5,
          name = "setting_sellMultiplier", description = "setting_sellMultiplier_desc",
          argument = { min = 0.0, max = 3.0 } },
        { key = "dailyDispCap", renderer = "number", default = 5,
          name = "setting_dailyDispCap", description = "setting_dailyDispCap_desc",
          argument = { integer = true, min = 0, max = 50 } },
        { key = "dailyTravelDispCap", renderer = "number", default = 3,
          name = "setting_dailyTravelDispCap", description = "setting_dailyTravelDispCap_desc",
          argument = { integer = true, min = 0, max = 20 } },
        { key = "haggleBonus", renderer = "number", default = 1,
          name = "setting_haggleBonus", description = "setting_haggleBonus_desc",
          argument = { integer = true, min = 0, max = 5 } },
        { key = "passiveXpMult", renderer = "number", default = 0.5,
          name = "setting_passiveXpMult", description = "setting_passiveXpMult_desc",
          argument = { min = 0.0, max = 2.0 } },
        { key = "enableLoyalty", renderer = "checkbox", default = true,
          name = "setting_enableLoyalty", description = "setting_enableLoyalty_desc" },
        { key = "enableMerchantScaling", renderer = "checkbox", default = true,
          name = "setting_enableMerchantScaling", description = "setting_enableMerchantScaling_desc" },
        { key = "enableTransportLoyalty", renderer = "checkbox", default = true,
          name = "setting_enableTransportLoyalty", description = "setting_enableTransportLoyalty_desc" },
        { key = "enableRegionalLoyalty", renderer = "checkbox", default = true,
          name = "setting_enableRegionalLoyalty", description = "setting_enableRegionalLoyalty_desc" },
    },
}

local settingsSection = storage.playerSection(SETTINGS_GROUP)

local SETTING_DEFAULTS = {
    enabled                       = true,
    showMessages                  = true,
    showTravelDispositionMessages = false,
    debugLogging                  = false,
    dispScale                     = 1.0,
    buyMultiplier                 = 1.0,
    sellMultiplier                = 0.5,
    dailyDispCap                  = 5,
    dailyTravelDispCap            = 3,
    haggleBonus                   = 1,
    passiveXpMult                 = 0.5,
    enableLoyalty                 = true,
    enableMerchantScaling         = true,
    enableTransportLoyalty        = true,
    enableRegionalLoyalty         = true,
}

local function getSetting(key)
    local val = settingsSection:get(key)
    if val == nil then return SETTING_DEFAULTS[key] end
    return val
end

local function debugLog(message)
    if getSetting("debugLogging") then
        print("[Fair Trade] " .. tostring(message))
    end
end

-- -----------------------------------------------------------------
-- Push settings to global
-- -----------------------------------------------------------------

local function pushSettingsToGlobal()
    core.sendGlobalEvent("FairTrade_SettingsChanged", {
        enabled                       = getSetting("enabled"),
        showMessages                  = getSetting("showMessages"),
        showTravelDispositionMessages = getSetting("showTravelDispositionMessages"),
        debugLogging                  = getSetting("debugLogging"),
        dispScale                     = getSetting("dispScale"),
        buyMultiplier                 = getSetting("buyMultiplier"),
        sellMultiplier                = getSetting("sellMultiplier"),
        dailyDispCap                  = getSetting("dailyDispCap"),
        dailyTravelDispCap            = getSetting("dailyTravelDispCap"),
        haggleBonus                   = getSetting("haggleBonus"),
        enableLoyalty                 = getSetting("enableLoyalty"),
        enableMerchantScaling         = getSetting("enableMerchantScaling"),
        enableTransportLoyalty        = getSetting("enableTransportLoyalty"),
        enableRegionalLoyalty         = getSetting("enableRegionalLoyalty"),
    })
end

settingsSection:subscribe(async:callback(function(_, _)
    pushSettingsToGlobal()
end))

-- -----------------------------------------------------------------
-- State
-- -----------------------------------------------------------------

local inBarter, inDialogue, inTravel = false, false, false
local barterMerchant, sessionMerchant, dialogueMerchant = nil, nil, nil
local travelOperator, travelOriginCell = nil, nil

local lastGold               = 0
local vanillaMercantileFired = false
local emittingOwnXp          = false
local preBarterDisposition   = nil
local hadTransactions        = false
local lastCommittedTarget    = nil
local queuedGoldRewards      = 0
-- After exiting barter, keep a short-lived watch active so we can
-- neutralize vanilla's delayed +1 even if it lands only after the
-- player leaves and re-enters dialogue. We only fire while not in
-- barter, and never continuously during an open dialogue session.
local leakCorrectionDue      = 0
local leakWatchExpires       = 0
local dialogueJustOpened     = false
local pendingLeakWatch       = false
local lateHaggleCandidate   = nil
local LATE_HAGGLE_WINDOW    = 0.75

-- -----------------------------------------------------------------
-- Utility
-- -----------------------------------------------------------------

local function getPlayerGold()
    return types.Actor.inventory(self):countOf("gold_001")
end

local function getCurrentCellName()
    local cell = self.object.cell
    if not cell then return "Unknown" end
    if cell.name and cell.name ~= "" then return cell.name end
    return tostring(cell)
end

local function isTravelServiceOperator(actor)
    if not actor or not types.NPC.objectIsInstance(actor) then return false end
    local record = types.NPC.record(actor)
    return record and record.servicesOffered and record.servicesOffered.Travel == true
end

-- -----------------------------------------------------------------
-- Gold reward delivery
-- -----------------------------------------------------------------

local function deliverReward(amount, reason)
    amount = math.floor(amount or 0)
    if amount <= 0 then return end
    core.sendGlobalEvent("FairTrade_DeliverQueuedGold", {
        player = self.object,
        amount = amount,
        reason = reason,
    })
end

local function flushQueuedRewards(reason)
    if queuedGoldRewards <= 0 then return end
    deliverReward(queuedGoldRewards, reason)
    debugLog("Flushed queued rewards: " .. queuedGoldRewards .. "g (" .. tostring(reason) .. ")")
    queuedGoldRewards = 0
end

-- -----------------------------------------------------------------
-- SkillProgression handler (re-entrancy guarded)
-- -----------------------------------------------------------------

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if emittingOwnXp then return end
    if skillId == "mercantile"
       and params.useType == I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success then
        local now = core.getSimulationTime()
        if lateHaggleCandidate
           and lateHaggleCandidate.merchant
           and now <= lateHaggleCandidate.expires then
            core.sendGlobalEvent("FairTrade_HaggleBonus", {
                merchant       = lateHaggleCandidate.merchant,
                player         = self.object,
                trackAsPending = inBarter,
            })
            debugLog("Late haggle signal matched to previous barter transaction")
            lateHaggleCandidate = nil
            vanillaMercantileFired = false
        else
            vanillaMercantileFired = true
            debugLog("Mercantile success signal captured for next barter transaction")
        end
    end
end)

-- -----------------------------------------------------------------
-- Events from global
-- -----------------------------------------------------------------

local function onFairTradeMessage(data)
    if not data or not data.message then return end
    ui.showMessage(data.message)
end

local function onQueueReward(data)
    if not data or not data.amount then return end
    local amount = math.floor(data.amount)
    if amount <= 0 then return end

    if not inBarter and not inTravel then
        deliverReward(amount, data.reason)
        debugLog("Delivered reward immediately: +" .. amount .. "g")
        return
    end

    queuedGoldRewards = queuedGoldRewards + amount
    debugLog("Queued reward: +" .. amount .. "g (total queued: " .. queuedGoldRewards .. "g)")
end

local function armLeakWatchIfPending()
    if not pendingLeakWatch then return end
    if lastCommittedTarget == nil or not sessionMerchant then return end

    leakCorrectionDue = core.getSimulationTime() + LEAK_SETTLE_DELAY
    leakWatchExpires = leakCorrectionDue + LEAK_WATCH_WINDOW
    pendingLeakWatch = false
    debugLog("Armed leak watch at committed floor: " .. tostring(lastCommittedTarget))
end

local function onUpdateRestoreTarget(data)
    if data and data.newTarget ~= nil then
        preBarterDisposition = data.newTarget
        lastCommittedTarget  = data.newTarget
        debugLog("Updated restore target to: " .. tostring(data.newTarget))
        armLeakWatchIfPending()
    end
end

-- -----------------------------------------------------------------
-- Transaction detection
-- -----------------------------------------------------------------

local function onBarterTransactionDetected(goldDelta)
    if not getSetting("enabled") then return end

    local absValue = math.abs(goldDelta)
    if absValue == 0 then return end

    local isBuying = goldDelta < 0
    debugLog("Barter transaction: " .. goldDelta .. "g | " .. (isBuying and "BUY" or "SELL"))

    local merchantBaseGold = 0
    if barterMerchant and types.NPC.objectIsInstance(barterMerchant) then
        local record = types.NPC.record(barterMerchant)
        if record then merchantBaseGold = record.baseGold or 0 end
    end

    if barterMerchant then
        core.sendGlobalEvent("FairTrade_Transaction", {
            merchant         = barterMerchant,
            player           = self.object,
            absValue         = absValue,
            isBuying         = isBuying,
            didHaggle        = vanillaMercantileFired,
            merchantBaseGold = merchantBaseGold,
        })

        if not vanillaMercantileFired then
            -- OpenMW can emit Mercantile_Success just after the gold total
            -- changes. Keep a short candidate window so a late skill signal can
            -- still receive the configured haggle disposition bonus.
            lateHaggleCandidate = {
                merchant = barterMerchant,
                expires  = core.getSimulationTime() + LATE_HAGGLE_WINDOW,
            }
        else
            lateHaggleCandidate = nil
        end
    end

    if not vanillaMercantileFired then
        local passiveMult = getSetting("passiveXpMult") or 0.5
        if passiveMult > 0 then
            local valueFactor = math.log(absValue + 1) / math.log(10)
            if valueFactor > 1.0 then valueFactor = 1.0 end
            if valueFactor < 0   then valueFactor = 0 end
            local xpGain = passiveMult * valueFactor
            if xpGain > 0 then
                emittingOwnXp = true
                I.SkillProgression.skillUsed("mercantile", {
                    skillGain = xpGain,
                    useType   = I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success,
                })
                emittingOwnXp = false
                debugLog("Passive Mercantile XP: " .. string.format("%.2f", xpGain))
            end
        end
    else
        debugLog("Player haggled - vanilla Mercantile XP applies")
    end

    vanillaMercantileFired = false
end

local function onTravelTransactionDetected(goldDelta)
    if not getSetting("enabled") then return end

    local absValue = math.abs(goldDelta)
    if absValue == 0 or goldDelta >= 0 then return end
    if not travelOperator then return end

    debugLog("Travel transaction: " .. goldDelta .. "g | origin=" .. tostring(travelOriginCell))

    core.sendGlobalEvent("FairTrade_TravelTransaction", {
        operator   = travelOperator,
        player     = self.object,
        absValue   = absValue,
        originCell = travelOriginCell,
    })
end

-- -----------------------------------------------------------------
-- UI-mode transitions
-- -----------------------------------------------------------------

local function onUiModeChanged(data)
    local newMode = data.newMode
    local oldMode = data.oldMode

    if newMode == "Dialogue" and not inDialogue then
        inDialogue = true
        hadTransactions = false
        dialogueMerchant = data.arg or dialogueMerchant
        dialogueJustOpened = true

        if dialogueMerchant and types.NPC.objectIsInstance(dialogueMerchant) then
            core.sendGlobalEvent("FairTrade_DialogueStarted", {
                merchant = dialogueMerchant,
                player   = self.object,
            })
        end
    end

    if newMode == "Barter" then
        inBarter = true
        barterMerchant   = data.arg
        sessionMerchant  = data.arg
        dialogueMerchant = data.arg
        lastGold = getPlayerGold()
        vanillaMercantileFired = false
        lateHaggleCandidate = nil

        preBarterDisposition = nil
        if barterMerchant and types.NPC.objectIsInstance(barterMerchant) then
            preBarterDisposition = types.NPC.getBaseDisposition(barterMerchant, self.object)
        else
            debugLog("Entered barter but arg is not an NPC; skipping disposition snapshot")
        end

        debugLog("Entered barter with disposition snapshot " .. tostring(preBarterDisposition))
    end

    if newMode == "Travel" and isTravelServiceOperator(data.arg) then
        inTravel = true
        travelOperator   = data.arg
        travelOriginCell = getCurrentCellName()
        lastGold = getPlayerGold()
        debugLog("Entered travel from " .. tostring(travelOriginCell))
    end

    if oldMode == "Barter" and newMode ~= "Barter" then
        local currentGold = getPlayerGold()
        local delta = currentGold - lastGold
        if delta ~= 0 then
            hadTransactions = true
            onBarterTransactionDetected(delta)
        end

        if preBarterDisposition ~= nil and sessionMerchant then
            -- Ask the global script to commit FairTrade gains and report the
            -- final floor back before the leak watcher starts. Starting the
            -- watcher immediately is unsafe: for a +1 FairTrade gain, the
            -- player script can otherwise mistake our own gain for vanilla's
            -- delayed +1 and remove it before the dialogue UI refreshes.
            pendingLeakWatch = hadTransactions
            leakCorrectionDue = 0
            leakWatchExpires = 0
            lastCommittedTarget = nil
            core.sendGlobalEvent("FairTrade_RestoreDisposition", {
                merchant          = sessionMerchant,
                player            = self.object,
                targetDisposition = preBarterDisposition,
                commitGains       = true,
            })
        end

        inBarter = false
        barterMerchant = nil
        flushQueuedRewards("barter")
        debugLog("Left barter")
    end

    if oldMode == "Travel" and inTravel then
        local currentGold = getPlayerGold()
        local delta = currentGold - lastGold
        if delta ~= 0 then
            onTravelTransactionDetected(delta)
        end

        inTravel = false
        travelOperator = nil
        travelOriginCell = nil
        flushQueuedRewards("travel")
        debugLog("Left travel")
    end

    if oldMode == "Dialogue" and newMode ~= "Dialogue" and newMode ~= "Barter" then
        inDialogue = false
        dialogueJustOpened = false
        hadTransactions = false
        -- Keep the leak watch alive briefly after dialogue closes so
        -- a delayed vanilla +1 can still be neutralized before the
        -- player starts a fresh interaction.
        if core.getSimulationTime() > leakWatchExpires then
            lastCommittedTarget = nil
            leakCorrectionDue = 0
            leakWatchExpires = 0
            pendingLeakWatch = false
            dialogueMerchant = nil
            sessionMerchant = nil
        end
    end
end

-- -----------------------------------------------------------------
-- Per-frame update
-- -----------------------------------------------------------------

local function onUpdate(dt)
    if not getSetting("enabled") then return end

    if lateHaggleCandidate and core.getSimulationTime() > lateHaggleCandidate.expires then
        lateHaggleCandidate = nil
    end

    if inBarter then
        local currentGold = getPlayerGold()
        if currentGold ~= lastGold then
            local delta = currentGold - lastGold
            lastGold = currentGold
            hadTransactions = true
            onBarterTransactionDetected(delta)
        end
    elseif sessionMerchant and lastCommittedTarget ~= nil
           and leakWatchExpires > 0
           and core.getSimulationTime() <= leakWatchExpires
           and core.getSimulationTime() >= leakCorrectionDue
           and not inBarter then
        core.sendGlobalEvent("FairTrade_NeutralizeVanillaLeak", {
            merchant         = sessionMerchant,
            player           = self.object,
            floorDisposition = lastCommittedTarget,
            maxDelta         = LEAK_MAX_CORRECTION,
        })
        if dialogueJustOpened then
            debugLog("Leak check fired on dialogue entry")
            dialogueJustOpened = false
        else
            debugLog("Leak check fired during high-frequency watch")
        end

        -- While the short watch window is active, poll every frame so
        -- the vanilla +1 gets stripped before the player can really
        -- notice it on a dialogue reopen.
        leakCorrectionDue = core.getSimulationTime()
    elseif leakWatchExpires > 0 and core.getSimulationTime() > leakWatchExpires then
        leakCorrectionDue = 0
        leakWatchExpires = 0
        lastCommittedTarget = nil
        dialogueMerchant = nil
        sessionMerchant = nil
        dialogueJustOpened = false
        pendingLeakWatch = false
    elseif inTravel then
        local currentGold = getPlayerGold()
        if currentGold ~= lastGold then
            local delta = currentGold - lastGold
            lastGold = currentGold
            onTravelTransactionDetected(delta)
        end
    end
end

-- -----------------------------------------------------------------
-- Init / Load — push settings to global
-- -----------------------------------------------------------------

local function onInit()
    pushSettingsToGlobal()
end

local function onLoad()
    pushSettingsToGlobal()
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInit   = onInit,
        onLoad   = onLoad,
    },
    eventHandlers = {
        UiModeChanged                 = onUiModeChanged,
        FairTrade_Message             = onFairTradeMessage,
        FairTrade_UpdateRestoreTarget = onUpdateRestoreTarget,
        FairTrade_QueueReward         = onQueueReward,
    },
}
