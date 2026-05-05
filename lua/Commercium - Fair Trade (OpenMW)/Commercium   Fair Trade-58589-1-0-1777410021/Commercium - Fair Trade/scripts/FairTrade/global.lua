--[[
    Fair Trade - Global Script

    Handles:
      - Barter transaction outcomes (disposition, per-merchant loyalty,
        merchant-type scaling, rebate queueing)
      - Travel transaction outcomes (per-operator loyalty, vouchers,
        disposition)
      - Regional loyalty (cumulative spending per region -> welcome
        disposition for unmet merchants + region-wide rebates)
      - Vanilla +1 disposition leak neutralization
      - Gold delivery into player inventory
]]

local core  = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local MODNAME = "FairTrade"
local L10N    = "FairTrade"

-- -----------------------------------------------------------------
-- Tunable constants
-- -----------------------------------------------------------------

local MERCHANT_SCALE_BASE_GOLD   = 500
local MERCHANT_SCALE_FLOOR       = 0.6
local MERCHANT_SCALE_COEFF       = 0.4
local MERCHANT_SELL_SCALE_SOFTEN = 0.5
local REBATE_COMBINED_CAP_PCT    = 5
local SECS_PER_DAY               = 86400

-- -----------------------------------------------------------------
-- Cached settings (populated by FairTrade_SettingsChanged events)
-- -----------------------------------------------------------------

local settings = {
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
    enableLoyalty                 = true,
    enableMerchantScaling         = true,
    enableTransportLoyalty        = true,
    enableRegionalLoyalty         = true,
}

local function getSetting(key) return settings[key] end

-- -----------------------------------------------------------------
-- Loyalty tier definitions
-- -----------------------------------------------------------------

local LOYALTY_TIERS = {
    { threshold = 1000,  name = "Familiar",  messageKey = "loyalty_familiar",  discount = 1 },
    { threshold = 5000,  name = "Valued",    messageKey = "loyalty_valued",    discount = 2 },
    { threshold = 10000, name = "Preferred", messageKey = "loyalty_preferred", discount = 3 },
    { threshold = 50000, name = "Honoured",  messageKey = "loyalty_honoured",  discount = 5 },
}

local TRAVEL_TIERS = {
    { threshold = 3,  name = "Known Passenger",    discount = 5,  voucherChance = 0.00, messageKey = "travel_known" },
    { threshold = 7,  name = "Trusted Passenger",  discount = 7,  voucherChance = 0.03, messageKey = "travel_trusted" },
    { threshold = 12, name = "Favoured Passenger", discount = 10, voucherChance = 0.05, messageKey = "travel_favoured" },
    { threshold = 18, name = "Regular Patron",     discount = 12, voucherChance = 0.08, messageKey = "travel_regular" },
    { threshold = 25, name = "Local Fixture",      discount = 15, voucherChance = 0.12, messageKey = "travel_fixture" },
}

local REGIONAL_TIERS = {
    { threshold = 10000, name = "Known in Region",     welcomeDisp = 1, rebatePct = 0, messageKey = "regional_known" },
    { threshold = 25000, name = "Respected in Region", welcomeDisp = 3, rebatePct = 1, messageKey = "regional_respected" },
    { threshold = 50000, name = "Renowned in Region",  welcomeDisp = 5, rebatePct = 3, messageKey = "regional_renowned" },
}

local TRAVEL_SERVICE_PATTERNS = {
    { key = "mages guild guide", serviceType = "Mages Guild guide" },
    { key = "guild guide",       serviceType = "Mages Guild guide" },
    { key = "gondolier",         serviceType = "Gondolier" },
    { key = "boat",              serviceType = "Boat" },
    { key = "shipmaster",        serviceType = "Boat" },
    { key = "silt strider",      serviceType = "Silt strider" },
    { key = "caravaner",         serviceType = "Silt strider" },
}

-- -----------------------------------------------------------------
-- Persistent state
-- -----------------------------------------------------------------

