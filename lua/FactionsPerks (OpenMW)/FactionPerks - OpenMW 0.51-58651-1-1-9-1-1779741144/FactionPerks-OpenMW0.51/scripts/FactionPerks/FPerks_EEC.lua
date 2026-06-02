--[[
    EEC:
        FPerks_EEC1_Passive         - +3 Personality, +3 Willpower,
                                      +5 Mercantile, +5 Speechcraft
        FPerks_EEC2_Passive         - +5 Personality, +5 Willpower,
                                      +10 Mercantile, +10 Speechcraft
        FPerks_EEC3_Passive         - +10 Personality, +10 Willpower,
                                      +18 Mercantile, +18 Speechcraft
        FPerks_EEC4_Passive         - +15 Personality, +15 Willpower,
                                      +25 Mercantile, +25 Speechcraft

    Non-table spells (granted once, not removed on rank-up):
        FPerks_EEC4_FactorPromise   - Power (P4)

    Empire's Coffers (P2+):
        The first time the player speaks with a merchant, that merchant's
        available barter gold is permanently boosted by a flat+percentage hybrid
        that scales with perk rank:
            P2: max(250,  floor(baseGold * 0.25))
            P3: max(500,  floor(baseGold * 0.35))
            P4: max(1000, floor(baseGold * 0.50))
        Boosted merchants are tracked per-save (keyed by NPC instance ID).
        Each entry stores the merchant's baseGold and the rank that applied the
        current bonus, enabling retroactive upgrades on rank-up:
          - Immediate: upgradeNearbyMerchants() fires from P3/P4 onAdd and
            applies the delta to all already-boosted merchants in load range.
          - Deferred: eecOnUiModeChanged checks appliedRank vs. current rank
            on every dialogue open and applies any outstanding delta, covering
            merchants who were out of range at rank-up time.
        On perk loss, all currently nearby/loaded merchants are restored.
        Non-nearby merchants retain their bonus until their next natural restock.
        Gold manipulation routes through global.lua since setBarterGold is
        a global-only API.

    Factor's Promise (P4, once/day):
        Grants Fortify Mercantile +100 for 30s.
        While the power is active, Empire's Coffers is tripled in effectiveness
        for any merchant spoken to during the duration. When the power expires
        (detected via activeSpells polling in onUpdate), the extra bonus is
        removed from affected nearby merchants.

        NOTE: Factor bonuses are not restored through save/load cycles.
        The power lasts 30s; by the time a save is loaded, it has certainly
        expired. Factor entries are cleared on load without gold restoration;
        affected merchants will restock naturally.
]]

local ns              = require("scripts.FactionPerks.namespace")
local utils           = require("scripts.FactionPerks.utils")
local perkHidden      = utils.perkHidden
local safeAddSpell    = utils.safeAddSpell
local safeRemoveSpell = utils.safeRemoveSpell
local GUILD           = utils.FACTION_GROUPS.eastEmpireCompany
local interfaces      = require("openmw.interfaces")
local types           = require('openmw.types')
local self            = require('openmw.self')
local core            = require('openmw.core')
local ui              = require('openmw.ui')
local nearby          = require('openmw.nearby')
local storage         = require('openmw.storage')

local R = interfaces.ErnPerkFramework.requirements

-- ============================================================
--  TAMRIEL DATA / STOCK EXCHANGE FRAMEWORK
--  Detected once at load time. If present, Empire's Coffers
--  gains a third bonus component derived from the total value
--  of the player's EEC stock portfolio.
--
--  Global variables (MWScript, synced by ErnPerkFramework):
--    t_glob_stockpriceeec        - current price per EEC share
--    t_glob_stockcountplayereec  - number of shares player holds
--
--  Total portfolio value = price * count.
--  Per-rank stock component:
--    P2: 0.2% of portfolio, capped at 20%  of merchant baseGold
--    P3: 0.5% of portfolio, capped at 50%  of merchant baseGold
--    P4: 1.0% of portfolio, capped at 100% of merchant baseGold
--
--  The ErnPerkFramework global script syncs all MWScript
--  globals into storage.globalSection("ErnPerkFramework_mwVars")
--  every ~3 seconds, keyed by player ID. We read from there
--  directly - no additional global events needed.
-- ============================================================

local hasTamrielData = core.contentFiles.has("Tamriel_Data.esm")

