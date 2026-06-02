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
local ledger  = require('scripts.FairTrade.ui.ledger')

local MODNAME        = "FairTrade"
local L10N           = "FairTrade"
local SETTINGS_GROUP = "SettingsPlayer" .. MODNAME

ledger.registerTrigger()

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
        { key = "showSmallTransactionMessages", renderer = "checkbox", default = true,
          name = "setting_showSmallTransactionMessages", description = "setting_showSmallTransactionMessages_desc" },
        { key = "ledgerHotkey", renderer = "inputBinding", default = "",
          name = "setting_ledgerHotkey", description = "setting_ledgerHotkey_desc",
          argument = { key = "FairTrade_ToggleLedger", type = "trigger" } },
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
    showSmallTransactionMessages  = true,
    ledgerHotkey                  = "",
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
        showSmallTransactionMessages  = getSetting("showSmallTransactionMessages"),
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
local dialogueTopicTravelOperator = nil

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

-- Travel mode often opens without carrying the dialogue actor in
-- UiModeChanged.data.arg. Keep the last NPC who actually talked to the player
-- briefly available so the hotkey and transaction watcher can still resolve
-- the operator without drawing on stale conversations.
local TRAVEL_DIALOGUE_CACHE_WINDOW = 12.0
local cachedDialogueActor          = nil
local cachedDialogueActorUntil     = 0

-- Some barter overhauls finalize sell-side gold one or more frames after the
-- Barter UI closes. The normal in-barter gold watcher sees vanilla/OpenMW
-- trades, but misses those delayed positive gold deltas. Keep a short
-- post-barter watch associated with the last merchant so delayed sales still
-- receive transaction handling and passive XP.
local POST_BARTER_WATCH_WINDOW = 2.0
local postBarterWatchExpires   = 0
local postBarterMerchant       = nil
local postBarterLastGold       = 0

-- Fair Trade's own queued rebates are delivered after barter closes. When the
-- post-barter watcher is active, those positive gold deltas must not be
-- mistaken for sell transactions.
local expectedOwnGoldDelta     = 0
local ledgerBarterHooked       = false

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

local function isNpc(actor)
    return actor ~= nil and types.NPC.objectIsInstance(actor)
end