local dailyDispGains       = {}
local dailyCapNotices      = {}
local dailyTravelDispGains = {}
local travelCapNotices     = {}
local lastDay              = -1
local loyaltyData          = {}
local travelLoyaltyData    = {}
local regionalData         = {}
local pendingDispGains     = {}  -- ephemeral

-- -----------------------------------------------------------------
-- Utility
-- -----------------------------------------------------------------

local function debugLog(message)
    if getSetting("debugLogging") then
        print("[Fair Trade Global] " .. tostring(message))
    end
end

local function getCurrentDay()
    return math.floor(core.getGameTime() / SECS_PER_DAY)
end

local function resetDailyIfNeeded()
    local today = getCurrentDay()
    if today ~= lastDay then
        dailyDispGains       = {}
        dailyCapNotices      = {}
        dailyTravelDispGains = {}
        travelCapNotices     = {}
        lastDay              = today
    end
end

local function calcDispositionGain(absValue, dispScale)
    if absValue <= 0 then return 0 end
    return (math.log(absValue + 1) / math.log(10)) * dispScale
end

local function lfmt(key, ...)
    local L = core.l10n(L10N)
    local template = L(key) or key
    local ok, result = pcall(string.format, template, ...)
    if ok then return result end
    return template
end

local function sendMessage(player, message, kind)
    if not getSetting("showMessages") then return end
    if kind == "travelDisposition" and not getSetting("showTravelDispositionMessages") then
        return
    end
    player:sendEvent("FairTrade_Message", { message = message })
end

local function queueReward(player, amount, reason)
    if amount and amount > 0 then
        player:sendEvent("FairTrade_QueueReward", {
            amount = math.floor(amount),
            reason = reason,
        })
    end
end

local function merchantDisplayName(merchant)
    local record = merchant and types.NPC.record(merchant)
    return (record and record.name) or (merchant and merchant.recordId) or "the merchant"
end

-- -----------------------------------------------------------------
-- Travel service classification
-- -----------------------------------------------------------------

local function normalizeServiceType(operator)
    local record = types.NPC.record(operator)
    local name = ((record and record.name) or operator.recordId or "travel"):lower()
    local recordId = (operator.recordId or ""):lower()

    for _, pattern in ipairs(TRAVEL_SERVICE_PATTERNS) do
        if name:find(pattern.key, 1, true) or recordId:find(pattern.key, 1, true) then
            return pattern.serviceType
        end
    end
    return "Travel service"
end

local function getTravelKey(operator)
    local recordId = operator and operator.recordId
    if recordId and recordId ~= "" then return recordId:lower() end
    local record = operator and types.NPC.record(operator)
    local name = record and record.name
    if name and name ~= "" then return string.lower(name) end
    return normalizeServiceType(operator):lower()
end

local function getTravelDiscount(key)
    local data = travelLoyaltyData[key]
    if not data or data.tier == 0 then return 0 end
    return TRAVEL_TIERS[data.tier].discount or 0
end

local function getTravelVoucherChance(key)
    local data = travelLoyaltyData[key]
    if not data or data.tier == 0 then return 0 end
    return TRAVEL_TIERS[data.tier].voucherChance or 0
end

-- -----------------------------------------------------------------
-- Regional loyalty
-- -----------------------------------------------------------------

local function getRegionForMerchant(merchant)
    local cell = merchant and merchant.cell
    if not cell then return nil, nil end

    local regionId = cell.region
    if regionId and regionId ~= "" then
        local rec = core.regions.records[regionId]
        local displayName = (rec and rec.name) or regionId
        return regionId:lower(), displayName
    end

    local cname = cell.name or ""
    if cname ~= "" then
        local prefix = cname:match("^([^,]+)")
        if prefix and prefix ~= "" then
            local trimmed = prefix:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then return trimmed:lower(), trimmed end
        end
    end
    return nil, nil
end

local function getRegionalTierIndex(spent)
    local tierIdx = 0
    for i, tier in ipairs(REGIONAL_TIERS) do
        if spent >= tier.threshold then tierIdx = i end
    end
    return tierIdx
end