-- Reference to the ErnPerkFramework MWScript variable cache.
-- Only initialised if Tamriel_Data is present to avoid
-- unnecessary storage lookups on every bonus calculation.
local eecMwVars = hasTamrielData
    and storage.globalSection("ErnPerkFramework_mwVars")
    or nil

-- Returns the current total value of the player's EEC stock
-- portfolio, or 0 if Tamriel_Data is not loaded or if the
-- player has not enrolled in the stock exchange.
local function getEECPortfolioValue()
    if not eecMwVars then return 0 end
    local vars  = eecMwVars:get(self.id)
    if not vars then return 0 end
    local price = vars["t_glob_stockpriceeec"]       or 0
    local count = vars["t_glob_stockcountplayereec"] or 0
    return price * count
end

-- Per-rank stock bonus parameters.
-- pct  = fraction of portfolio value applied as bonus
-- cap  = fraction of merchant baseGold that the stock
--        component may not exceed
local EEC_STOCK_BONUS = {
    [2] = { pct = 0.001, cap = 0.20 },
    [3] = { pct = 0.001, cap = 0.50 },
    [4] = { pct = 0.001, cap = 1.00 },
}

local perkTable = {
    [1] = { passive = {"FPerks_EEC1_Passive"} },
    [2] = { passive = {"FPerks_EEC2_Passive"} },
    [3] = { passive = {"FPerks_EEC3_Passive"} },
    [4] = { passive = {"FPerks_EEC4_Passive"} },
}

-- Perk id prep
local eec1_id = ns .. "_eec_company_charter"
local eec2_id = ns .. "_eec_empires_coffers"
local eec3_id = ns .. "_eec_established_routes"
local eec4_id = ns .. "_eec_senior_factor"

local setRank = utils.makeSetRank(perkTable, nil)

-- ============================================================
--  EMPIRE'S COFFERS STATE
-- ============================================================

-- Set true when P2 is acquired; cleared when P2 is removed.
-- Guards all UiModeChanged and onUpdate logic.
local hasEECCoffers = false

-- True while Factor's Promise effects are active on the player.
local eecFactorActive = false

-- Poll interval for Factor's Promise expiry detection.
local eecFactorPollTimer    = 0
local EEC_FACTOR_POLL_INTERVAL = 0.5

-- Tracks the gold bonus currently applied to each merchant.
-- Keyed by npc.id (unique instance ID, not record ID).
-- Value: { baseBonus, totalApplied, baseGold, appliedRank, goldBeforeBonus }
--   baseBonus       = the coffers bonus WITHOUT the Factor's Promise multiplier;
--                     used to calculate how much to remove when the power expires
--   totalApplied    = total gold currently added to this merchant (base + factor);
--                     delta between this and the expected total is applied as a
--                     SINGLE boostMerchant call, eliminating race conditions from
--                     two rapid global events reading stale getBarterGold values
--   baseGold        = the merchant's base gold from their record
--   appliedRank     = the EEC perk rank that produced the current baseBonus
--   goldBeforeBonus = the merchant's actual barter gold at the moment we first
--                     applied a bonus. A restock returns them to exactly this value.
local eecBoostedMerchants = {}

-- ============================================================
--  BONUS CALCULATION
-- ============================================================

-- Per-rank bonus parameters for Empire's Coffers base component.
local EEC_BONUS = {
    [2] = { pct = 0.10, flat = 50  },
    [3] = { pct = 0.25, flat = 150 },
    [4] = { pct = 0.50, flat = 250 },
}

-- Returns the total Empire's Coffers gold bonus for the given
-- merchant baseGold and perk rank, plus a breakdown table.
-- Two return values:
--   bonus     (number) - total gold to apply
--   breakdown (table)  - {
--       baseComponent  = flat or percentage component
--       usedFlat       = true if flat value won over percentage
--       stockComponent = stock portfolio component (0 if no TD)
--   }
-- If Tamriel_Data is loaded, a stock portfolio component is
-- added on top of the base flat/percentage component.
local function calcBaseBonus(baseGold, rank)
    local b = EEC_BONUS[rank]
    if not b then return 0, {} end

    -- Base component: higher of flat value or percentage of baseGold.
    local flatVal    = b.flat
    local pctVal     = math.floor(baseGold * b.pct)
    local usedFlat   = flatVal >= pctVal
    local baseComp   = math.max(flatVal, pctVal)

    -- Stock component (Tamriel_Data only).
       local stockComp = 0
    if hasTamrielData then
        local s         = EEC_STOCK_BONUS[rank] --Gets current rank's stock limits
        local portfolio = getEECPortfolioValue()
        local stockRaw  = (math.floor(portfolio * s.pct)) / 100 -- calculates the percent value of the total stock
        local stockCap  = math.floor(baseGold  * s.cap) -- Sets the cap to the % value of the merchant's base gold
        local stockValue = math.floor(baseGold * stockRaw) -- Sets the % value of the stock amount in regards to the merchant's gold
        stockComp = math.min(stockValue, stockCap) -- Gets the lower value of the current percent value or the rank cap
    end

    local bonus = baseComp + stockComp
    return bonus, {
        baseComponent  = baseComp,
        usedFlat       = usedFlat,
        stockComponent = stockComp,
    }