local function travelDestinationsCount(record)
    local destinations = record and record.travelDestinations
    if not destinations then return 0 end

    local ok, count = pcall(function() return #destinations end)
    if ok and (count or 0) > 0 then return count end

    count = 0
    for _ in pairs(destinations) do
        count = count + 1
        if count > 0 then return count end
    end
    return count
end

local function isTravelServiceOperator(actor)
    if not isNpc(actor) then return false end
    local record = types.NPC.record(actor)
    if not record then return false end

    -- Some travel NPCs expose no Services bit even though their record has
    -- valid travel destinations and the dialogue UI shows the Travel topic.
    -- Use destinations as the primary signal for the ledger and for Travel
    -- mode fallback detection.
    if travelDestinationsCount(record) > 0 then return true end

    return record.servicesOffered and record.servicesOffered.Travel == true
end

local function cacheDialogueActor(actor)
    if not isNpc(actor) then return end
    cachedDialogueActor = actor
    cachedDialogueActorUntil = core.getSimulationTime() + TRAVEL_DIALOGUE_CACHE_WINDOW
end

local function getCachedDialogueActor()
    if not cachedDialogueActor then return nil end
    if core.getSimulationTime() > cachedDialogueActorUntil then
        cachedDialogueActor = nil
        cachedDialogueActorUntil = 0
        return nil
    end
    return cachedDialogueActor
end

local function resolveTravelOperator(modeArg)
    if isTravelServiceOperator(modeArg) then
        cacheDialogueActor(modeArg)
        return modeArg
    end

    if isTravelServiceOperator(dialogueMerchant) then return dialogueMerchant end
    if isTravelServiceOperator(sessionMerchant) then return sessionMerchant end

    -- DialogueResponse fires when the player selects a topic. If a custom
    -- travel implementation exposes the topic before it exposes destinations,
    -- this still lets the ledger identify the active operator.
    if isNpc(dialogueTopicTravelOperator) then return dialogueTopicTravelOperator end

    local cached = getCachedDialogueActor()
    if isTravelServiceOperator(cached) then return cached end

    return nil
end

local function resolveLedgerOperator()
    if isTravelServiceOperator(travelOperator) then return travelOperator end
    if isTravelServiceOperator(dialogueMerchant) then return dialogueMerchant end
    if isTravelServiceOperator(sessionMerchant) then return sessionMerchant end
    if inDialogue and isNpc(dialogueTopicTravelOperator)
       and dialogueTopicTravelOperator == dialogueMerchant then
        return dialogueTopicTravelOperator
    end

    -- Use the short-lived dialogue cache only outside a live dialogue, so the
    -- ledger does not show an old transport operator while the player is now
    -- speaking with an unrelated NPC.
    if not inDialogue then
        local cached = getCachedDialogueActor()
        if isTravelServiceOperator(cached) then return cached end
    end

    return nil
end

-- -----------------------------------------------------------------
-- Gold reward delivery
-- -----------------------------------------------------------------

local function deliverReward(amount, reason)
    amount = math.floor(amount or 0)
    if amount <= 0 then return end
    if postBarterWatchExpires > 0 then
        expectedOwnGoldDelta = expectedOwnGoldDelta + amount
    end
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

local function subtractExpectedOwnGoldDelta(delta)
    if delta <= 0 or expectedOwnGoldDelta <= 0 then return delta end

    local consumed = math.min(delta, expectedOwnGoldDelta)
    expectedOwnGoldDelta = expectedOwnGoldDelta - consumed
    local remaining = delta - consumed

    debugLog("Ignored own queued gold delta: +" .. tostring(consumed)
             .. "g; remaining external delta: " .. tostring(remaining)
             .. "g; expected left: " .. tostring(expectedOwnGoldDelta) .. "g")

    return remaining
end

-- -----------------------------------------------------------------
-- SkillProgression handler (re-entrancy guarded)
-- -----------------------------------------------------------------

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
    if emittingOwnXp then return end
    if skillId == "mercantile"
       and params.useType == I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success then
        -- Treat a Mercantile_Success signal as a real vanilla haggle only if it
        -- actually carries skill progress. Some barter setups/mod combinations
        -- can surface a zero-gain Mercantile_Success during ordinary sales; if
        -- we classify that as haggling, passive XP for selling is incorrectly
        -- suppressed.
        local vanillaGain = tonumber(params.skillGain) or 0
        if vanillaGain <= 0 then
            debugLog("Ignoring zero-gain Mercantile success signal")
            return
        end

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
            debugLog("Mercantile success signal captured for next barter transaction; gain=" .. tostring(vanillaGain))
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

local function onBarterTransactionDetected(goldDelta, merchantOverride)
    if not getSetting("enabled") then return end

    local absValue = math.abs(goldDelta)
    if absValue == 0 then return end

    local isBuying = goldDelta < 0
    local merchant = merchantOverride or barterMerchant
    debugLog("Barter transaction: " .. goldDelta .. "g | " .. (isBuying and "BUY" or "SELL"))

    local merchantBaseGold = 0
    if merchant and types.NPC.objectIsInstance(merchant) then
        local record = types.NPC.record(merchant)
        if record then merchantBaseGold = record.baseGold or 0 end
    end

    if merchant then
        core.sendGlobalEvent("FairTrade_Transaction", {
            merchant         = merchant,
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
                merchant = merchant,
                expires  = core.getSimulationTime() + LATE_HAGGLE_WINDOW,
            }
        else
            lateHaggleCandidate = nil
        end
    end

    if not vanillaMercantileFired then
        local passiveMult = getSetting("passiveXpMult") or 0.5
        if passiveMult > 0 then
            local valueFactor = 0
            if absValue >= 10 then
                valueFactor = math.log(absValue) / math.log(10)
            end
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

local function armPostBarterWatch(merchant, currentGold)
    if not merchant then return end
    postBarterMerchant = merchant
    postBarterLastGold = currentGold
    postBarterWatchExpires = core.getSimulationTime() + POST_BARTER_WATCH_WINDOW
    debugLog("Armed post-barter gold watch at " .. tostring(currentGold) .. "g")
end

local function clearPostBarterWatch(reason)
    if postBarterWatchExpires > 0 then
        debugLog("Cleared post-barter gold watch (" .. tostring(reason) .. ")")
    end
    postBarterWatchExpires = 0
    postBarterMerchant = nil
    postBarterLastGold = 0
end

local function pollPostBarterWatch()
    if postBarterWatchExpires <= 0 then return end

    if core.getSimulationTime() > postBarterWatchExpires then
        clearPostBarterWatch("expired")
        return
    end

    if inBarter or inTravel then return end

    local currentGold = getPlayerGold()
    if currentGold == postBarterLastGold then return end

    local delta = currentGold - postBarterLastGold
    postBarterLastGold = currentGold

    if delta > 0 then
        delta = subtractExpectedOwnGoldDelta(delta)
    end

    -- Only positive delayed deltas are treated as post-barter sales. Negative
    -- deltas after barter are usually unrelated UI/service costs.
    if delta > 0 and postBarterMerchant then
        hadTransactions = true
        debugLog("Post-barter delayed SELL detected: +" .. tostring(delta) .. "g")
        onBarterTransactionDetected(delta, postBarterMerchant)
    elseif delta ~= 0 then
        debugLog("Ignored post-barter gold delta: " .. tostring(delta) .. "g")
    end
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
-- Dialogue tracking
-- -----------------------------------------------------------------

local function onDialogueResponse(e)
    if not e or not isNpc(e.actor) then return end

    dialogueMerchant = e.actor
    cacheDialogueActor(e.actor)

    -- If a modded travel provider exposes a Travel topic before filling the
    -- NPC travel destination list, selecting that topic still gives the ledger
    -- a reasonable operator while this dialogue remains open.
    local recordId = tostring(e.recordId or ''):lower()
    if recordId == 'travel' or recordId == 'destination' or recordId:find('travel', 1, true) then
        dialogueTopicTravelOperator = e.actor
    end
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
        dialogueTopicTravelOperator = nil
        cacheDialogueActor(dialogueMerchant)
        dialogueJustOpened = true

        if dialogueMerchant and types.NPC.objectIsInstance(dialogueMerchant) then
            core.sendGlobalEvent("FairTrade_DialogueStarted", {
                merchant = dialogueMerchant,
                player   = self.object,
            })
        end
    end

    if newMode == "Barter" then
        clearPostBarterWatch("entered barter")
        inBarter = true
        barterMerchant   = data.arg
        sessionMerchant  = data.arg
        dialogueMerchant = data.arg
        cacheDialogueActor(dialogueMerchant)
        lastGold = getPlayerGold()
        vanillaMercantileFired = false
        lateHaggleCandidate = nil
        ledgerBarterHooked = false

        preBarterDisposition = nil
        if barterMerchant and types.NPC.objectIsInstance(barterMerchant) then
            preBarterDisposition = types.NPC.getBaseDisposition(barterMerchant, self.object)
        else
            debugLog("Entered barter but arg is not an NPC; skipping disposition snapshot")
        end

        debugLog("Entered barter with disposition snapshot " .. tostring(preBarterDisposition))
    end

    if newMode == "Travel" then
        local resolvedOperator = resolveTravelOperator(data.arg)
        if resolvedOperator then
            clearPostBarterWatch("entered travel")
            inTravel = true
            travelOperator   = resolvedOperator
            travelOriginCell = getCurrentCellName()
            lastGold = getPlayerGold()
            debugLog("Entered travel with operator " .. tostring(resolvedOperator.recordId)
                     .. " from " .. tostring(travelOriginCell))
        else
            debugLog("Entered travel without a resolved operator from " .. tostring(getCurrentCellName()))
        end
    end

    if oldMode == "Barter" and newMode ~= "Barter" then
        local currentGold = getPlayerGold()
        local delta = currentGold - lastGold
        if delta > 0 then
            delta = subtractExpectedOwnGoldDelta(delta)
        end
        if delta ~= 0 then
            hadTransactions = true
            onBarterTransactionDetected(delta)
        end

        armPostBarterWatch(sessionMerchant, currentGold)

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
        ledgerBarterHooked = false
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
        dialogueTopicTravelOperator = nil
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
            dialogueTopicTravelOperator = nil
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

    pollPostBarterWatch()

    if inBarter then
        if not ledgerBarterHooked then
            ledgerBarterHooked = ledger.hookBarterButton() or false
        end

        local currentGold = getPlayerGold()
        if currentGold ~= lastGold then
            local delta = currentGold - lastGold
            if delta > 0 then
                delta = subtractExpectedOwnGoldDelta(delta)
            end
            lastGold = currentGold
            if delta ~= 0 then
                hadTransactions = true
                onBarterTransactionDetected(delta)
            end
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

local function getLedgerContext()
    return {
        merchant = barterMerchant or dialogueMerchant or sessionMerchant,
        operator = resolveLedgerOperator(),
        inBarter = inBarter,
        inTravel = inTravel,
    }
end

local function onInit()
    ledger.init(getLedgerContext)
    pushSettingsToGlobal()
end

local function onLoad()
    ledger.init(getLedgerContext)
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
        DialogueResponse              = onDialogueResponse,
        FairTrade_Message             = onFairTradeMessage,
        FairTrade_UpdateRestoreTarget = onUpdateRestoreTarget,
        FairTrade_QueueReward         = onQueueReward,
        FairTrade_LedgerSnapshot      = ledger.onSnapshot,
    },
}