local function getRegionalWelcomeDisposition(regionKey)
    local data = regionalData[regionKey]
    if not data or data.tier == 0 then return 0 end
    return REGIONAL_TIERS[data.tier].welcomeDisp or 0
end

local function getRegionalRebatePct(regionKey)
    local data = regionalData[regionKey]
    if not data or data.tier == 0 then return 0 end
    return REGIONAL_TIERS[data.tier].rebatePct or 0
end

local function applyRegionalWelcome(merchant, player, regionKey)
    if not regionKey then return end
    local data = regionalData[regionKey]
    if not data or not data.metMerchants then return end

    local merchantId = merchant.recordId
    if data.metMerchants[merchantId] then return end
    data.metMerchants[merchantId] = true

    local welcome = getRegionalWelcomeDisposition(regionKey)
    if welcome <= 0 then return end

    types.NPC.modifyBaseDisposition(merchant, player, welcome)
    sendMessage(player, lfmt("msg_regional_welcome", merchantDisplayName(merchant)))
    debugLog("Regional welcome: +" .. welcome .. " to " .. merchantDisplayName(merchant)
             .. " in region " .. regionKey)
end

local function processRegionalSpending(merchant, player, absValue, isBuying)
    if not getSetting("enableRegionalLoyalty") then return nil end
    if not isBuying or absValue <= 0 then return nil end

    local regionKey, regionName = getRegionForMerchant(merchant)
    if not regionKey then return nil end

    if not regionalData[regionKey] then
        regionalData[regionKey] = {
            spent = 0, tier = 0, name = regionName, metMerchants = {},
        }
    end
    local data = regionalData[regionKey]
    data.metMerchants = data.metMerchants or {}
    data.name = data.name or regionName

    -- If this trade is still building the region's reputation from zero,
    -- mark the current merchant as already met before any tier-up. This
    -- prevents the trade that unlocks a regional tier from also receiving
    -- the new welcome bonus retroactively. Once a regional tier already
    -- exists, new merchants are left unmarked here so applyRegionalWelcome
    -- can grant the one-time welcome bonus before marking them as met.
    local oldTier = data.tier or 0
    if oldTier == 0 then
        data.metMerchants[merchant.recordId] = true
    end

    data.spent = data.spent + absValue
    local newTier = getRegionalTierIndex(data.spent)

    if newTier > oldTier then
        data.tier = newTier
        local tierDef = REGIONAL_TIERS[newTier]
        sendMessage(player, lfmt(tierDef.messageKey, data.name))
        debugLog("Regional tier up: " .. regionKey .. " -> " .. tierDef.name
                 .. " (spent: " .. data.spent .. "g)")
    end
    return regionKey
end

-- -----------------------------------------------------------------
-- Per-merchant loyalty
-- -----------------------------------------------------------------

local function getMerchantDiscountPct(merchantId)
    local data = loyaltyData[merchantId]
    if not data or data.tier == 0 then return 0 end
    return LOYALTY_TIERS[data.tier].discount or 0
end

local function processLoyalty(merchant, player, absValue, isBuying, regionKey)
    if not getSetting("enableLoyalty") then return end

    local merchantId = merchant.recordId
    if not loyaltyData[merchantId] then
        loyaltyData[merchantId] = { spent = 0, tier = 0 }
    end
    local data = loyaltyData[merchantId]
    local oldTier = data.tier

    if isBuying then data.spent = data.spent + absValue end

    local newTier = 0
    for i, tier in ipairs(LOYALTY_TIERS) do
        if data.spent >= tier.threshold then newTier = i end
    end

    if newTier > oldTier then
        data.tier = newTier
        local tierDef = LOYALTY_TIERS[newTier]
        local merchantName = merchantDisplayName(merchant)
        local msg = tierDef.discount > 1
            and lfmt(tierDef.messageKey, merchantName, tierDef.discount)
            or  lfmt(tierDef.messageKey, merchantName)
        sendMessage(player, msg)
        debugLog("Loyalty tier up: " .. merchantName .. " -> " .. tierDef.name
                 .. " (spent: " .. data.spent .. "g)")
    end

    if isBuying and absValue > 0 then
        local merchantPct = getMerchantDiscountPct(merchantId)
        local regionalPct = regionKey and getRegionalRebatePct(regionKey) or 0
        local combinedPct = merchantPct + regionalPct
        if combinedPct > REBATE_COMBINED_CAP_PCT then
            combinedPct = REBATE_COMBINED_CAP_PCT
        end
        if combinedPct > 0 then
            local refund = math.floor(absValue * combinedPct / 100)
            if refund > 0 then
                local reason
                if merchantPct > 0 and regionalPct > 0 then
                    reason = "merchantRebate"
                elseif regionalPct > 0 then
                    reason = "regionalRebate"
                else
                    reason = "merchantRebate"
                end
                queueReward(player, refund, reason)
                debugLog("Queued rebate " .. refund .. "g (merchant=" .. merchantPct
                         .. "%, region=" .. regionalPct .. "%)")
            end
        end
    end