end

-- Returns the current EEC perk rank (2-4), or nil if below P2.
local function getEECRank()
    if R().hasPerk(eec4_id).check() then return 4 end
    if R().hasPerk(eec3_id).check() then return 3 end
    if R().hasPerk(eec2_id).check() then return 2 end
    return nil
end

-- ============================================================
--  FLAVOUR MESSAGES
-- ============================================================

-- Builds the Empire's Coffers application message from a bonus
-- breakdown table. The base line differs depending on whether
-- the flat or percentage component won; a stock line is
-- appended when the stock component is non-zero.
local function buildCoffersMsg(npc, breakdown)
    local name  = types.NPC.record(npc).name or "The merchant"
    local base  = breakdown.baseComponent  or 0
    local stock = breakdown.stockComponent or 0

    local baseLine
    if breakdown.usedFlat then
        baseLine = "The Company's standing credit opens " .. name
            .. "'s strongbox - " .. tostring(base) .. " gold."
    else
        baseLine = "Recognising the scale of your dealings, " .. name
            .. " opens their full reserves - " .. tostring(base) .. " gold."
    end

    local stockLine = ""
    if stock > 0 then
        stockLine = " Your EEC portfolio adds a further "
            .. tostring(stock) .. " gold."
    end

    return baseLine .. stockLine
end

-- Shown when Factor's Promise applies the extra boost to a
-- specific merchant during dialogue.
local function buildFactorMsg(npc)
    local name = types.NPC.record(npc).name or "The merchant"
    return "Presented with your Factor's seal, " .. name
        .. " nods slowly - they'll go a little into debt for the "
        .. "privilege of your business."
end

-- ============================================================
--  MERCHANT DETECTION
--  Mirrors the check in FPerks_HH.lua. Only applies to NPCs
--  that offer trade services (not pure trainers or enchanters).
-- ============================================================

local TRADE_SERVICES = {
    Barter      = true, Weapon      = true, Armor       = true,
    Clothing    = true, Books       = true, Ingredients = true,
    Picks       = true, Probes      = true, Lights      = true,
    Apparatus   = true, RepairItems = true, Misc        = true,
    Potions     = true, MagicItems  = true,
}

local function isMerchant(actor)
    if not types.NPC.objectIsInstance(actor) then return false end
    local services = types.NPC.record(actor).servicesOffered
    if not services then return false end
    for service, _ in pairs(TRADE_SERVICES) do
        if services[service] then return true end
    end
    return false
end

-- ============================================================
--  GOLD MANIPULATION HELPERS
--  Both route through global.lua since setBarterGold is
--  a global-only API.
-- ============================================================

local function boostMerchant(npc, amount)
    core.sendGlobalEvent("FPerks_EEC_BoostMerchant", { npc = npc, amount = amount })
end

local function restoreMerchant(npc, amount)
    core.sendGlobalEvent("FPerks_EEC_RestoreMerchant", { npc = npc, amount = amount })
end

-- ============================================================
--  FACTOR'S PROMISE EXPIRY
--  Called when onUpdate detects the power has expired.
--  Iterates nearby actors to find and restore factor-boosted
--  merchants. Entries for non-nearby merchants have their
--  factor amount zeroed but gold is not restored (they will
--  restock naturally).
-- ============================================================