end

-- -----------------------------------------------------------------
-- Travel loyalty
-- -----------------------------------------------------------------

local function processTravelLoyalty(operator, player, absValue, originCell)
    local key = getTravelKey(operator)
    local serviceType = normalizeServiceType(operator)
    local operatorRecord = types.NPC.record(operator)
    local operatorName = (operatorRecord and operatorRecord.name) or operator.recordId or key

    if not travelLoyaltyData[key] then
        travelLoyaltyData[key] = { trips = 0, tier = 0, vouchers = 0 }
    end
    local data = travelLoyaltyData[key]
    local oldTier = data.tier
    data.trips = (data.trips or 0) + 1

    local newTier = 0
    for i, tier in ipairs(TRAVEL_TIERS) do
        if data.trips >= tier.threshold then newTier = i end
    end

    if newTier > oldTier then
        data.tier = newTier
        local tierDef = TRAVEL_TIERS[newTier]
        sendMessage(player, lfmt(tierDef.messageKey, operatorName, serviceType))
        debugLog("Travel tier up: " .. operatorName .. " [" .. key .. "] -> " .. tierDef.name
                 .. " (trips: " .. data.trips .. ")")
    end

    if (data.vouchers or 0) > 0 then
        data.vouchers = data.vouchers - 1
        queueReward(player, absValue, "travelVoucherUsed")
        debugLog("Travel voucher consumed on " .. operatorName .. ": refunded " .. absValue .. "g")
    else
        local discount = getTravelDiscount(key)
        if discount > 0 then
            local refund = math.floor(absValue * discount / 100)
            if refund > 0 then
                queueReward(player, refund, "travelDiscount")
                debugLog("Travel rebate " .. refund .. "g for " .. operatorName)
            end
        end
    end

    local dispCap = getSetting("dailyTravelDispCap") or 0
    local gainedToday = dailyTravelDispGains[key] or 0
    if dispCap == 0 or gainedToday < dispCap then
        types.NPC.modifyBaseDisposition(operator, player, 1)
        dailyTravelDispGains[key] = gainedToday + 1
        sendMessage(player, lfmt("msg_travel_disposition", operatorName), "travelDisposition")
        debugLog("Travel disposition +1 with " .. operatorName)
    elseif not travelCapNotices[key] then
        travelCapNotices[key] = true
        sendMessage(player, lfmt("msg_daily_travel_cap_reached", operatorName))
    end

    local voucherChance = getTravelVoucherChance(key)
    if voucherChance > 0 then
        local mix = (math.random() + core.getSimulationTime()) % 1.0
        if mix < voucherChance then
            data.vouchers = (data.vouchers or 0) + 1
            sendMessage(player, lfmt("msg_voucher_awarded", operatorName))
            debugLog("Voucher awarded by " .. operatorName)
        end
    end
end

-- -----------------------------------------------------------------
-- Merchant-type scaling
-- -----------------------------------------------------------------