local function removeFactorBonuses()
    for _, actor in pairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor) then
            local entry = eecBoostedMerchants[actor.id]
            if entry and entry.totalApplied > entry.baseBonus then
                local factorAmount = entry.totalApplied - entry.baseBonus
                restoreMerchant(actor, factorAmount)
                entry.totalApplied = entry.baseBonus
                print("EEC: Removed factor bonus " .. tostring(factorAmount)
                    .. " from " .. tostring(actor.id))
            end
        end
    end
    -- Zero out any non-nearby entries' factor component by syncing totalApplied
    -- back to baseBonus. Their gold keeps the bonus until natural restock.
    for _, entry in pairs(eecBoostedMerchants) do
        entry.totalApplied = entry.baseBonus
    end
    eecFactorActive = false
end

-- ============================================================
--  PERK REMOVAL CLEANUP
--  Called from P2 onRemove (which gates the whole mechanic).
--  Restores all applied bonuses from currently nearby merchants.
--  Non-nearby merchants retain their gold until natural restock.
-- ============================================================

local function eecClearAllBonuses()
    for _, actor in pairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor) then
            local entry = eecBoostedMerchants[actor.id]
            if entry and entry.totalApplied > 0 then
                restoreMerchant(actor, entry.totalApplied)
                print("EEC: Restored " .. tostring(entry.totalApplied)
                    .. " gold to " .. tostring(actor.id))
            end
        end
    end
    eecBoostedMerchants = {}
    hasEECCoffers       = false
    eecFactorActive     = false
end

-- ============================================================
--  RANK UPGRADE - IMMEDIATE PATH
--  Called from P3 and P4 onAdd. Iterates nearby actors and
--  applies the delta between the old rank bonus and the new
--  rank bonus to every already-boosted merchant in load range.
--  Non-nearby merchants are handled by the deferred path in
--  eecOnUiModeChanged on their next dialogue open.
-- ============================================================

local function upgradeNearbyMerchants(newRank)
    for _, actor in pairs(nearby.actors) do
        if types.NPC.objectIsInstance(actor) then
            local entry = eecBoostedMerchants[actor.id]
            if entry and entry.appliedRank and entry.appliedRank < newRank then
                local newBase  = (calcBaseBonus(entry.baseGold, newRank))
                -- Compute expected total: new base, plus factor multiplier if active.
                local newTotal = eecFactorActive and (newBase * 3) or newBase
                local delta    = newTotal - entry.totalApplied
                if delta > 0 then
                    boostMerchant(actor, delta)
                    entry.baseBonus    = newBase
                    entry.totalApplied = newTotal
                    entry.appliedRank  = newRank
                    print("EEC: Upgraded " .. tostring(actor.id)
                        .. " to baseBonus=" .. tostring(newBase)
                        .. " totalApplied=" .. tostring(newTotal)
                        .. " (delta=+" .. tostring(delta) .. ")")
                end
            end
        end
    end
end

-- ============================================================
--  UI MODE CHANGED - EMPIRE'S COFFERS APPLICATION
--  Fires when any dialogue mode opens. The isMerchant check
--  filters to trade-service NPCs only.
--  The bonus is NOT removed when dialogue closes; it persists.
-- ============================================================

local EEC_TALK_MODES = {
    Barter         = true,
    Dialogue       = true,
    Training       = true,
    SpellBuying    = true,
    MerchantRepair = true,
    Enchanting     = true,
    Companion      = true,
}

local function eecOnUiModeChanged(data)
    if not hasEECCoffers then return end
    if not data.newMode then return end
    if not EEC_TALK_MODES[data.newMode] then return end
    if not data.arg then return end

    local npc = data.arg
    if not isMerchant(npc) then return end

    local rank = getEECRank()
    if not rank or rank < 2 then return end

    local npcId    = npc.id
    local baseGold = types.NPC.record(npc).baseGold

    if baseGold == 0 then return end

    local entry = eecBoostedMerchants[npcId]

    -- ----------------------------------------------------------------
    --  Helper: compute the full expected total for this merchant given
    --  a base bonus and whether Factor's Promise is currently active.
    --  Factor triples total effectiveness, i.e. base * 3.
    -- ----------------------------------------------------------------
    local function expectedTotal(base)
        return eecFactorActive and (base * 3) or base
    end

    if not entry then
        -- ------------------------------------------------------------
        --  FIRST CONTACT
        --  Read gold before applying anything; this is the restock
        --  detection baseline.
        -- ------------------------------------------------------------
        local currentGold = types.Actor.getBarterGold(npc)
        if currentGold == 0 then return end

        local newBase, breakdown = calcBaseBonus(baseGold, rank)
        local newTotal           = expectedTotal(newBase)

        boostMerchant(npc, newTotal)
        eecBoostedMerchants[npcId] = {
            baseBonus       = newBase,
            totalApplied    = newTotal,
            baseGold        = baseGold,
            appliedRank     = rank,
            goldBeforeBonus = currentGold,
        }
        ui.showMessage(buildCoffersMsg(npc, breakdown))
        if eecFactorActive then
            ui.showMessage(buildFactorMsg(npc))
        end
        print("EEC: First contact " .. tostring(npcId)
            .. " baseBonus=" .. tostring(newBase)
            .. " totalApplied=" .. tostring(newTotal)
            .. " (base=" .. tostring(breakdown.baseComponent)
            .. " stock=" .. tostring(breakdown.stockComponent) .. ")")

    else
        local currentGold = types.Actor.getBarterGold(npc)

        if currentGold == entry.goldBeforeBonus then
            -- ------------------------------------------------------------
            --  RESTOCK DETECTED
            --  Merchant gold returned to exactly the pre-bonus snapshot.
            --  Recalculate at current rank and reapply in one call.
            -- ------------------------------------------------------------
            local newBase, breakdown = calcBaseBonus(entry.baseGold, rank)
            local newTotal           = expectedTotal(newBase)

            boostMerchant(npc, newTotal)
            entry.baseBonus    = newBase
            entry.totalApplied = newTotal
            entry.appliedRank  = rank
            ui.showMessage(buildCoffersMsg(npc, breakdown))
            if eecFactorActive then
                ui.showMessage(buildFactorMsg(npc))
            end
            print("EEC: Restock " .. tostring(npcId)
                .. " baseBonus=" .. tostring(newBase)
                .. " totalApplied=" .. tostring(newTotal))

        else
            -- ------------------------------------------------------------
            --  EXISTING ENTRY - compute expected total and apply delta.
            --  This covers three cases in one unified path:
            --    1. Factor's Promise just activated (eecFactorActive flipped
            --       true since last dialogue with this merchant)
            --    2. Deferred rank upgrade (appliedRank < current rank)
            --    3. Factor's Promise expired (eecFactorActive is false but
            --       totalApplied > baseBonus - handled by removeFactorBonuses,
            --       but the delta path catches any edge cases cleanly)
            -- ------------------------------------------------------------
            local newBase  = (entry.appliedRank < rank)
                and (calcBaseBonus(entry.baseGold, rank))
                or  entry.baseBonus
            local newTotal = expectedTotal(newBase)
            local delta    = newTotal - entry.totalApplied

            if delta > 0 then
                boostMerchant(npc, delta)
                local showFactor = eecFactorActive
                    and entry.totalApplied == entry.baseBonus
                entry.baseBonus    = newBase
                entry.totalApplied = newTotal
                entry.appliedRank  = rank

                if entry.appliedRank < rank then
                    -- Rank upgrade component - show coffers message.
                    local _, breakdown = calcBaseBonus(entry.baseGold, rank)
                    ui.showMessage(buildCoffersMsg(npc, breakdown))
                end
                if showFactor then
                    ui.showMessage(buildFactorMsg(npc))
                end
                print("EEC: Delta applied to " .. tostring(npcId)
                    .. " delta=+" .. tostring(delta)
                    .. " baseBonus=" .. tostring(newBase)
                    .. " totalApplied=" .. tostring(newTotal))

            elseif delta < 0 then
                -- Shouldn't normally happen outside of removeFactorBonuses,
                -- but guard against it to avoid negative gold.
                restoreMerchant(npc, math.abs(delta))
                entry.baseBonus    = newBase
                entry.totalApplied = newTotal
                entry.appliedRank  = rank
                print("EEC: Negative delta corrected for " .. tostring(npcId)
                    .. " delta=" .. tostring(delta))
            end
        end
    end
end

-- ============================================================
--  onUpdate - FACTOR'S PROMISE EXPIRY DETECTION
--  Polls activeSpells every 0.5s to detect the transition from
--  active - inactive for FPerks_EEC4_FactorPromise.
--  When expiry is detected, removeFactorBonuses() is called.
-- ============================================================