local function getMerchantScaleFactor(merchantBaseGold)
    if merchantBaseGold <= 0 then return 1.0 end
    local ratio = merchantBaseGold / MERCHANT_SCALE_BASE_GOLD
    if ratio <= 1 then return 1.0 end
    local scale = math.min(math.log(ratio) / math.log(10), 1.0)
    local factor = 1.0 - MERCHANT_SCALE_COEFF * scale
    if factor < MERCHANT_SCALE_FLOOR then factor = MERCHANT_SCALE_FLOOR end
    return factor
end

-- -----------------------------------------------------------------
-- Main transaction handler
-- -----------------------------------------------------------------

local function onTransaction(data)
    if not getSetting("enabled") then return end

    local merchant = data.merchant
    local player   = data.player
    local absValue = data.absValue
    local isBuying = data.isBuying
    local didHaggle = data.didHaggle
    local merchantBaseGold = data.merchantBaseGold or 0

    if not merchant or not player or not types.NPC.objectIsInstance(merchant) then
        debugLog("Missing or invalid merchant in transaction event")
        return
    end

    resetDailyIfNeeded()

    local merchantId = merchant.recordId
    local merchantName = merchantDisplayName(merchant)

    local regionKey = processRegionalSpending(merchant, player, absValue, isBuying)
    applyRegionalWelcome(merchant, player, regionKey)

    local dispScale      = getSetting("dispScale") or 1.0
    local buyMultiplier  = getSetting("buyMultiplier") or 1.0
    local sellMultiplier = getSetting("sellMultiplier") or 0.5
    local dailyDispCap   = getSetting("dailyDispCap") or 5
    local haggleBonus    = getSetting("haggleBonus") or 1

    local rawGain = calcDispositionGain(absValue, dispScale)
    rawGain = rawGain * (isBuying and buyMultiplier or sellMultiplier)

    if getSetting("enableMerchantScaling") and merchantBaseGold > 0 then
        local scaleFactor = getMerchantScaleFactor(merchantBaseGold)
        if not isBuying then
            scaleFactor = 1.0 - (1.0 - scaleFactor) * MERCHANT_SELL_SCALE_SOFTEN
        end
        rawGain = rawGain * scaleFactor
        debugLog("Merchant scaling: " .. merchantName .. " factor="
                 .. string.format("%.2f", scaleFactor))
    end

    local gain = math.floor(rawGain)
    if didHaggle and haggleBonus > 0 then gain = gain + haggleBonus end

    local gainedToday = dailyDispGains[merchantId] or 0

    if dailyDispCap > 0 and gainedToday >= dailyDispCap then
        if not dailyCapNotices[merchantId] then
            dailyCapNotices[merchantId] = true
            sendMessage(player, lfmt("msg_daily_cap_reached", merchantName))
        end
        processLoyalty(merchant, player, absValue, isBuying, regionKey)
        return
    end

    if gain <= 0 then
        sendMessage(player, lfmt("msg_transaction_too_small", merchantName))
        debugLog("No disposition gain: transaction below threshold for " .. merchantName)
        processLoyalty(merchant, player, absValue, isBuying, regionKey)
        return
    end

    if dailyDispCap > 0 then
        gain = math.min(gain, dailyDispCap - gainedToday)
    end

    -- Apply the earned disposition immediately while barter is still the active
    -- UI mode. If we wait until the Barter -> Dialogue transition, OpenMW can
    -- rebuild the dialogue UI from the old cached disposition and the player
    -- will not see the gain until they close and reopen dialogue. We still
    -- remember the gain so the restore/leak-neutralisation pass can set the
    -- final floor to preBarterDisposition + our gains and strip only vanilla's
    -- delayed +1.
    types.NPC.modifyBaseDisposition(merchant, player, gain)
    pendingDispGains[merchantId] = (pendingDispGains[merchantId] or 0) + gain
    dailyDispGains[merchantId] = gainedToday + gain

    local msgKey = didHaggle and haggleBonus > 0 and "msg_disposition_gain_haggle" or "msg_disposition_gain"
    sendMessage(player, lfmt(msgKey, gain, merchantName))
    debugLog("Applied disposition immediately: " .. merchantName .. " +" .. gain)

    processLoyalty(merchant, player, absValue, isBuying, regionKey)