local function onUpdate(dt)
    if not hasEECCoffers then return end

    eecFactorPollTimer = eecFactorPollTimer - dt
    if eecFactorPollTimer > 0 then return end
    eecFactorPollTimer = EEC_FACTOR_POLL_INTERVAL

    local powerActive = types.Actor.activeSpells(self):isSpellActive('fperks_eec4_factorpromise')

    if eecFactorActive and not powerActive then
        -- The power has expired; remove factor bonuses from nearby merchants.
        print("EEC: Factor's Promise expired, restoring factor bonuses.")
        removeFactorBonuses()
    elseif not eecFactorActive and powerActive then
        -- The power has just been cast (or was active at load - cleared on load,
        -- so this branch is only hit on a fresh cast).
        eecFactorActive = true
        print("EEC: Factor's Promise activated.")
    end
end

-- ============================================================
--  EAST EMPIRE COMPANY PERKS
--  Primary attributes: Personality, Willpower
--  Scaling: Mercantile, Speechcraft
--  Special: Empire's Coffers (P2+), Factor's Promise power (P4)
--
--  The EEC has 9 ranks (0-indexed 0-8) rather than the usual 10.
--  Perk rank requirements are spread accordingly:
--      P1: rank 0   P2: rank 2   P3: rank 5   P4: rank 8
-- ============================================================

interfaces.ErnPerkFramework.registerPerk({
    id = eec1_id,
    localizedName = "Company Charter",
    localizedDescription = "You have been granted a trading licence by the East Empire Company. "
        .. "The Company's name and reputation open doors that gold alone cannot.\
 "
        .. "(+3 Personality, +3 Willpower, +5 Mercantile, +5 Speechcraft)",
    hidden = perkHidden(GUILD, 0, 1),
    art = "textures\\levelup\\healer", cost = 1,
    requirements = {
        R().minimumFactionRank('east empire company', 0),
        R().minimumLevel(1),
    },
    onAdd    = function() setRank(1) end,
    onRemove = function() setRank(nil) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = eec2_id,
    localizedName = "Empire's Coffers",
    localizedDescription = "The weight of the Company's treasury stands behind your every trade. "
        .. "Merchants who deal with you find their available gold bolstered by the "
        .. "Company's credit - a permanent arrangement for as long as you hold its favour.\
 "
        .. "Requires Company Charter. "
        .. "(+5 Personality, +5 Willpower, +10 Mercantile, +10 Speechcraft)\
\
"
        .. "Empire's Coffers: The first time you speak with a merchant, they receive "
        .. "a permanent boost to their available barter gold: "
        .. "+50 or +10% of their base gold, whichever is greater."
        .. (hasTamrielData and
            "\
 Stock Exchange: An additional bonus of 0.1% of your EEC portfolio value is added, "
            .. "capped at 20% of the merchant's base gold."
            or ""),
    hidden = perkHidden(GUILD, 2, 5),
    art = "textures\\levelup\\healer", cost = 2,
    requirements = {
        R().hasPerk(eec1_id),
        R().minimumFactionRank('east empire company', 2),
        R().minimumAttributeLevel('personality', 40),
        R().minimumLevel(5),
    },
    onAdd = function()
        setRank(2)
        hasEECCoffers = true
    end,
    onRemove = function()
        setRank(nil)
        -- P2 gates the entire Coffers mechanic. Clearing here handles all
        -- cleanup even if P3/P4 are also being removed by a respec.
        eecClearAllBonuses()
    end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = eec3_id,
    localizedName = "Established Routes",
    localizedDescription = "The Company's trade network spans sea and shore. "
        .. "Merchants across Vvardenfell recognise you as a person of consequence.\
 "
        .. "Requires Empire's Coffers. "
        .. "(+10 Personality, +10 Willpower, +18 Mercantile, +18 Speechcraft)\
\
"
        .. "Empire's Coffers increases to +150 or +25% of base gold."
        .. (hasTamrielData and
            "\
 Stock Exchange cap increases to 50% of base gold."
            or ""),
    hidden = perkHidden(GUILD, 5, 10),
    art = "textures\\levelup\\healer", cost = 3,
    requirements = {
        R().hasPerk(eec2_id),
        R().minimumFactionRank('east empire company', 5),
        R().minimumAttributeLevel('personality', 50),
        R().minimumLevel(10),
    },
    onAdd    = function() setRank(3); upgradeNearbyMerchants(3) end,
    onRemove = function() setRank(nil) end,
})