end

local function onHaggleBonus(data)
    if not getSetting("enabled") then return end

    local merchant = data and data.merchant
    local player   = data and data.player
    if not merchant or not player or not types.NPC.objectIsInstance(merchant) then return end

    resetDailyIfNeeded()

    local haggleBonus = getSetting("haggleBonus") or 1
    if haggleBonus <= 0 then return end

    local dailyDispCap = getSetting("dailyDispCap") or 5
    local merchantId = merchant.recordId
    local merchantName = merchantDisplayName(merchant)
    local gainedToday = dailyDispGains[merchantId] or 0

    if dailyDispCap > 0 and gainedToday >= dailyDispCap then
        if not dailyCapNotices[merchantId] then
            dailyCapNotices[merchantId] = true
            sendMessage(player, lfmt("msg_daily_cap_reached", merchantName))
        end
        debugLog("Late haggle bonus skipped: daily cap reached for " .. merchantName)
        return
    end

    local gain = haggleBonus
    if dailyDispCap > 0 then
        gain = math.min(gain, dailyDispCap - gainedToday)
    end
    if gain <= 0 then return end

    types.NPC.modifyBaseDisposition(merchant, player, gain)
    dailyDispGains[merchantId] = gainedToday + gain

    if data.trackAsPending then
        pendingDispGains[merchantId] = (pendingDispGains[merchantId] or 0) + gain
    else
        -- If the late skill signal arrives after the restore/commit pass, move
        -- the player-side leak floor forward so our bonus is not mistaken for
        -- vanilla's delayed +1.
        player:sendEvent("FairTrade_UpdateRestoreTarget", {
            newTarget = types.NPC.getBaseDisposition(merchant, player),
        })
    end

    sendMessage(player, lfmt("msg_disposition_gain_haggle", gain, merchantName))
    debugLog("Applied late haggle disposition bonus: " .. merchantName .. " +" .. gain)
end

-- -----------------------------------------------------------------
-- Dialogue entry
-- -----------------------------------------------------------------

local function onDialogueStarted(data)
    if not getSetting("enabled") or not getSetting("enableRegionalLoyalty") then return end

    local merchant = data and data.merchant
    local player   = data and data.player
    if not merchant or not player or not types.NPC.objectIsInstance(merchant) then return end

    local regionKey = getRegionForMerchant(merchant)
    applyRegionalWelcome(merchant, player, regionKey)
end

-- -----------------------------------------------------------------
-- Travel / Gold / Leak handlers
-- -----------------------------------------------------------------

local function onTravelTransaction(data)
    if not getSetting("enabled") or not getSetting("enableTransportLoyalty") then return end

    local operator = data.operator
    local player   = data.player
    local absValue = data.absValue
    local originCell = data.originCell

    if not operator or not player or not types.NPC.objectIsInstance(operator) then
        debugLog("Missing or invalid travel operator")
        return
    end

    resetDailyIfNeeded()
    processTravelLoyalty(operator, player, absValue, originCell)
end

local function onDeliverQueuedGold(data)
    local player = data.player
    local amount = math.floor(data.amount or 0)
    if not player or amount <= 0 then return end

    local gold = world.createObject("gold_001", amount)
    gold:moveInto(types.Actor.inventory(player))

    local reason = data.reason
    if reason == "travelDiscount" then
        sendMessage(player, lfmt("msg_travel_discount", amount))
    elseif reason == "travelVoucherUsed" then
        sendMessage(player, lfmt("msg_travel_voucher_used", amount))
    elseif reason == "merchantRebate" then
        sendMessage(player, lfmt("msg_merchant_rebate", amount))
    elseif reason == "regionalRebate" then
        sendMessage(player, lfmt("msg_regional_rebate", amount))
    else
        sendMessage(player, lfmt("msg_gold_received", amount))
    end
end