interfaces.ErnPerkFramework.registerPerk({
    id = eec4_id,
    localizedName = "Senior Factor",
    localizedDescription = "You hold the Company's highest confidence. "
        .. "Once each day, you may invoke the full weight of the Company's promise, "
        .. "sharpening your mercantile instincts and flooding merchants' coffers "
        .. "far beyond their normal limits.\
 "
        .. "Requires Established Routes. "
        .. "(+15 Personality, +15 Willpower, +25 Mercantile, +25 Speechcraft)\
\
"
        .. "Empire's Coffers increases to +250 or +50% of base gold.\
\
"
        .. "Factor's Promise (1/day): Fortify Mercantile +100 for 30s. "
        .. "Empire's Coffers is tripled in effectiveness for the duration."
        .. (hasTamrielData and
            "\
 Stock Exchange cap increases to 100% of base gold."
            or ""),
    hidden = perkHidden(GUILD, 8, 15),
    art = "textures\\levelup\\healer", cost = 4,
    requirements = {
        R().hasPerk(eec3_id),
        R().minimumFactionRank('east empire company', 8),
        R().minimumAttributeLevel('personality', 75),
        R().minimumLevel(15),
    },
    onAdd = function()
        setRank(4)
        upgradeNearbyMerchants(4)
        safeAddSpell("FPerks_EEC4_FactorPromise")
    end,
    onRemove = function()
        setRank(nil)
        safeRemoveSpell("FPerks_EEC4_FactorPromise")
    end,
})

-- ============================================================
--  SAVE / LOAD
-- ============================================================

local function onSave()
    local savedMerchants = {}
    for npcId, data in pairs(eecBoostedMerchants) do
        savedMerchants[npcId] = {
            baseBonus       = data.baseBonus,
            totalApplied    = data.totalApplied,
            baseGold        = data.baseGold,
            appliedRank     = data.appliedRank,
            goldBeforeBonus = data.goldBeforeBonus,
        }
    end
    return {
        eecBoostedMerchants = savedMerchants,
    }
end

local function onLoad(data)
    -- The game engine resets all NPC barter gold to their base values on every
    -- load, regardless of what setBarterGold set during the previous session.
    -- Any entries we saved are therefore stale - the merchants no longer have
    -- their bonuses in-game even though the table thinks they do.
    -- Wiping the table here ensures every merchant gets correctly re-boosted
    -- on their next dialogue open, including saves that were made mid-session
    -- after some merchants had already been boosted.
    eecBoostedMerchants = {}
    -- Factor's Promise lasts 30s and cannot survive a load.
    eecFactorActive = false
end

-- ============================================================
--  CONSOLE COMMANDS
--
--  All commands require the target NPC to be selected in the
--  console (click on the NPC before typing the command).
--
--  lua eec debug          - print overall state summary
--  lua eec dump           - list every tracked merchant with
--                           their base, factor, baseGold, and
--                           appliedRank values
--  lua eec reset          - set the selected NPC's barter gold
--                           back to their record baseGold and
--                           remove them from the tracking table
--                           so Empire's Coffers will reapply
--                           on next dialogue
--  lua eec set <amount>   - set the selected NPC's barter gold
--                           to an exact value and clear their
--                           tracking entry (useful when gold
--                           has drifted from a known good state)
--  lua eec clear          - restore all nearby tracked merchants
--                           to their baseGold and wipe the
--                           tracking table entirely (nuclear
--                           option; same as losing the perk)
-- ============================================================