local function onNeutralizeVanillaLeak(data)
    local merchant = data.merchant
    local player   = data.player
    local floorDisposition = data.floorDisposition
    local maxDelta = data.maxDelta or 1
    if not merchant or not player or floorDisposition == nil then return end
    if not types.NPC.objectIsInstance(merchant) then return end

    local current = types.NPC.getBaseDisposition(merchant, player)
    local gap = current - floorDisposition
    -- Only correct if the gap is positive and within maxDelta. A
    -- gap larger than maxDelta indicates another source (persuasion,
    -- another mod, a quest script) changed disposition between
    -- commit and settle
    if gap > 0 and gap <= maxDelta then
        types.NPC.modifyBaseDisposition(merchant, player, -gap)
        debugLog("Neutralized disposition leak: " .. current .. " -> " .. (current - gap)
                 .. " (gap=" .. gap .. ", maxDelta=" .. maxDelta .. ")")
    elseif gap > maxDelta then
        debugLog("Skipping leak correction: gap=" .. gap .. " exceeds maxDelta="
                 .. maxDelta .. "; probably persuasion or external change")
    end
end

local function onRestoreDisposition(data)
    local merchant = data.merchant
    local player   = data.player
    local target   = data.targetDisposition
    if not merchant or not player or target == nil then return end
    if not types.NPC.objectIsInstance(merchant) then return end

    local merchantId = merchant.recordId
    local ourGains = pendingDispGains[merchantId] or 0
    local finalTarget = target + ourGains
    local current = types.NPC.getBaseDisposition(merchant, player)

    if current ~= finalTarget then
        types.NPC.setBaseDisposition(merchant, player, finalTarget)
    end

    if data.commitGains then
        -- Always acknowledge the committed floor. The player-side leak watcher
        -- waits for this value before stripping vanilla's delayed +1, otherwise
        -- a legitimate +1 FairTrade gain can be mistaken for the leak.
        pendingDispGains[merchantId] = nil
        player:sendEvent("FairTrade_UpdateRestoreTarget", { newTarget = finalTarget })
    elseif ourGains > 0 then
        pendingDispGains[merchantId] = nil
        player:sendEvent("FairTrade_UpdateRestoreTarget", { newTarget = finalTarget })
    end
end

-- -----------------------------------------------------------------
-- Settings push from player
-- -----------------------------------------------------------------

local function onSettingsChanged(data)
    if type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
end

-- -----------------------------------------------------------------
-- Save / Load
-- -----------------------------------------------------------------

local function onSave()
    return {
        dailyDispGains       = dailyDispGains,
        dailyCapNotices      = dailyCapNotices,
        dailyTravelDispGains = dailyTravelDispGains,
        travelCapNotices     = travelCapNotices,
        lastDay              = lastDay,
        loyaltyData          = loyaltyData,
        travelLoyaltyData    = travelLoyaltyData,
        regionalData         = regionalData,
    }
end

local function onLoad(data)
    if data then
        dailyDispGains       = data.dailyDispGains       or {}
        dailyCapNotices      = data.dailyCapNotices      or {}
        dailyTravelDispGains = data.dailyTravelDispGains or {}
        travelCapNotices     = data.travelCapNotices     or {}
        lastDay              = data.lastDay              or -1
        loyaltyData          = data.loyaltyData          or {}
        travelLoyaltyData    = data.travelLoyaltyData    or {}
        regionalData         = data.regionalData         or {}
    else
        dailyDispGains, dailyCapNotices = {}, {}
        dailyTravelDispGains, travelCapNotices = {}, {}
        lastDay = -1
        loyaltyData, travelLoyaltyData, regionalData = {}, {}, {}
    end
    pendingDispGains = {}
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
    eventHandlers = {
        FairTrade_Transaction           = onTransaction,
        FairTrade_HaggleBonus           = onHaggleBonus,
        FairTrade_TravelTransaction     = onTravelTransaction,
        FairTrade_DialogueStarted       = onDialogueStarted,
        FairTrade_DeliverQueuedGold     = onDeliverQueuedGold,
        FairTrade_RestoreDisposition    = onRestoreDisposition,
        FairTrade_NeutralizeVanillaLeak = onNeutralizeVanillaLeak,
        FairTrade_SettingsChanged       = onSettingsChanged,
    },
}