local function onConsoleCommand(mode, command, selectedObject)
    local lower = command:lower()

    -- --------------------------------------------------------
    --  lua eec debug
    -- --------------------------------------------------------
    if lower:find("^lua eec debug") then
        local count = 0
        for _ in pairs(eecBoostedMerchants) do count = count + 1 end
        print("EEC: hasEECCoffers  = " .. tostring(hasEECCoffers))
        print("EEC: eecFactorActive = " .. tostring(eecFactorActive))
        print("EEC: tracked merchants: " .. tostring(count))
        local rank = getEECRank()
        print("EEC: current perk rank: " .. tostring(rank))

    -- --------------------------------------------------------
    --  lua eec dump
    -- --------------------------------------------------------
    elseif lower:find("^lua eec dump") then
        local count = 0
        for _ in pairs(eecBoostedMerchants) do count = count + 1 end
        if count == 0 then
            print("EEC: No merchants tracked.")
            return
        end
        print("EEC: Tracked merchants (" .. tostring(count) .. "):")
        local i = 0
        for npcId, entry in pairs(eecBoostedMerchants) do
            i = i + 1
            print("  [" .. i .. "]"
                .. "  id="           .. tostring(npcId)
                .. "  baseBonus="    .. tostring(entry.baseBonus)
                .. "  totalApplied=" .. tostring(entry.totalApplied)
                .. "  baseGold="     .. tostring(entry.baseGold)
                .. "  appliedRank="  .. tostring(entry.appliedRank))
        end

    -- --------------------------------------------------------
    --  lua eec reset
    --  Restores the selected NPC to their record baseGold and
    --  removes them from tracking. Falls back to reading the
    --  record's baseGold directly if no tracking entry exists,
    --  so the command is useful even for untracked merchants.
    -- --------------------------------------------------------
    elseif lower:find("^lua eec reset") then
        if not selectedObject or not selectedObject:isValid() then
            print("EEC reset: no valid object selected. Click an NPC first.")
            return
        end
        if not types.NPC.objectIsInstance(selectedObject) then
            print("EEC reset: selected object is not an NPC.")
            return
        end
        local npcId = selectedObject.id
        local entry = eecBoostedMerchants[npcId]
        -- Use the stored baseGold if available; fall back to the record value.
        local targetGold = entry and entry.baseGold
                           or types.NPC.record(selectedObject).baseGold
        core.sendGlobalEvent("FPerks_EEC_SetMerchantGold", {
            npc    = selectedObject,
            amount = targetGold,
        })
        if entry then
            eecBoostedMerchants[npcId] = nil
            print("EEC reset: " .. tostring(npcId)
                .. " gold set to baseGold " .. tostring(targetGold)
                .. ". Tracking entry cleared; Empire's Coffers will"
                .. " reapply on next dialogue.")
        else
            print("EEC reset: " .. tostring(npcId)
                .. " was not tracked. Gold set to record baseGold "
                .. tostring(targetGold) .. ".")
        end

    -- --------------------------------------------------------
    --  lua eec set <amount>
    --  Sets the selected NPC's barter gold to an exact value.
    --  Clears their tracking entry so Empire's Coffers will
    --  reapply from scratch on next dialogue.
    -- --------------------------------------------------------
    elseif lower:find("^lua eec set") then
        if not selectedObject or not selectedObject:isValid() then
            print("EEC set: no valid object selected. Click an NPC first.")
            return
        end
        if not types.NPC.objectIsInstance(selectedObject) then
            print("EEC set: selected object is not an NPC.")
            return
        end
        -- Extract the trailing number from the original (pre-lowered) command.
        local amountStr = command:match("%s+(%d+)%s*$")
        if not amountStr then
            print("EEC set: usage: lua eec set <amount>")
            return
        end
        local amount = tonumber(amountStr)
        if not amount or amount < 0 then
            print("EEC set: amount must be a non-negative integer.")
            return
        end
        local npcId = selectedObject.id
        core.sendGlobalEvent("FPerks_EEC_SetMerchantGold", {
            npc    = selectedObject,
            amount = amount,
        })
        if eecBoostedMerchants[npcId] then
            eecBoostedMerchants[npcId] = nil
            print("EEC set: " .. tostring(npcId) .. " gold set to "
                .. tostring(amount)
                .. ". Tracking entry cleared; Empire's Coffers will"
                .. " reapply on next dialogue.")
        else
            print("EEC set: " .. tostring(npcId) .. " gold set to "
                .. tostring(amount) .. ". (No tracking entry existed.)")
        end

    -- --------------------------------------------------------
    --  lua eec clear
    --  Calls eecClearAllBonuses - identical to losing the perk.
    --  Restores nearby tracked merchants to baseGold and wipes
    --  the entire tracking table.
    -- --------------------------------------------------------
    elseif lower:find("^lua eec clear") then
        print("EEC clear: restoring all nearby tracked merchants and wiping table...")
        eecClearAllBonuses()
        print("EEC clear: done.")
    end
end

-- ============================================================
--  ENGINE CALLBACKS
-- ============================================================

return {
    eventHandlers = {
        UiModeChanged = eecOnUiModeChanged,
    },
    engineHandlers = {
        onUpdate         = onUpdate,
        onSave           = onSave,
        onLoad           = onLoad,
        onConsoleCommand = onConsoleCommand,
    },
}
