local core    = require('openmw.core')
local storage = require('openmw.storage')
local self    = require('openmw.self')
local T       = require('openmw.types')
local ui      = require('openmw.ui')
local I       = require('openmw.interfaces')
local nearby  = require('openmw.nearby')

local mSummaryUi = require('scripts.SC.ui.summary')
mSummaryUi.registerTrigger()

local mS      = require('scripts.SC.config.settings')
mS.initPlayerSettings()

local mDef    = require('scripts.SC.config.definition')
local mStatsUi = require('scripts.SC.ui.stats')
local ARTIFACT_IDS = require('scripts.SC.data.artifacts')
local WORSHIPPER_IDS = require('scripts.SC.data.worshippers')

-- Runtime state bucket. OpenMW's Lua runtime inherits Lua's 200-local limit
-- per function/chunk; keeping long-lived mutable state in one table prevents
-- this large player script from exceeding the main chunk's local register cap.
local V = {}

-- Gods: divine/god-like beings whose death has world-altering consequences
local GOD_IDS = {
    ["vivec_god"] = true,
    ["dagoth_ur_1"] = true,
    ["almalexia"] = true,
    ["almalexia_warrior"] = true,
}

-- Regicides: kings, queens, dukes, duchesses, and other ruling figures
local REGICIDE_IDS = {
    ["barenziah"] = true,
    ["goris the maggot king"] = true,
    ["vedam dren"] = true,
    ["king hlaalu helseth"] = true,
    ["tr_m3_ji'morashu-ri"] = true,
    ["tr_m1_duchess_jandacia"] = true,
    ["tr_m3_phyrios mattimus"] = true,
    ["pc_m1_enmanseptim"] = true,
    ["pc_m1_enmaneumaeus"] = true,
    ["pc_m1_millonaconomorus"] = true,
    ["sky_qre_dsw_alaktol"] = true,
    ["sky_qre_kw_alrod"] = true,
}

local L = core.l10n(mDef.MOD_NAME)

local state = {
    savedGameVersion = mDef.savedGameVersion,
    profileId        = nil,
}

local profileSection = nil

-- ============================================================
-- PROFILE STORAGE
-- ============================================================

local function initProfileId()
    -- Generate a unique playthrough ID on first init (new game).
    -- This is saved with the character via onSave/onLoad so each
    -- playthrough gets its own storage section.
    if not state.playthroughId then
        state.playthroughId = string.format("%x%x", os.time(), math.floor(math.random() * 0xFFFF))
    end

    -- NOTE: Do NOT include playerName in the key. During chargen the name
    -- is "player", but after chargen it changes to the real name, which
    -- would create a different (empty) storage section on first load.
    local profileId  = string.format("%s_%s", mDef.MOD_NAME, state.playthroughId)
    local section    = storage.playerSection(profileId)

    local defaults = {
        deathCount    = 0,
        trainCount    = 0,
        jailCount     = 0,
        highestBounty = 0,
        mostGold      = 0,
        alchemyCount  = 0,
        potionCount   = 0,
        bookCount     = 0,
        questCount    = 0,
        scribCount    = 0,
        travelCount       = 0,
        recallCount       = 0,   -- times recalled (vanilla + LMM)
        interventionCount = 0,
        hitCount      = 0,   -- melee/fist hits that connected
        swingCount    = 0,   -- all melee/fist swings (hits + misses)
        sleepHours    = 0,   -- accumulated game hours asleep/waiting
        slavesFreed   = 0,
        lockpicksBroken = 0,
        probesBroken  = 0,
        repairCount   = 0,
        unlockCount   = 0,
        disarmCount   = 0,
        trapCount   = 0,
        damageTaken       = 0,   -- total HP lost from all sources (combat, magic, falls, etc.)
        combatDamageTaken = 0,   -- HP lost specifically from combat hits
        killCount         = 0,   -- total actors killed (NPCs + creatures)
        npcKillCount      = 0,   -- NPCs killed
        creatureKillCount = 0,   -- creatures killed (type 0: beasts, animals)
        undeadKillCount   = 0,   -- undead killed (type 3)
        daedraKillCount   = 0,   -- daedra killed (type 1)
        humanoidKillCount = 0,   -- humanoid creatures killed (type 2, NOT NPCs)
        headshotCount     = 0,   -- ranged headshots (Bullseye mod)
        witchesHunted     = 0,   -- NPCs of class "Witch" killed
        necromancersSlain = 0,   -- NPCs of class "Necromancer" killed
        warlocksSlain     = 0,   -- NPCs of class "Warlock" killed
        worshippersSlain  = 0,   -- Daedra worshipper NPCs killed (by record ID)
        bruteForceCount   = 0,   -- locks smashed open (Brute Force mod)
        sdMealCount       = 0,   -- meals eaten (Sun's Dusk mod)
        sdDrinkCount      = 0,   -- beverages consumed (Sun's Dusk mod)
        sdBathCount       = 0,   -- baths taken (Sun's Dusk mod)
        stolenItemCount   = 0,   -- items stolen (ErnBurglary mod)
        stolenItemValue   = 0,   -- total value of stolen items (ErnBurglary mod)
        spellsMade        = 0,   -- spells created at spellmakers
        itemsEnchanted    = 0,   -- items enchanted at enchanters or self-enchanting
        plantsForaged     = 0,   -- plant containers harvested for ingredients
        ingredientsEaten  = 0,   -- raw ingredients consumed (eaten directly)
        artifactsFound    = 0,   -- unique artifacts ever held by the player
        diseaseCaught     = 0,   -- unique common diseases contracted
        blightCaught      = 0,   -- unique blight diseases contracted
        sdCookCount       = 0,   -- meals cooked (Sun's Dusk mod)
        bountiesPaid      = 0,   -- times bounty paid off to a guard
        knockdownCount    = 0,   -- times knocked down in combat
        blackSoulsTrapped = 0,   -- NPC souls trapped (Black Soul Gems mod)
        sneakAttackCount  = 0,   -- sneak attacks landed while sneaking
        switCount         = 0,   -- times called s'wit by NPCs (requires OpenMW 0.51+)
        fetcherCount      = 0,   -- times called fetcher by NPCs (requires OpenMW 0.51+)
        nwahCount         = 0,   -- times called n'wah by NPCs (requires OpenMW 0.51+)
        scumCount         = 0,   -- times called scum by NPCs (requires OpenMW 0.51+)
        totalGoldFound    = 0,   -- cumulative gold gained from all sources
        spellEffectsLearned = 0, -- unique spell effect IDs the player has learned
        quickloadCount    = 0, -- times the player has quickloaded/save-scummed
        worldsDoomed      = 0, -- essential NPCs killed (thread of prophecy severed)
        skoomaCount      = 0, -- times skooma was consumed
        godsKilled        = 0, -- god-like beings killed (Vivec, Dagoth Ur, Almalexia)
        regicides         = 0, -- kings/queens/rulers killed
        peopleMet         = 0, -- unique NPCs the player has spoken to
        peopleMetStr      = "",-- serialized set of NPC record IDs met
        murderCount       = 0, -- murders committed (bounty +1000)
        assaultCount      = 0, -- assaults committed (bounty +40)
        distOnFoot        = 0, -- distance travelled on foot (game units)
        distLevitated     = 0, -- distance travelled while levitating (game units)
        distJumped        = 0, -- distance travelled while airborne from jumping (game units)
        distSwum          = 0, -- distance travelled while swimming (game units)
        distMounted       = 0, -- distance travelled while riding a mount (game units)
        highestPoint      = 0, -- highest Z coordinate reached (game units)
        deepestDive       = 0, -- lowest Z coordinate reached while swimming (game units)
        longestFallSurvived = 0, -- longest fall distance survived (game units)
        fastestSpeed      = 0, -- peak movement speed (game units per second)
        furthestFromStart = 0, -- max distance from Seyda Neen (game units)
        playSeconds       = 0, -- real/simulation time tracked by the mod for this character
        mainQuestSummaryShown = false, -- one-shot celebratory summary popup after MQ completion
    }
    for key, default in pairs(defaults) do
        if not section:get(key) then section:set(key, default) end
    end
    if not section:get("booksSeenStr") then section:set("booksSeenStr", "") end
    if not section:get("creatureKillsStr") then section:set("creatureKillsStr", "") end
    if not section:get("creatureTypesStr") then section:set("creatureTypesStr", "") end
    if not section:get("artifactsSeenStr") then section:set("artifactsSeenStr", "") end
    if not section:get("diseasesSeenStr") then section:set("diseasesSeenStr", "") end
    if not section:get("weaponTallyStr") then section:set("weaponTallyStr", "") end
    if not section:get("spellTallyStr") then section:set("spellTallyStr", "") end
    if not section:get("spellEffectsSeenStr") then section:set("spellEffectsSeenStr", "") end
    state.profileId = profileId
    profileSection = section
end

local function get(key)
    if not profileSection then return 0 end
    return profileSection:get(key) or 0
end
local function set(key, value)
    if profileSection then profileSection:set(key, value) end
end
local function increment(key)
    set(key, get(key) + 1)
end
local function storeIfHigher(key, value)
    if value > get(key) then set(key, value) end
end
local function addTo(key, amount)
    set(key, get(key) + amount)
end

V.playSecondsBuffer = 0
local PLAY_SECONDS_FLUSH_INTERVAL = 5.0

local function flushPlaySeconds()
    if state.profileId and V.playSecondsBuffer > 0 then
        addTo("playSeconds", V.playSecondsBuffer)
        V.playSecondsBuffer = 0
    end
end

-- Personal records are sampled every frame, but persistent storage writes are
-- buffered. This avoids write-heavy frames while preserving save compatibility.
V.personalRecordBuffer = {}
V.personalRecordDirty = false
local PERSONAL_RECORD_FLUSH_INTERVAL = 5.0

local function getPersonalRecordValue(key)
    local buffered = V.personalRecordBuffer[key]
    if buffered ~= nil then return buffered end
    return get(key)
end

local function setPersonalRecordValue(key, value)
    V.personalRecordBuffer[key] = value
    V.personalRecordDirty = true
end

local function storePersonalRecordIfHigher(key, value)
    if value > getPersonalRecordValue(key) then
        setPersonalRecordValue(key, value)
    end
end

local function flushPersonalRecords()
    if not state.profileId or not profileSection or not V.personalRecordDirty then return end
    for key, value in pairs(V.personalRecordBuffer) do
        set(key, value)
    end
    V.personalRecordBuffer = {}
    V.personalRecordDirty = false
end

local function resetPersonalRecordBuffer()
    V.personalRecordBuffer = {}
    V.personalRecordDirty = false
end

-- ============================================================
-- BOOKS SEEN SET
-- ============================================================

V.booksSeenCache = nil

local function loadBooksSeenCache()
    local raw = profileSection:get("booksSeenStr") or ""
    V.booksSeenCache = {}
    for id in raw:gmatch("[^\n]+") do V.booksSeenCache[id] = true end
end

local function markBookSeen(recordId)
    if V.booksSeenCache == nil then loadBooksSeenCache() end
    if V.booksSeenCache[recordId] then return false end
    V.booksSeenCache[recordId] = true
    local parts = {}
    for id in pairs(V.booksSeenCache) do parts[#parts + 1] = id end
    profileSection:set("booksSeenStr", table.concat(parts, "\n"))
    return true
end

-- ============================================================
-- ARTIFACT TRACKING
-- Scans inventory every poll for known artifact IDs.
-- Uses a persistent "seen" set so each artifact is only
-- counted once, even if dropped and re-acquired.
-- ============================================================

V.artifactsSeenCache = nil

local function loadArtifactsSeenCache()
    local raw = profileSection:get("artifactsSeenStr") or ""
    V.artifactsSeenCache = {}
    for id in raw:gmatch("[^\n]+") do V.artifactsSeenCache[id] = true end
end

local function markArtifactSeen(recordId)
    if V.artifactsSeenCache == nil then loadArtifactsSeenCache() end
    if V.artifactsSeenCache[recordId] then return false end
    V.artifactsSeenCache[recordId] = true
    local parts = {}
    for id in pairs(V.artifactsSeenCache) do parts[#parts + 1] = id end
    profileSection:set("artifactsSeenStr", table.concat(parts, "\n"))
    return true
end

local function pollArtifacts()
    -- Scan all item types that can be artifacts
    local typeList = {T.Weapon, T.Armor, T.Clothing, T.Miscellaneous}
    for _, itemType in ipairs(typeList) do
        local ok, items = pcall(function() return T.Actor.inventory(self):getAll(itemType) end)
        if ok and items then
            for _, item in pairs(items) do
                local rok, recordId = pcall(function()
                    return string.lower(itemType.record(item).id)
                end)
                if rok and recordId and ARTIFACT_IDS[recordId] then
                    if markArtifactSeen(recordId) then
                        increment("artifactsFound")
                    end
                end
            end
        end
    end
end

-- ============================================================
-- DISEASE TRACKING
-- Scans the player's spell list for Disease (type 3) and
-- Blight (type 2) spells. Each unique disease is counted once.
-- Automatically supports vanilla MW, TR, and any mod diseases
-- since it reads spell type from the record, not a hardcoded list.
-- ============================================================

V.diseasesSeenCache = nil

local function loadDiseasesSeenCache()
    local raw = profileSection:get("diseasesSeenStr") or ""
    V.diseasesSeenCache = {}
    for id in raw:gmatch("[^\n]+") do V.diseasesSeenCache[id] = true end
end

local function markDiseaseSeen(spellId)
    if V.diseasesSeenCache == nil then loadDiseasesSeenCache() end
    if V.diseasesSeenCache[spellId] then return false end
    V.diseasesSeenCache[spellId] = true
    local parts = {}
    for id in pairs(V.diseasesSeenCache) do parts[#parts + 1] = id end
    profileSection:set("diseasesSeenStr", table.concat(parts, "\n"))
    return true
end

-- ESM Spell types: 0=Spell, 1=Ability, 2=Blight, 3=Disease, 4=Curse, 5=Power
local function pollDiseases()
    for _, spell in pairs(T.Actor.spells(self)) do
        local ok, stype = pcall(function()
            return core.magic.spells.records[spell.id].type
        end)
        if ok and stype then
            if stype == 3 then -- Disease
                if markDiseaseSeen(spell.id) then
                    increment("diseaseCaught")
                end
            elseif stype == 2 then -- Blight
                if markDiseaseSeen(spell.id) then
                    increment("blightCaught")
                end
            end
        end
    end
end

-- ============================================================
-- TOTAL GOLD FOUND
-- Polls gold count every 2s. Any increase is accumulated into
-- totalGoldFound. Tracks ALL gold gains: loot, barter sales,
-- quest rewards, pickpocketing, etc. Differs from Most Gold
-- Held which only records the peak amount carried at once.
-- ============================================================

V.lastGoldCount = nil

local function pollGoldFound()
    local current = T.Actor.inventory(self):countOf("gold_001")
    if V.lastGoldCount == nil then
        V.lastGoldCount = current
        return
    end
    local delta = current - V.lastGoldCount
    if delta > 0 then
        addTo("totalGoldFound", delta)
    end
    V.lastGoldCount = current
end

-- ============================================================
-- SPELL EFFECTS LEARNED
-- Scans all the player's known spells (type 0 = Spell and
-- type 5 = Power) and collects every unique magic effect ID.
-- Each new effect ID is counted once across the playthrough.
-- ============================================================

local spellEffectsSeenCache = nil

local function loadSpellEffectsSeenCache()
    local raw = profileSection:get("spellEffectsSeenStr") or ""
    spellEffectsSeenCache = {}
    for id in raw:gmatch("[^\n]+") do spellEffectsSeenCache[id] = true end
end

local function markSpellEffectSeen(effectId)
    if spellEffectsSeenCache == nil then loadSpellEffectsSeenCache() end
    if spellEffectsSeenCache[effectId] then return false end
    spellEffectsSeenCache[effectId] = true
    local parts = {}
    for id in pairs(spellEffectsSeenCache) do parts[#parts + 1] = id end
    profileSection:set("spellEffectsSeenStr", table.concat(parts, "\n"))
    return true
end

local function pollSpellEffects()
    for _, spell in pairs(T.Actor.spells(self)) do
        local ok, rec = pcall(function()
            return core.magic.spells.records[spell.id]
        end)
        if ok and rec then
            -- Only count Spell (0) and Power (5) types — not abilities,
            -- diseases, curses, or blight which are gained passively
            local stype = rec.type
            if stype == 0 or stype == 5 then
                for _, eff in ipairs(rec.effects) do
                    if eff.id and markSpellEffectSeen(eff.id) then
                        increment("spellEffectsLearned")
                    end
                end
            end
        end
    end
end

-- ============================================================
-- FAVOURITE WEAPON
-- Tracks which weapon the player is holding when combat hits
-- land. The actor script sends CombatSwing with hit=true for
-- successful melee/fist strikes. We read the currently equipped
-- weapon and tally by weapon name. Fist/Hand-to-Hand is tracked
-- as "Hand-to-Hand". Tooltip displays top 5.
-- Format: "name1\tcount1\nname2\tcount2\n..."
-- ============================================================

V.weaponTallyCache = {}

local function loadWeaponTallyCache()
    if not state.profileId then return end
    V.weaponTallyCache = {}
    local raw = profileSection:get("weaponTallyStr") or ""
    for line in raw:gmatch("[^\n]+") do
        local name, count = line:match("^(.+)\t(%d+)$")
        if name and count then
            V.weaponTallyCache[name] = tonumber(count)
        end
    end
end

local function saveWeaponTallyCache()
    local parts = {}
    for name, count in pairs(V.weaponTallyCache) do
        parts[#parts + 1] = name .. "\t" .. tostring(count)
    end
    profileSection:set("weaponTallyStr", table.concat(parts, "\n"))
end

local function recordWeaponKill()
    -- Check what the player has equipped in the right hand
    local weapon = T.Actor.getEquipment(self, T.Actor.EQUIPMENT_SLOT.CarriedRight)
    local weaponName = "Hand-to-Hand"
    if weapon then
        local ok, rec = pcall(function() return T.Weapon.record(weapon) end)
        if ok and rec and rec.name then
            weaponName = rec.name
        end
    end
    V.weaponTallyCache[weaponName] = (V.weaponTallyCache[weaponName] or 0) + 1
    saveWeaponTallyCache()
end

local function getTopWeapons(limit)
    local sorted = {}
    for name, count in pairs(V.weaponTallyCache) do
        sorted[#sorted + 1] = { name = name, count = count }
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    local result = {}
    for i = 1, math.min(limit or 5, #sorted) do
        result[#result + 1] = sorted[i]
    end
    return result
end

-- ============================================================
-- FAVOURITE SPELL
-- Tracks which spell the player casts during gameplay.
-- Detection methods:
-- 1. activeSpells polling: when a new activeSpellId appears
--    that wasn't seen before, record the spell/power name.
-- 2. onConsume hook: when a scroll is consumed, record the
--    enchantment name (scrolls vanish too fast for polling).
-- Covers: Spells (type 0), Powers (type 5), and Scrolls.
-- Excludes: abilities, diseases, blight, curses, constant-
-- effect enchantments, and cast-on-strike enchantments.
-- The seenActiveSpellIds set is pre-populated on load so that
-- effects already active when a save is loaded are not
-- re-counted.
-- Tooltip displays top 5.
-- Format: "name1\tcount1\nname2\tcount2\n..."
-- ============================================================

V.spellTallyCache = {}
V.seenActiveSpellIds = {}  -- activeSpellId -> true, to avoid double-counting
V.spellPollInitialised = false  -- true once we've seeded the seen set

local function loadSpellTallyCache()
    if not state.profileId then return end
    V.spellTallyCache = {}
    local raw = profileSection:get("spellTallyStr") or ""
    for line in raw:gmatch("[^\n]+") do
        local name, count = line:match("^(.+)\t(%d+)$")
        if name and count then
            V.spellTallyCache[name] = tonumber(count)
        end
    end
end

-- People Met: track unique NPCs the player has opened dialogue with.
-- Uses a string-serialized set of NPC record IDs (same as books/diseases).
V.peopleMetCache = {}

local function loadPeopleMetCache()
    if not state.profileId then return end
    V.peopleMetCache = {}
    local raw = profileSection:get("peopleMetStr")
    if type(raw) ~= "string" then return end
    for id in raw:gmatch("[^\n]+") do
        if id ~= "" then V.peopleMetCache[id] = true end
    end
end

local function saveSpellTallyCache()
    local parts = {}
    for name, count in pairs(V.spellTallyCache) do
        parts[#parts + 1] = name .. "\t" .. tostring(count)
    end
    profileSection:set("spellTallyStr", table.concat(parts, "\n"))
end

local function recordSpellCast(spellName)
    V.spellTallyCache[spellName] = (V.spellTallyCache[spellName] or 0) + 1
    saveSpellTallyCache()
end

local function pollSpellsCast(activeSpells)
    -- On first poll after load, seed the seen set with all currently
    -- active spell IDs so we don't re-count them as new casts.
    if not V.spellPollInitialised then
        V.spellPollInitialised = true
        for _, activeSpell in pairs(activeSpells or T.Actor.activeSpells(self)) do
            V.seenActiveSpellIds[activeSpell.activeSpellId] = true
        end
        return
    end

    for _, activeSpell in pairs(activeSpells or T.Actor.activeSpells(self)) do
        local spellId = activeSpell.activeSpellId
        if not V.seenActiveSpellIds[spellId] then
            V.seenActiveSpellIds[spellId] = true

            -- Skip ALL equipment-sourced effects. Enchanted items
            -- (constant-effect armour, cast-on-use items, scrolls) are
            -- tracked separately by pollEnchantedItemUse(), which
            -- detects charge drops for cast-on-use and item consumption
            -- for scrolls. Counting them here would double-count.
            if activeSpell.fromEquipment then
                -- handled by pollEnchantedItemUse
            else
                -- Only count spells the player actually cast. This excludes
                -- traps and hostile spells that get applied onto the player.
                if activeSpell.caster ~= self then
                    goto continue_active_spell
                end

                -- Exclude passive spell types: Ability(1), Blight(2),
                -- Disease(3), Curse(4). Only count Spell(0), Power(5),
                -- and enchantment-sourced effects (scrolls, cast-on-use items).
                local dominated = false
                local ok, rec = pcall(function()
                    return core.magic.spells.records[activeSpell.id]
                end)
                if ok and rec and rec.type ~= nil then
                    if rec.type ~= 0 and rec.type ~= 5 then
                        dominated = true
                    end
                end

                -- Exclude consumed potions and ingredients (Sun's Dusk
                -- meals, drinks, and raw ingredients all appear as
                -- activeSpells when consumed). pcall returns true even
                -- when the lookup returns nil, so check the actual value.
                if not dominated then
                    local potOk, potRec = pcall(function()
                        return T.Potion.records[activeSpell.id]
                    end)
                    if potOk and potRec then dominated = true end
                end
                if not dominated then
                    local ingOk, ingRec = pcall(function()
                        return T.Ingredient.records[activeSpell.id]
                    end)
                    if ingOk and ingRec then dominated = true end
                end

                if not dominated then
                    local displayName = activeSpell.name
                    if displayName and displayName ~= "" then
                        recordSpellCast(displayName)
                    end
                end
            end
            ::continue_active_spell::
        end
    end
end

local function getTopSpells(limit)
    local sorted = {}
    for name, count in pairs(V.spellTallyCache) do
        sorted[#sorted + 1] = { name = name, count = count }
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    local result = {}
    for i = 1, math.min(limit or 5, #sorted) do
        result[#result + 1] = sorted[i]
    end
    return result
end

-- ============================================================
-- ENCHANTED ITEM CHARGE TRACKING (touch/target effects)
-- Touch and target enchanted item effects land on the target,
-- NOT on the caster, so they never appear in the player's
-- activeSpells. Instead, we monitor the charge of the player's
-- selected enchanted item. When charge drops, the item was used.
-- ============================================================

V.lastEnchItemId = nil  -- recordId of last selected enchanted item
V.lastEnchItemCharge = nil  -- charge level last frame
V.lastEnchItemName = nil  -- display name of last selected enchanted item
V.lastEnchItemIsScroll = false -- was last selected item a CastOnce scroll?
V.currentUiMode = nil  -- tracks active UI mode (nil = gameplay)

local function pollEnchantedItemUse()
    local item = T.Actor.getSelectedEnchantedItem(self)
    local currentId = item and item.recordId or nil

    -- Read current enchantment charge from itemData
    local currentCharge = nil
    if item then
        local chargeOk, charge = pcall(function()
            local data = T.Item.itemData(item)
            return data and data.enchantmentCharge or nil
        end)
        if chargeOk then currentCharge = charge end
    end

    -- If the selected item changed (or vanished)…
    if currentId ~= V.lastEnchItemId then
        -- If the previous item was a CastOnce scroll and it's now
        -- gone (consumed), count it as a spell cast. Scrolls are
        -- destroyed on use, so the item disappears from the slot.
        -- Only count during gameplay — if a UI is open the scroll
        -- was sold, dropped, or moved to a container, not cast.
        if V.lastEnchItemIsScroll and V.lastEnchItemName and not V.currentUiMode then
            recordSpellCast(V.lastEnchItemName)
        end

        -- Reset baseline for new item
        V.lastEnchItemId = currentId
        V.lastEnchItemCharge = currentCharge
        V.lastEnchItemIsScroll = false
        V.lastEnchItemName = nil

        if item then
            -- Check if this is a scroll (Book with CastOnce enchantment)
            pcall(function()
                if T.Book.objectIsInstance(item) then
                    local rec = T.Book.record(item)
                    if rec.enchant and rec.enchant ~= "" then
                        local enchRec = core.magic.enchantments.records[rec.enchant]
                        if enchRec and enchRec.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
                            V.lastEnchItemIsScroll = true
                            V.lastEnchItemName = rec.name
                        end
                    end
                end
            end)
            -- Also store name for charge-based items
            if not V.lastEnchItemName then
                pcall(function()
                    for _, itype in ipairs({T.Weapon, T.Armor, T.Clothing, T.Book, T.Miscellaneous}) do
                        if itype.objectIsInstance(item) then
                            V.lastEnchItemName = itype.record(item).name
                            break
                        end
                    end
                end)
            end
        end
        return
    end

    -- Same item — if charge decreased, the item was used (cast-on-use)
    if V.lastEnchItemCharge and currentCharge
       and currentCharge < V.lastEnchItemCharge then
        if V.lastEnchItemName then
            recordSpellCast(V.lastEnchItemName)
        end
    end

    V.lastEnchItemCharge = currentCharge
end

-- ============================================================
-- DISTANCE TRACKING
-- Measures distance moved per frame and classifies it:
-- on foot (grounded, not levitating), levitating, or jumping
-- Grounded/swimming/levitating movement uses planar (XY) distance
-- to avoid overcounting from vertical animation/terrain jitter.
-- (airborne, not swimming, not levitating). Accumulates in
-- local buffers and saves to storage every 2 seconds.
-- ============================================================

V.lastPosition = nil   -- vec3 from previous frame
V.distFootBuf = 0     -- accumulated on-foot distance since last save
V.distLevBuf = 0     -- accumulated levitation distance since last save
V.distJumpBuf = 0     -- accumulated jump/airborne distance since last save
V.distSwimBuf = 0     -- accumulated swimming distance since last save
V.distMountBufs = {}    -- per-mount accumulated distance: mountKey → units

-- Mount riding detection: speed-boost spell IDs added by riding mods.
-- Maps spell ID (lowercase) → mount display key.
local MOUNT_SPEED_SPELLS = {
    ["detd_horse_speed"]     = "horse",     -- Devilish Horse Riding
    ["detd_horse_speed2"]    = "horse",     -- Windhelm Horse Riding
    ["detd_whhorse_speed"]   = "horse",     -- Windhelm Horse Riding
    ["detd_guar_speed"]      = "guar",      -- Devilish Guar Riding
    ["detd_donkey_speed"]    = "donkey",     -- Donkey Riding
    ["detd_strident_speed"]  = "strident",   -- Strident Runner Riding
    ["detd_skylampspeed"]    = "skylamp",    -- Skylamp Riding
    ["detd_skybugspeed"]     = "skyrender",  -- Devilish Sky Render Riding
    ["detd_nix_speed"]       = "nix",        -- Nix Mount Riding
    ["detd_boar_speed"]      = "boar",       -- Boar Riding
}

-- Also check the levitate spells added by flying mounts, in case
-- the speed spell doesn't appear in activeSpells but the lev one does.
local MOUNT_LEV_SPELLS = {
    ["detd_whhorse_lev"]          = "horse",      -- Windhelm Horse Riding
    ["detd_levitatelamp_ability"] = "skylamp",    -- Skylamp Riding
    ["detd_levitate_ability"]     = "skyrender",  -- Devilish Sky Render Riding
    ["detd_skylamp_lev"]          = "skylamp",    -- Skylamp (alt)
    ["detd_skybug_lev"]           = "skyrender",  -- Sky Render (alt)
    ["detd_boar_lev"]              = "boar",       -- Boar Riding
}

-- Racer Riding (Lua mod) uses events rather than speed spells.
-- We hook RacerRidingStart/Stop events to track state.
V.racerRidingActive = false

-- Mounted distance uses a separate position sampler to avoid zigzag.
-- Mount mods teleport the player to the creature every MWScript frame,
-- but Lua onUpdate runs at a higher rate. Between teleport snaps the
-- player drifts away then snaps back, creating a zigzag path that's
-- much longer than the actual distance. We sample position every 0.5s
-- when mounted to let the zigzag average out.
V.mountSamplePos = nil   -- last sampled position while mounted
V.lastMountSampleTime = nil  -- simulation time of last mount sample
local MOUNT_SAMPLE_INTERVAL = 0.5  -- seconds between mount distance samples

local function pollDistance(activeSpells)
    local pos = self.position
    if not V.lastPosition then
        V.lastPosition = pos
        return
    end

    local dx = pos.x - V.lastPosition.x
    local dy = pos.y - V.lastPosition.y
    local dz = pos.z - V.lastPosition.z
    local delta2D = math.sqrt(dx * dx + dy * dy)
    local delta3D = math.sqrt(dx * dx + dy * dy + dz * dz)
    V.lastPosition = pos

    -- Ignore tiny movements (noise) and huge teleport jumps.
    -- Use planar distance for the threshold so ordinary vertical jitter
    -- from walking/terrain does not inflate travel totals.
    if delta2D < 1.0 or delta2D > 10000 then return end

    -- Classify movement state
    local isLevitating = false
    pcall(function()
        for _, activeSpell in pairs(activeSpells or T.Actor.activeSpells(self)) do
            if activeSpell.effects then
                for _, eff in ipairs(activeSpell.effects) do
                    if eff.id and eff.id == core.magic.EFFECT_TYPE.Levitate then
                        isLevitating = true
                        return
                    end
                end
            end
        end
    end)
    -- Fallback: also check activeEffects aggregate
    if not isLevitating then
        pcall(function()
            local effects = T.Actor.activeEffects(self)
            local mag = effects:getEffect(core.magic.EFFECT_TYPE.Levitate)
            if mag and type(mag) == "number" and mag > 0 then
                isLevitating = true
            end
        end)
    end

    local onGround = T.Actor.isOnGround(self)
    local swimming = T.Actor.isSwimming(self)

    -- Detect mount riding: check for mount speed/lev spells in activeSpells.
    -- Use lowercase matching since MWScript spell IDs can vary in case.
    local mountKey = nil
    pcall(function()
        for _, activeSpell in pairs(activeSpells or T.Actor.activeSpells(self)) do
            if activeSpell.id then
                local id = activeSpell.id:lower()
                local key = MOUNT_SPEED_SPELLS[id] or MOUNT_LEV_SPELLS[id]
                if key then
                    mountKey = key
                    return
                end
            end
        end
    end)
    -- Racer Riding (Lua mod): tracked via event hooks.
    -- Auto-reset when levitate drops (player dismounted).
    if not mountKey and V.racerRidingActive then
        if isLevitating then
            mountKey = "cliffracer"
        else
            V.racerRidingActive = false
        end
    end

    if mountKey then
        -- Mounted distance: use time-based sampling to avoid zigzag
        -- from MWScript position teleports (player drifts then snaps back).
        if not V.mountSamplePos then
            V.mountSamplePos = pos
            mountSampleTimer = 0
            return
        end
        local now = core.getSimulationTime()
        if not V.lastMountSampleTime then
            V.lastMountSampleTime = now
        end
        local elapsed = now - V.lastMountSampleTime
        if elapsed >= MOUNT_SAMPLE_INTERVAL then
            local mdx = pos.x - V.mountSamplePos.x
            local mdy = pos.y - V.mountSamplePos.y
            local mountDelta = math.sqrt(mdx * mdx + mdy * mdy)
            if mountDelta > 1.0 and mountDelta < 50000 then
                V.distMountBufs[mountKey] = (V.distMountBufs[mountKey] or 0) + mountDelta
            end
            V.mountSamplePos = pos
            V.lastMountSampleTime = now
        end
    else
        -- Not mounted: reset mount sampling state
        V.mountSamplePos = nil
        V.lastMountSampleTime = nil

        if isLevitating and not onGround then
            V.distLevBuf = V.distLevBuf + delta2D
        elseif swimming then
            V.distSwimBuf = V.distSwimBuf + delta2D
        elseif not onGround and not swimming and not isLevitating then
            V.distJumpBuf = V.distJumpBuf + delta3D
        elseif onGround and not swimming then
            V.distFootBuf = V.distFootBuf + delta2D
        end
    end
end

local function saveDistanceBuffers()
    if V.distFootBuf > 0 then
        addTo("distOnFoot", math.floor(V.distFootBuf))
        V.distFootBuf = V.distFootBuf - math.floor(V.distFootBuf)
    end
    if V.distLevBuf > 0 then
        addTo("distLevitated", math.floor(V.distLevBuf))
        V.distLevBuf = V.distLevBuf - math.floor(V.distLevBuf)
    end
    if V.distJumpBuf > 0 then
        addTo("distJumped", math.floor(V.distJumpBuf))
        V.distJumpBuf = V.distJumpBuf - math.floor(V.distJumpBuf)
    end
    if V.distSwimBuf > 0 then
        addTo("distSwum", math.floor(V.distSwimBuf))
        V.distSwimBuf = V.distSwimBuf - math.floor(V.distSwimBuf)
    end
    -- Per-mount distance buffers → both total and per-mount storage
    for key, buf in pairs(V.distMountBufs) do
        if buf > 0 then
            local whole = math.floor(buf)
            addTo("distMounted", whole)
            addTo("distMount_" .. key, whole)
            V.distMountBufs[key] = buf - whole
        end
    end
end

-- ============================================================
-- PERSONAL RECORDS
-- Track peak values: highest point, deepest dive, fastest speed,
-- longest fall survived. Values are sampled every frame, then flushed
-- to persistent storage periodically and on save.
-- ============================================================

-- Fall tracking: record Z when player leaves ground, compare on landing
V.fallStartZ = nil
V.wasOnGroundForFall = true

-- Speed tracking: previous position and time for velocity calculation
V.speedLastPos = nil
V.speedLastTime = nil

-- Guard fastest-speed records against teleport/scripted-relocation spikes.
-- Normal running, jumping, levitation, and riding should stay well below this.
-- Teleports, jail relocation, intervention/recall, and scripted PositionCell jumps
-- can otherwise create impossible frame-to-frame velocities.
local MAX_TRACKED_SPEED_UNITS_PER_SEC = 15000
local MAX_TRACKED_SPEED_SAMPLE_DISTANCE = 5000

local function pollPersonalRecords()
    if not state.profileId then return end
    local pos = self.position
    local z = pos.z
    local onGround = T.Actor.isOnGround(self)
    local swimming = T.Actor.isSwimming(self)

    -- Highest point reached (always track, even flying/levitating)
    storePersonalRecordIfHigher("highestPoint", z)

    -- Deepest dive: only while swimming (underwater)
    if swimming then
        -- Depth is negative Z relative to sea level (Z=0 is water surface
        -- in exteriors). We store the raw Z and invert for display.
        local currentDepth = getPersonalRecordValue("deepestDive")
        if z < currentDepth then
            setPersonalRecordValue("deepestDive", z)
        end
    end

    -- Longest fall survived: track Z on leaving ground, compare on landing
    if onGround then
        if not V.wasOnGroundForFall and V.fallStartZ then
            -- Just landed — calculate fall distance
            local fallDist = V.fallStartZ - z
            if fallDist > 0 then
                storePersonalRecordIfHigher("longestFallSurvived", math.floor(fallDist))
            end
        end
        V.fallStartZ = nil
        V.wasOnGroundForFall = true
    else
        if V.wasOnGroundForFall then
            -- Just left the ground — record starting Z
            V.fallStartZ = z
        end
        V.wasOnGroundForFall = false
    end

    -- Fastest speed: compute velocity from position delta / time delta.
    -- Reject impossible movement samples so teleports, jail, recall/intervention,
    -- and scripted relocation do not become bogus personal records.
    local currentFastest = getPersonalRecordValue("fastestSpeed")
    if currentFastest > MAX_TRACKED_SPEED_UNITS_PER_SEC then
        setPersonalRecordValue("fastestSpeed", 0)
    end

    local now = core.getSimulationTime()
    if V.speedLastPos and V.speedLastTime then
        local dt = now - V.speedLastTime
        if dt > 0.01 and dt < 2.0 then -- avoid near-zero and stale post-load/menu samples
            local dist = (pos - V.speedLastPos):length()
            if dist <= MAX_TRACKED_SPEED_SAMPLE_DISTANCE then
                local speed = dist / dt  -- game units per second
                if speed <= MAX_TRACKED_SPEED_UNITS_PER_SEC then
                    storePersonalRecordIfHigher("fastestSpeed", math.floor(speed))
                end
            end
        end
    end
    V.speedLastPos = pos
    V.speedLastTime = now

    -- Furthest from Seyda Neen: 2D distance from the Census & Excise Office.
    -- Approximate starting position: (16411, -71532) in game world coordinates.
    local SEYDA_X, SEYDA_Y = 16411, -71532
    local dx = pos.x - SEYDA_X
    local dy = pos.y - SEYDA_Y
    local dist2d = math.sqrt(dx * dx + dy * dy)
    storePersonalRecordIfHigher("furthestFromStart", math.floor(dist2d))
end
-- Stores creature name → count in a serialized string.
-- Format: "name1\tcount1\nname2\tcount2\n..."
-- Also stores creature category → count (Undead, Daedra, etc.)
-- Format: "category1\tcount1\ncategory2\tcount2\n..."
-- ============================================================

-- Creature.TYPE numeric values → display names
local CREATURE_TYPE_NAMES = {
    [0] = "Creatures",
    [1] = "Daedra",
    [2] = "Humanoid",
    [3] = "Undead",
}

V.creatureKillsCache = {}  -- name -> count
V.creatureTypesCache = {}  -- category name -> count

local function loadCreatureKillsCache()
    if not state.profileId then return end
    V.creatureKillsCache = {}
    local raw = profileSection:get("creatureKillsStr") or ""
    for line in raw:gmatch("[^\n]+") do
        local name, count = line:match("^(.+)\t(%d+)$")
        if name and count then
            V.creatureKillsCache[name] = tonumber(count)
        end
    end
    V.creatureTypesCache = {}
    local rawTypes = profileSection:get("creatureTypesStr") or ""
    for line in rawTypes:gmatch("[^\n]+") do
        local name, count = line:match("^(.+)\t(%d+)$")
        if name and count then
            V.creatureTypesCache[name] = tonumber(count)
        end
    end
end

local function saveCreatureKillsCache()
    local parts = {}
    for name, count in pairs(V.creatureKillsCache) do
        parts[#parts + 1] = name .. "\t" .. tostring(count)
    end
    profileSection:set("creatureKillsStr", table.concat(parts, "\n"))
end

local function saveCreatureTypesCache()
    local parts = {}
    for name, count in pairs(V.creatureTypesCache) do
        parts[#parts + 1] = name .. "\t" .. tostring(count)
    end
    profileSection:set("creatureTypesStr", table.concat(parts, "\n"))
end

local function recordCreatureKill(name, creatureType)
    if not name or name == "" then return end
    V.creatureKillsCache[name] = (V.creatureKillsCache[name] or 0) + 1
    saveCreatureKillsCache()
    -- Also track by category
    if creatureType ~= nil then
        local catName = CREATURE_TYPE_NAMES[creatureType] or "Unknown"
        V.creatureTypesCache[catName] = (V.creatureTypesCache[catName] or 0) + 1
        saveCreatureTypesCache()
    end
end

-- Get sorted creature kills for display (top N)
local function getTopCreatureKills(limit)
    local sorted = {}
    for name, count in pairs(V.creatureKillsCache) do
        sorted[#sorted + 1] = { name = name, count = count }
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    local result = {}
    for i = 1, math.min(limit or 10, #sorted) do
        result[#result + 1] = sorted[i]
    end
    return result
end

-- Get creature kills grouped by category (Undead, Daedra, etc.)
local function getCreatureKillsByType()
    local sorted = {}
    for name, count in pairs(V.creatureTypesCache) do
        sorted[#sorted + 1] = { name = name, count = count }
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    return sorted
end

-- ============================================================
-- LUCK MODIFIER (death-based)
-- ============================================================

local function applyLuckModifier(showNotification)
    if not mS.healthStorage:get("deathCounter") then return end
    local modifier = mS.healthStorage:get("luckModifierPerDeath") or 0
    if modifier == 0 then return end
    local luckAttr = T.Actor.stats.attributes.luck(self)
    local current  = luckAttr.base
    local chargenLuck = profileSection:get("chargenLuck")
    if not chargenLuck then
        chargenLuck = current
        profileSection:set("chargenLuck", chargenLuck)
    end
    local target = math.floor(chargenLuck + get("deathCount") * modifier)
    target = math.max(0, target)
    if current == target then return end
    luckAttr.base = target
    if showNotification and mS.healthStorage:get("showLuckChangeNotification") then
        local msgKey  = target > current and "attrUp" or "attrDown"
        local attrName = core.stats.Attribute.records["luck"].name
        ui.showMessage(L(msgKey, {stat = attrName, value = target}), {showInDialogue = false})
    end
end

-- ============================================================
-- SKILL PROGRESSION HANDLERS
-- CONFIRMED source values from live diagnostic (v7):
--   trainer visits -> 'trainer'   (NOT 'training')
--   jail sentence  -> 'jail'
--   locks unlocked -> 'skillid == security'
-- ============================================================

V.lastJailTime = -999
V.alchemyUIOpen = false
V.handlersRegistered = false  -- guard against double-registration on load

local function registerSkillHandlers()
    if V.handlersRegistered then return end

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source, options)
        if source == 'trainer' then increment("trainCount") end
    end)

    I.SkillProgression.addSkillLevelUpHandler(function(skillId, source, options)
        if source == 'jail' then
            local now = core.getSimulationTime()
            if now - V.lastJailTime > 1 then
                V.lastJailTime = now
                V.lastJailIncrement = now
                storeIfHigher("highestBounty", T.Player.getCrimeLevel(self))
                increment("jailCount")
            end
        end
    end)

    -- Security skill usage.
    -- Unlock counting is handled by lock-state polling so it also covers
    -- spells, scrolls, keys, brute force, and other non-lockpick unlocks
    -- without double-counting lockpicks here.
    I.SkillProgression.addSkillUsedHandler(function(skillid, params)
        if skillid == 'security' and params.skillGain > 0
           and params.useType == I.SkillProgression.SKILL_USE_TYPES.Security_DisarmTrap then
            increment("disarmCount")
        end
    end)

    -- Armorer: count successful repairs.
    I.SkillProgression.addSkillUsedHandler(function(skillid, params)
        if skillid == 'armorer' and params.skillGain and params.skillGain > 0 then
            increment("repairCount")
        end
    end)

    -- Enchanting: self-enchanting fires enchant skill use on success.
    -- useType 0 = Enchant_CreateItem in vanilla Morrowind.
    -- We set a flag so the UI mode close handler can skip this one
    -- (avoids double-counting when self-enchanting via the Enchanting UI).
    I.SkillProgression.addSkillUsedHandler(function(skillid, params)
        if skillid == 'enchant' and params.useType == 0 then
            increment("itemsEnchanted")
            -- Signal that this enchantment was already counted
            V.enchantItemSnapshot = nil
        end
    end)

    -- Alchemy: only count when the apparatus UI is open (not eating ingredients)
    I.SkillProgression.addSkillUsedHandler(function(skillId, options)
        if skillId == "alchemy" and V.alchemyUIOpen then
            increment("alchemyCount")
        end
    end)
end

-- ============================================================
-- SCRIB PETTING COUNTER
-- Counts triggered by ScribPetted event from scripts/SC/scrib.lua
-- ============================================================

local function onScribPetted()
    if not state.profileId then return end
    increment("scribCount")
end

-- ============================================================
-- POTION TRACKING via UiModeChanged + hotkey poll
-- ============================================================

V.potionSnapshot = nil
V.inventoryWasOpen = false
V.barterWasOpen = false

local function countPotions()
    local total = 0
    -- Exclude Sun's Dusk registered consumables (cooked meals, drinks, etc.)
    local sdEntries = nil
    local ok, sd = pcall(function() return I.SunsDusk end)
    if ok and sd then
        local sdOk, sdData = pcall(function() return sd.getSaveData() end)
        if sdOk and sdData then sdEntries = sdData.registeredConsumables end
    end
    for _, item in pairs(T.Actor.inventory(self):getAll(T.Potion)) do
        local skip = false
        if sdEntries and sdEntries[item.recordId] then
            skip = true
        end
        if not skip then
            total = total + item.count
        end
    end
    return total
end

-- ============================================================
-- LOCKPICK & PROBE BROKEN TRACKING
-- Snapshot counts when Inventory opens (same barter exclusion
-- as potions). A decrease while not bartering = item(s) broke.
-- Lockpicks also break during gameplay (no UI), so we also
-- poll during onUpdate when no menu is open.
-- ============================================================

V.lockpickSnapshot = nil
V.probeSnapshot = nil
V.lockpickBaseline = nil  -- for hotkey/gameplay breaks
V.probeBaseline = nil

local function countLockpicks()
    local t = 0
    for _, item in pairs(T.Actor.inventory(self):getAll(T.Lockpick)) do
        t = t + item.count
    end
    return t
end

local function countProbes()
    local t = 0
    for _, item in pairs(T.Actor.inventory(self):getAll(T.Probe)) do
        t = t + item.count
    end
    return t
end

-- ============================================================
-- TRAVEL TRACKING via Dialogue close + position change heuristic
-- When Dialogue closes and the player's position changed by more
-- than 1000 units, that was a travel service (Silt Strider, boat,
-- guild guide). Cell name comparison fails for exterior cells
-- (they have empty names), so we use position distance instead.
-- ============================================================


V.seenInterventionSpells = {}  -- activeSpellId -> true, once counted

-- INTERVENTION_IDS maps effect id -> true (AlmsivI + Divine only)
V.INTERVENTION_IDS = nil

-- Recall detection — two paths:
--   Vanilla: activeSpells scan + activeEffects rising-edge fallback
--   LMM: openMarkMenu event → snapshot position → watch for >5000 unit move
V.lmmRecallPending = false  -- LMM recall: menu opened, watching for teleport
V.lmmRecallPos = nil    -- position when LMM menu opened
V.lmmRecallTimeout = 0      -- frames remaining to watch
V.vanillaRecallWasActive = false  -- for activeEffects rising-edge fallback

local function cellId(cell)
    if cell == nil then return "nil" end
    -- cell.id is the unique record ID used by the engine (works for interior and exterior)
    local ok, id = pcall(function() return cell.id end)
    if ok and id then return id end
    return tostring(cell)
end

local function onLmmOpenMarkMenu()
    -- LMM sends this event when Recall menu opens.
    -- Snapshot position and start watching for teleport.
    V.lmmRecallPending = true
    V.lmmRecallPos     = self.object.position
    V.lmmRecallTimeout = 300  -- 5 seconds at 60fps — player may browse marks
end

V.RECALL_EFFECT_ID = nil  -- cached core.magic.EFFECT_TYPE.Recall

local function buildInterventionIds()
    V.INTERVENTION_IDS = {}
    local function safeGet(k)
        local ok, v = pcall(function() return core.magic.EFFECT_TYPE[k] end)
        return ok and v or nil
    end
    local almsivi = safeGet("AlmsiviIntervention")
    local divine  = safeGet("DivineIntervention")
    if almsivi then V.INTERVENTION_IDS[almsivi] = true end
    if divine  then V.INTERVENTION_IDS[divine]  = true end
    V.RECALL_EFFECT_ID = safeGet("Recall")
end

local function pollTeleportSpells(activeSpells)
    if V.INTERVENTION_IDS == nil then
        buildInterventionIds()
    end
    local mode = I.UI.getMode()
    if mode == 'Dialogue' then return end

    -- LMM RECALL: watch for large position change after menu opened
    if V.lmmRecallPending and V.lmmRecallPos then
        V.lmmRecallTimeout = V.lmmRecallTimeout - 1
        local currentPos = self.object.position
        local dx = currentPos.x - V.lmmRecallPos.x
        local dy = currentPos.y - V.lmmRecallPos.y
        local dz = currentPos.z - V.lmmRecallPos.z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        if dist > 5000 then
            increment("recallCount")
            V.lmmRecallPending = false
            V.lmmRecallPos     = nil
            V.lmmRecallTimeout = 0
        elseif V.lmmRecallTimeout <= 0 then
            -- Timed out — player opened menu but didn't recall
            V.lmmRecallPending = false
            V.lmmRecallPos     = nil
        end
    end

    -- VANILLA RECALL: activeEffects rising-edge detection.
    -- Recall is an instant effect — check if the magnitude just became >0.
    -- This won't fire with LMM installed (LMM replaces the vanilla spell).
    if V.RECALL_EFFECT_ID then
        local recallEff    = T.Actor.activeEffects(self):getEffect(V.RECALL_EFFECT_ID)
        local recallActive = recallEff ~= nil and recallEff.magnitude > 0
        if recallActive and not V.vanillaRecallWasActive then
            increment("recallCount")
        end
        V.vanillaRecallWasActive = recallActive
    end

    -- VANILLA RECALL FALLBACK: also scan activeSpells in case the
    -- rising-edge misses very short-lived effects.
    -- INTERVENTIONS: also detected here via activeSpells scan.
    for _, activeSpell in pairs(activeSpells or T.Actor.activeSpells(self)) do
        local spellId = activeSpell.activeSpellId
        if not V.seenInterventionSpells[spellId] then
            for _, effect in ipairs(activeSpell.effects) do
                if V.RECALL_EFFECT_ID and effect.id == V.RECALL_EFFECT_ID then
                    V.seenInterventionSpells[spellId] = true
                    increment("recallCount")
                    break
                elseif V.INTERVENTION_IDS[effect.id] then
                    V.seenInterventionSpells[spellId] = true
                    increment("interventionCount")
                    break
                end
            end
        end
    end
end


-- ============================================================
-- SLAVE FREED TRACKING
-- Two-pronged approach:
-- 1. Snapshot before dialogue, compare after — catches the
--    moment a slave is freed via dialogue (vanilla or mods).
--    Freed slaves often change class immediately even before
--    walking away.
-- 2. Continuous poll every 2s — catches slaves freed by
--    spells, scripts, or other non-dialogue methods.
-- Both methods update the same baseline to avoid double-counting.
-- ============================================================

V.slaveNpcSnapshot = nil  -- count of nearby enslaved NPCs
V.slaveDialogueSnapshot = nil  -- snapshot taken when dialogue opens
V.travelCellSnapshot = nil   -- cell when dialogue opened
V.travelPosSnapshot = nil   -- player position when dialogue opened
V.travelWasExterior = nil   -- was the snapshot cell exterior?
V.travelCheckActive = false -- true while waiting for cell change after dialogue
V.travelCheckTimeout = 0     -- frames remaining to watch

-- Count nearby NPCs whose NPC class record is "slave"
local function countNearbySlaves()
    local count = 0
    for _, obj in ipairs(nearby.actors) do
        if T.NPC.objectIsInstance(obj) then
            local ok, rec = pcall(function() return T.NPC.record(obj) end)
            if ok and rec and rec.class then
                local classLower = string.lower(rec.class)
                if classLower == "slave" then
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function pollSlavesFreed()
    local mode = I.UI.getMode()
    -- Don't poll during dialogue — handled by dialogue open/close
    if mode == 'Dialogue' then return end
    local current = countNearbySlaves()
    if V.slaveNpcSnapshot == nil then
        V.slaveNpcSnapshot = current
        return
    end
    local delta = V.slaveNpcSnapshot - current
    if delta > 0 then
        addTo("slavesFreed", delta)
    end
    V.slaveNpcSnapshot = current
end

-- ============================================================
-- SLEEP/WAIT HOURS TRACKING
-- Snapshot game time when Rest mode opens; diff on close.
-- ============================================================

V.restStartGameTime = nil

-- ============================================================
-- SPELLMAKING TRACKING
-- Snapshot spell count when SpellBuyingAndCreation opens.
-- An increase when it closes = new spell(s) created.
-- ============================================================

V.spellCountSnapshot = nil
V.enchantItemSnapshot = nil  -- total enchanted-item count before Enchanting UI

local function countPlayerSpells()
    local count = 0
    for _ in pairs(T.Actor.spells(self)) do count = count + 1 end
    return count
end

-- Count items with an enchantment in the player inventory
local function countEnchantedItems()
    local total = 0
    for _, typeTable in ipairs({T.Weapon, T.Armor, T.Clothing, T.Book}) do
        local ok, items = pcall(function() return T.Actor.inventory(self):getAll(typeTable) end)
        if ok and items then
            for _, item in pairs(items) do
                local rok, rec = pcall(function() return typeTable.record(item) end)
                if rok and rec and rec.enchant and rec.enchant ~= '' then
                    total = total + item.count
                end
            end
        end
    end
    return total
end

-- ============================================================
-- FORAGING / PLANT HARVESTING TRACKING
-- Two methods to catch both vanilla containers and Graphic
-- Herbalism (which bypasses the container UI entirely):
--
-- 1. Container UI: snapshot ingredient count when Container
--    mode opens. When it closes, count ingredient *increase*
--    as the number of plants foraged.
--
-- 2. Polling: every 2s, compare ingredient count. If it rose
--    while no container/barter/alchemy UI is open, that's
--    likely a Graphic Herbalism harvest (direct loot). Count
--    each increase as one forage event.
-- ============================================================

V.forageIngredientSnapshot = nil  -- for Container UI method
V.lastIngredientCount = nil       -- for polling method
V.foragePollCooldown = 0          -- suppress poll for N seconds after container/etc close

local function countIngredients()
    local total = 0
    for _, item in pairs(T.Actor.inventory(self):getAll(T.Ingredient)) do
        total = total + item.count
    end
    return total
end

-- ============================================================
-- SOUL GEM COUNTING (needed by both UiModeChanged and pollSoulGems)
-- Defined here so it's visible to both.
-- ============================================================

V.filledGemBaseline = nil

local function countFilledSoulGems()
    local count = 0
    for _, item in pairs(T.Actor.inventory(self):getAll(T.Miscellaneous)) do
        local ok, data = pcall(function() return T.Item.itemData(item) end)
        if ok and data and data.soul and data.soul ~= "" then
            count = count + item.count
        end
    end
    return count
end

-- ============================================================
-- UI MODE CHANGED — central handler
-- ============================================================

local function onUiModeChanged(data)
    -- Track the active UI mode for scroll-cast detection.
    -- When a UI is open, scroll disappearance is manipulation, not casting.
    V.currentUiMode = data.newMode

    -- Clear any "done" reset buttons when leaving the settings menu
    -- (returning to gameplay or switching to another UI mode)
    if data.newMode ~= data.oldMode then
        for _, rt in ipairs(mS.resetToggles) do
            if rt.storage:get(rt.toggle) == "done" then
                rt.storage:set(rt.toggle, false)
            end
        end
    end

    -- ALCHEMY: track apparatus UI open/close
    if data.newMode == 'Alchemy' then
        V.alchemyUIOpen = true
    elseif data.oldMode == 'Alchemy' then
        V.alchemyUIOpen = false
    end

    -- SPELLMAKING: snapshot on open, compare on close
    -- The actual OpenMW mode name is 'SpellCreation' (not SpellBuyingAndCreation)
    if data.newMode == 'SpellCreation' then
        V.spellCountSnapshot = countPlayerSpells()
    elseif data.oldMode == 'SpellCreation' and V.spellCountSnapshot ~= nil then
        local nowSpells = countPlayerSpells()
        local delta = nowSpells - V.spellCountSnapshot
        if delta > 0 then
            addTo("spellsMade", delta)
        end
        V.spellCountSnapshot = nil
    end

    -- ENCHANTING (NPC service): snapshot enchanted items on open, compare on close.
    -- Self-enchanting is caught by the skillUsedHandler below.
    if data.newMode == 'Enchanting' then
        V.enchantItemSnapshot = countEnchantedItems()
    elseif data.oldMode == 'Enchanting' and V.enchantItemSnapshot ~= nil then
        local nowItems = countEnchantedItems()
        local delta = nowItems - V.enchantItemSnapshot
        if delta > 0 then
            addTo("itemsEnchanted", delta)
        end
        V.enchantItemSnapshot = nil
    end

    -- FORAGING: two paths — Container UI (vanilla plants) and poll (Graphic Herbalism).
    -- For the Container UI path, we need to check if the container is organic.
    -- Refresh the ingredient baseline whenever any non-organic-container mode closes.
    local isOpeningOrganic = false
    if data.newMode == 'Container' then
        -- Check if this is an organic container (plant)
        if data.arg then
            local ok, rec = pcall(function() return T.Container.record(data.arg) end)
            if ok and rec and rec.isOrganic then
                isOpeningOrganic = true
            end
        end
        if isOpeningOrganic then
            V.forageIngredientSnapshot = countIngredients()
        else
            V.forageIngredientSnapshot = nil
            -- Refresh baseline now so poll doesn't count mid-container gains
            V.lastIngredientCount = countIngredients()
        end
    end
    if data.oldMode == 'Container' then
        if V.forageIngredientSnapshot ~= nil then
            -- This was an organic container — count ingredients gained
            local nowIngredients = countIngredients()
            local delta = nowIngredients - V.forageIngredientSnapshot
            if delta > 0 then
                addTo("plantsForaged", delta)
            end
            V.forageIngredientSnapshot = nil
        end
        -- Always refresh baseline after any container closes, and set cooldown
        -- to suppress the poll for a few seconds. This prevents mods like TakeAll
        -- (which transfer items via global events AFTER closing the container UI)
        -- from being miscounted as foraging.
        V.lastIngredientCount = countIngredients()
        V.foragePollCooldown = 4.0
    end

    -- Refresh baseline when other item-changing modes close
    if data.oldMode == 'Barter' or data.oldMode == 'Alchemy'
       or data.oldMode == 'Companion' or data.oldMode == 'Dialogue' then
        V.lastIngredientCount = countIngredients()
        V.foragePollCooldown = 4.0
    end

    -- BOOKS READ
    if data.newMode == 'Book' and data.arg then
        local ok, recordId = pcall(function() return T.Book.record(data.arg).id end)
        if ok and recordId and markBookSeen(recordId) then
            increment("bookCount")
        end
    end

    -- SLEEP / WAIT HOURS
    if data.newMode == 'Rest' then
        V.restStartGameTime = core.getGameTime()
    elseif data.oldMode == 'Rest' and V.restStartGameTime ~= nil then
        local elapsed = core.getGameTime() - V.restStartGameTime
        if elapsed > 0 then
            -- Convert game seconds to hours
            addTo("sleepHours", elapsed / 3600)
        end
        V.restStartGameTime = nil
    end

    -- TRAVEL TRACKING: detect NPC travel services (silt strider, boat,
    -- guild guide). Snapshot position on dialogue open. On dialogue close,
    -- start a short watch — the PositionCell teleport fires shortly after
    -- dialogue ends. The watch requires BOTH >5000 unit movement AND same
    -- cell type (exterior→exterior or interior→interior) to count.
    if data.newMode == 'Dialogue' then
        if not V.travelCheckActive then
            V.travelPosSnapshot   = self.object.position
            V.travelCellSnapshot  = self.object.cell
            local snapOk, snapExt = pcall(function() return self.object.cell.isExterior end)
            V.travelWasExterior  = snapOk and snapExt or nil
        end

        -- PEOPLE MET: count a unique NPC the moment dialogue is opened.
        -- This is the reliable first-contact signal and works even on builds
        -- where DialogueResponse is unavailable or the NPC does not emit a
        -- response line that reaches the player script.
        if data.arg and T.NPC.objectIsInstance(data.arg) then
            local npcId = nil
            local okRec, rec = pcall(function() return T.NPC.record(data.arg) end)
            if okRec and rec and rec.id then
                npcId = string.lower(rec.id)
            elseif data.arg.recordId then
                npcId = string.lower(data.arg.recordId)
            elseif data.arg.id then
                npcId = string.lower(data.arg.id)
            end
            if npcId and npcId ~= '' and not V.peopleMetCache[npcId] then
                V.peopleMetCache[npcId] = true
                local parts = {}
                for id in pairs(V.peopleMetCache) do
                    parts[#parts + 1] = id
                end
                set('peopleMetStr', table.concat(parts, '\n'))
                set('peopleMet', #parts)
            end
        end

        -- Snapshot slave count BEFORE dialogue for comparison after
        V.slaveDialogueSnapshot = countNearbySlaves()
    elseif data.oldMode == 'Dialogue' then
        -- Check if slaves were freed during this dialogue
        if V.slaveDialogueSnapshot ~= nil then
            local nowSlaves = countNearbySlaves()
            local delta = V.slaveDialogueSnapshot - nowSlaves
            if delta > 0 then
                addTo("slavesFreed", delta)
            end
            V.slaveDialogueSnapshot = nil
        end
        -- Update continuous poll baseline to current count
        -- so the poll doesn't double-count the same freed slaves
        V.slaveNpcSnapshot = countNearbySlaves()

        -- Start post-dialogue travel watch (120 frames ≈ 2s at 60fps).
        -- The actual teleport happens shortly after dialogue closes.
        if V.travelPosSnapshot and not V.travelCheckActive then
            V.travelCheckActive  = true
            V.travelCheckTimeout = 120
        end
    end

    -- TELEPORT SPELLS: handled by pollTeleportSpells() in onUpdate
    -- RECALL/TELEPORT: cell-change outside dialogue counts as travelCount

    -- POTION CONSUMPTION VIA INVENTORY
    if data.newMode == 'Inventory' then
        V.inventoryWasOpen = true
        V.barterWasOpen    = false
        V.potionSnapshot   = countPotions()
        V.lockpickSnapshot = countLockpicks()
        V.probeSnapshot    = countProbes()
    elseif data.newMode == 'Barter' then
        V.barterWasOpen = true
    elseif data.oldMode == 'Inventory' and not V.barterWasOpen then
        if V.potionSnapshot ~= nil then
            local delta = V.potionSnapshot - countPotions()
            if delta > 0 then addTo("potionCount", delta) end
        end
        if V.lockpickSnapshot ~= nil then
            local delta = V.lockpickSnapshot - countLockpicks()
            if delta > 0 then addTo("lockpicksBroken", delta) end
        end
        if V.probeSnapshot ~= nil then
            local delta = V.probeSnapshot - countProbes()
            if delta > 0 then addTo("probesBroken", delta) end
        end
        V.inventoryWasOpen = false
        V.potionSnapshot   = nil
        V.lockpickSnapshot = nil
        V.probeSnapshot    = nil
    elseif data.oldMode == 'Barter' then
        V.barterWasOpen = false
        -- After barter, refresh baselines so the inventory close doesn't miscount
        V.potionSnapshot   = countPotions()
        V.lockpickSnapshot = countLockpicks()
        V.probeSnapshot    = countProbes()
        -- Refresh soul gem baseline so bought pre-filled gems aren't counted as trapped
        V.filledGemBaseline = countFilledSoulGems()
    end
end

-- ============================================================
-- QUEST COMPLETION TRACKING (15-second staggered poll)
-- ============================================================

local QUEST_POLL_INTERVAL  = 15.0
local HEAVY_POLL_INTERVAL  = 30.0
V.lastFinishedQuests = nil

local function pollQuests()
    local finished = 0
    for _, q in pairs(T.Player.quests(self)) do
        if q.finished then finished = finished + 1 end
    end
    if V.lastFinishedQuests == nil then
        V.lastFinishedQuests = get("questCount")
        if V.lastFinishedQuests == 0 and finished > 0 then
            set("questCount", finished)
            V.lastFinishedQuests = finished
        end
    else
        local delta = finished - V.lastFinishedQuests
        if delta > 0 then
            addTo("questCount", delta)
            V.lastFinishedQuests = finished
        end
    end
end

local function isMainQuestCompletionQuest(q)
    if type(q) ~= "table" or not q.finished then return false end

    local fields = { q.name, q.id, q.questId, q.recordId, q.journalId, q.topic, q.title }
    for _, value in ipairs(fields) do
        if type(value) == "string" then
            local lower = value:lower()
            if lower:find('sleepers awake', 1, true) then return true end
            if lower == 'a2_2_6thhouse' or lower == 'a2_6thhouse' then return true end
        end
    end
    return false
end

local function pollMainQuestSummaryAutoOpen()
    if get('mainQuestSummaryShown') then return end

    local quests = T.Player.quests(self)
    if type(quests) ~= 'table' then return end

    for _, q in pairs(quests) do
        if isMainQuestCompletionQuest(q) then
            set('mainQuestSummaryShown', true)
            core.sendGlobalEvent('SC_MainQuestSummaryUnlocked', { profileId = state.profileId })
            pcall(function() mSummaryUi.show(state) end)
            return
        end
    end
end

-- ============================================================
-- HOTKEY POTION TRACKING (no UI open)
-- ============================================================

V.hotkeyPotionBaseline = nil

local function pollHotkeyPotions()
    local mode = I.UI.getMode()
    if mode ~= nil then return end
    local current = countPotions()
    if V.hotkeyPotionBaseline == nil then
        V.hotkeyPotionBaseline = current
        return
    end
    local delta = V.hotkeyPotionBaseline - current
    if delta > 0 then addTo("potionCount", delta) end
    V.hotkeyPotionBaseline = current
end

-- ============================================================
-- LOCKPICK / PROBE GAMEPLAY POLL (breaks outside inventory)
-- Lockpicks and probes break during use (Security skill use).
-- We poll counts when no UI is open to catch these.
-- ============================================================

local function pollToolBreaks()
    local mode = I.UI.getMode()
    if mode ~= nil then return end
    local lp = countLockpicks()
    local pr = countProbes()
    if V.lockpickBaseline == nil then
        V.lockpickBaseline = lp
    else
        local delta = V.lockpickBaseline - lp
        if delta > 0 then addTo("lockpicksBroken", delta) end
        V.lockpickBaseline = lp
    end
    if V.probeBaseline == nil then
        V.probeBaseline = pr
    else
        local delta = V.probeBaseline - pr
        if delta > 0 then addTo("probesBroken", delta) end
        V.probeBaseline = pr
    end
end

-- (cell change detection removed - teleport now handled via active effects)

-- ============================================================
-- LOCK OPEN TRACKING (poll lock-state transitions nearby)
-- Counts a lock as opened when a nearby lockable object changes from
-- locked -> unlocked. This covers lockpicks, spells, scrolls, keys,
-- brute force, and scripted unlocks.
--
-- We intentionally do not increment unlockCount from the Security
-- skill-used hook, because that would double-count lockpick unlocks.
-- ============================================================

V.lockStateBaseline = {}
local LOCKABLE = T.LOCKABLE or T.Lockable

local function isLockableObject(obj)
    if not obj or not obj:isValid() then return false end

    if LOCKABLE and LOCKABLE.objectIsInstance then
        local ok, result = pcall(function()
            return LOCKABLE.objectIsInstance(obj)
        end)
        if ok then return result == true end
    end

    if T.Door and T.Door.objectIsInstance then
        local ok, result = pcall(function()
            return T.Door.objectIsInstance(obj)
        end)
        if ok and result then return true end
    end

    if T.Container and T.Container.objectIsInstance then
        local ok, result = pcall(function()
            return T.Container.objectIsInstance(obj)
        end)
        if ok and result then return true end
    end

    return false
end

local function getLockedState(obj)
    if LOCKABLE and LOCKABLE.isLocked then
        local ok, result = pcall(function()
            return LOCKABLE.isLocked(obj)
        end)
        if ok and type(result) == "boolean" then return result end
    end

    if T.Door and T.Door.isLocked and T.Door.objectIsInstance and T.Door.objectIsInstance(obj) then
        local ok, result = pcall(function()
            return T.Door.isLocked(obj)
        end)
        if ok and type(result) == "boolean" then return result end
    end

    if T.Container and T.Container.isLocked and T.Container.objectIsInstance and T.Container.objectIsInstance(obj) then
        local ok, result = pcall(function()
            return T.Container.isLocked(obj)
        end)
        if ok and type(result) == "boolean" then return result end
    end

    -- Fallbacks for older / differing APIs.
    for _, key in ipairs({ "isLocked", "locked" }) do
        local ok, result = pcall(function()
            local value = obj[key]
            if type(value) == "function" then
                return value(obj)
            end
            return value
        end)
        if ok and type(result) == "boolean" then
            return result
        end
    end

    return nil
end

V.unlockPollAccumulator = 0
local UNLOCK_POLL_INTERVAL = 0.25

local function pollUnlocks()
    local mode = I.UI.getMode()
    if mode ~= nil then return end

    local currentSeen = {}

    local function scanLockables(list)
        for _, obj in ipairs(list) do
            if isLockableObject(obj) then
                local oid = obj.id
                currentSeen[oid] = true

                local locked = getLockedState(obj)
                if type(locked) == "boolean" then
                    local prev = V.lockStateBaseline[oid]
                    if prev == nil then
                        V.lockStateBaseline[oid] = locked
                    else
                        if prev == true and locked == false then
                            increment("unlockCount")
                        end
                        V.lockStateBaseline[oid] = locked
                    end
                end
            end
        end
    end

    scanLockables(nearby.doors)
    scanLockables(nearby.containers)

    for oid in pairs(V.lockStateBaseline) do
        if not currentSeen[oid] then
            V.lockStateBaseline[oid] = nil
        end
    end
end

-- ============================================================
-- SOUL TRAP TRACKING (filled soul gem poll)
-- Count soul gems in the player's inventory that have a soul.
-- An increase when no UI is open = the player trapped a soul
-- (via spell, enchanted weapon, scroll, etc.). Excludes barter
-- purchases by refreshing baseline on barter close.
-- ============================================================

local function pollSoulGems()
    local mode = I.UI.getMode()
    if mode ~= nil then return end
    local current = countFilledSoulGems()
    if V.filledGemBaseline == nil then
        V.filledGemBaseline = current
        return
    end
    local delta = current - V.filledGemBaseline
    if delta > 0 then
        addTo("trapCount", delta)
    end
    V.filledGemBaseline = current
end

-- ============================================================
-- COMBAT DAMAGE TAKEN (via I.Combat.addOnHitHandler on player)
-- This handler runs on the player (the victim) and captures
-- health damage from successful combat hits (melee, ranged,
-- hand-to-hand). The damage value is read after the engine's
-- default handler pipeline, so it reflects post-armor values.
-- ============================================================

V.markRecentCombatHit = nil
local function registerCombatDamageHandler()
    -- Guard is checked in registerSkillHandlers; both are called together.
    -- We only mark the time of the hit here and let the health snapshot poll
    -- account for the actual post-mitigation HP loss. This is more reliable
    -- across OpenMW versions/builds than trusting attack.damage.health here.
    I.Combat.addOnHitHandler(function(attack)
        if not state.profileId then return end
        if not attack.successful then return end
        V.markRecentCombatHit()
    end)
end

-- ============================================================
-- TOTAL DAMAGE TAKEN (health-poll approach)
-- Catches ALL sources of HP loss: combat, magic (Damage Health,
-- Drain Health, Sun Damage, etc.), fall damage, lava, traps,
-- and any other environmental or scripted damage.
-- We snapshot current health each frame; a decrease that is NOT
-- explained by natural regen being negative means damage.
-- We ignore health *gains* (potions, Restore Health, regen).
-- ============================================================

V.lastHealthSnapshot = nil
V.lastCombatHitTime = -math.huge
local COMBAT_DAMAGE_WINDOW = 1.0

V.markRecentCombatHit = function()
    V.lastCombatHitTime = core.getSimulationTime()
end

local function pollDamageTaken()
    local hp = T.Actor.stats.dynamic.health(self).current
    if V.lastHealthSnapshot == nil then
        V.lastHealthSnapshot = hp
        return
    end
    if hp < V.lastHealthSnapshot then
        local lost = V.lastHealthSnapshot - hp
        local lostInt = math.floor(lost)
        if lostInt > 0 then
            addTo("damageTaken", lostInt)
            if (core.getSimulationTime() - V.lastCombatHitTime) <= COMBAT_DAMAGE_WINDOW then
                addTo("combatDamageTaken", lostInt)
            end
        end
    end
    V.lastHealthSnapshot = hp
end

-- ============================================================
-- PEAK VALUE POLLING (gold, bounty, hotkeys) — 2s interval
-- ============================================================
-- FORAGING POLL (Graphic Herbalism support)
-- When the player gains ingredients outside any UI (no
-- Container, Barter, or Alchemy mode), it's a Graphic
-- Herbalism harvest or similar direct-pickup interaction.
-- Count each increase as foraged items.
-- ============================================================

local POLL_INTERVAL   = 2.0

local function pollForaging()
    local mode = I.UI.getMode()
    -- Don't poll during UI modes that can change ingredient count
    if mode == 'Container' or mode == 'Barter' or mode == 'Alchemy'
       or mode == 'Companion' then
        return
    end
    -- Cooldown: after a container/barter/etc closes, suppress the poll
    -- for a few seconds to let mods like TakeAll finish transferring items.
    if V.foragePollCooldown > 0 then
        V.foragePollCooldown = V.foragePollCooldown - POLL_INTERVAL
        -- Refresh baseline at end of cooldown so we start clean
        V.lastIngredientCount = countIngredients()
        return
    end
    local current = countIngredients()
    if V.lastIngredientCount == nil then
        V.lastIngredientCount = current
        return
    end
    local delta = current - V.lastIngredientCount
    if delta > 0 then
        addTo("plantsForaged", delta)
    end
    V.lastIngredientCount = current
end

-- All poll functions must be defined ABOVE this point.
-- ============================================================

-- ============================================================
-- BOUNTY PAID DETECTION
-- Polls the player's crime level. When it drops to 0 from a
-- positive value without a jail event, it means the player paid.
-- Tracks the total gold value paid in bounties.
-- ============================================================

V.lastBountyLevel = nil
V.lastJailIncrement = 0  -- simulation time of last jail increment
V.lastBountyFrame = nil  -- per-frame bounty for crime detection

local function pollBountyPaid()
    local current = T.Player.getCrimeLevel(self)
    if V.lastBountyLevel == nil then
        V.lastBountyLevel = current
        return
    end
    -- Bounty went from positive to zero
    if V.lastBountyLevel > 0 and current == 0 then
        -- Only count if we didn't just go to jail (within last 5 seconds)
        local now = core.getSimulationTime()
        if now - V.lastJailIncrement > 5 then
            addTo("bountiesPaid", V.lastBountyLevel)
        end
    end
    V.lastBountyLevel = current
end

-- Per-frame crime detection: watches for bounty increases.
-- Each frame where bounty increases counts as exactly one crime.
-- Classification uses GMST thresholds:
--   delta >= iCrimeMurder  → murder
--   delta >= iCrimeAssault → assault
--   delta < iCrimeAssault  → theft/other (not counted here)
local function pollCrimes()
    local current = T.Player.getCrimeLevel(self)
    if V.lastBountyFrame == nil then
        V.lastBountyFrame = current
        return
    end
    if current > V.lastBountyFrame then
        local delta = current - V.lastBountyFrame
        -- Get crime bounty thresholds from GMSTs
        local murderBounty = 1000
        local assaultBounty = 40
        pcall(function()
            local m = core.getGMST("iCrimeMurder")
            local a = core.getGMST("iCrimeAssault")
            if type(m) == "number" and m > 0 then murderBounty = m end
            if type(a) == "number" and a > 0 then assaultBounty = a end
        end)
        -- Classify: one crime per bounty increase event
        if delta >= murderBounty then
            increment("murderCount")
        elseif delta >= assaultBounty then
            increment("assaultCount")
        end
        -- delta < assaultBounty = theft/trespass/other, not counted
    end
    V.lastBountyFrame = current
end

-- ============================================================
-- KNOCKDOWN DETECTION
-- Polls Actor.canMove(). When it goes from true to false while
-- the player is alive and not in a menu, that's a knockdown.
-- We exclude death and UI modes (dialogue, menus, etc.).
-- ============================================================

V.wasAbleToMove = true

local function pollKnockdown()
    local mode = I.UI.getMode()
    if mode ~= nil then return end  -- ignore menu states
    local alive = not T.Actor.isDead(self)
    if not alive then
        V.wasAbleToMove = true  -- reset on death
        return
    end
    local canMove = T.Actor.canMove(self)
    if V.wasAbleToMove and not canMove then
        increment("knockdownCount")
    end
    V.wasAbleToMove = canMove
end

local PERF_LOG = false
local PERF_THRESHOLD = 0.002

local function timed(name, fn)
    if not PERF_LOG then
        fn()
        return
    end

    local start = core.getRealTime()
    fn()
    local elapsed = core.getRealTime() - start
    if elapsed >= PERF_THRESHOLD then
        print(string.format("[SC PERF] %s took %.4f sec", name, elapsed))
    end
end

local function pollBaselineStats()
    storeIfHigher("mostGold", T.Actor.inventory(self):countOf("gold_001"))
    storeIfHigher("highestBounty", T.Player.getCrimeLevel(self))
    pollBountyPaid()
    pollGoldFound()
end

local function pollQuestsAndSummary()
    pollQuests()
    pollMainQuestSummaryAutoOpen()
end

local function flushTimedPlaySeconds()
    flushPlaySeconds()
end

local function flushTimedPersonalRecords()
    flushPersonalRecords()
end

local pollTasks = {
    { name = "baselineStats",        interval = POLL_INTERVAL,              acc = 0.00, fn = pollBaselineStats },
    { name = "hotkeyPotions",        interval = POLL_INTERVAL,              acc = -0.25, fn = pollHotkeyPotions },
    { name = "toolBreaks",           interval = POLL_INTERVAL,              acc = -0.50, fn = pollToolBreaks },
    { name = "soulGems",             interval = POLL_INTERVAL,              acc = -0.75, fn = pollSoulGems },
    { name = "slavesFreed",          interval = POLL_INTERVAL,              acc = -1.00, fn = pollSlavesFreed },
    { name = "foraging",             interval = POLL_INTERVAL,              acc = -1.25, fn = pollForaging },
    { name = "distanceBuffers",      interval = POLL_INTERVAL,              acc = -1.50, fn = saveDistanceBuffers },
    { name = "playSeconds",          interval = PLAY_SECONDS_FLUSH_INTERVAL, acc = -1.75, fn = flushTimedPlaySeconds },
    { name = "personalRecords",      interval = PERSONAL_RECORD_FLUSH_INTERVAL, acc = -1.90, fn = flushTimedPersonalRecords },

    -- Heavier passive scans do not need two-second precision. Keeping them
    -- slower preserves behavior while avoiding the visible periodic Lua spike.
    { name = "artifacts",            interval = HEAVY_POLL_INTERVAL,       acc = HEAVY_POLL_INTERVAL - 2.00, fn = pollArtifacts },
    { name = "diseases",             interval = HEAVY_POLL_INTERVAL,       acc = HEAVY_POLL_INTERVAL - 4.00, fn = pollDiseases },
    { name = "spellEffects",         interval = HEAVY_POLL_INTERVAL,       acc = HEAVY_POLL_INTERVAL - 6.00, fn = pollSpellEffects },
    { name = "quests",               interval = QUEST_POLL_INTERVAL,       acc = QUEST_POLL_INTERVAL - 8.00, fn = pollQuestsAndSummary },
}

local function pollPeakValues(deltaTime)
    for _, task in ipairs(pollTasks) do
        task.acc = task.acc + deltaTime
        if task.acc >= task.interval then
            task.acc = task.acc - task.interval
            timed(task.name, task.fn)
        end
    end

    -- Intervention detection runs every frame (activeSpells check)
end

-- Reset staggered scheduler offsets after loading or starting a game.
local function resetPollTaskAccumulators()
    for _, task in ipairs(pollTasks) do
        if task.name == "baselineStats" then task.acc = 0.00
        elseif task.name == "hotkeyPotions" then task.acc = -0.25
        elseif task.name == "toolBreaks" then task.acc = -0.50
        elseif task.name == "soulGems" then task.acc = -0.75
        elseif task.name == "slavesFreed" then task.acc = -1.00
        elseif task.name == "foraging" then task.acc = -1.25
        elseif task.name == "distanceBuffers" then task.acc = -1.50
        elseif task.name == "playSeconds" then task.acc = -1.75
        elseif task.name == "personalRecords" then task.acc = -1.90
        elseif task.name == "artifacts" then task.acc = HEAVY_POLL_INTERVAL - 2.00
        elseif task.name == "diseases" then task.acc = HEAVY_POLL_INTERVAL - 4.00
        elseif task.name == "spellEffects" then task.acc = HEAVY_POLL_INTERVAL - 6.00
        elseif task.name == "quests" then task.acc = QUEST_POLL_INTERVAL - 8.00
        else task.acc = 0.00 end
    end
end

-- Settings "Enable All" cascade: poll group toggles and apply
-- to children. Runs in onFrame so it works during pause (when
-- the settings menu is open). Can't be done in subscribe
-- (OpenMW forbids modifying the same storage section from its handler).
local function pollSettingsCascade()
    for _, cascade in ipairs(mS.groupCascades) do
        local current = cascade.storage:get(cascade.toggleKey)
        if cascade.lastValue == nil then
            cascade.lastValue = current
        elseif current ~= cascade.lastValue then
            cascade.lastValue = current
            for _, childKey in ipairs(cascade.children) do
                cascade.storage:set(childKey, current)
            end
        end
    end

    -- Reset-to-zero toggles: when a reset button is clicked (value == true),
    -- zero all associated player storage keys and set to "done" for feedback.
    -- Clicking again when "done" resets to false (renderer handles this).
    if state.profileId then
        for _, rt in ipairs(mS.resetToggles) do
            if rt.storage:get(rt.toggle) == true then
                local section = profileSection
                for _, key in ipairs(rt.keys) do
                    -- String-serialized keys (ending in "Str") reset to ""
                    if key:sub(-3) == "Str" then
                        section:set(key, "")
                    else
                        section:set(key, 0)
                    end
                end
                -- Reload in-memory caches that may have been invalidated
                pcall(loadBooksSeenCache)
                pcall(loadArtifactsSeenCache)
                pcall(loadDiseasesSeenCache)
                pcall(loadCreatureKillsCache)
                pcall(loadSpellEffectsSeenCache)
                pcall(loadWeaponTallyCache)
                pcall(loadSpellTallyCache)
                pcall(loadPeopleMetCache)
                resetPersonalRecordBuffer()
                if rt.toggle == "resetStats" then
                    applyLuckModifier()
                end
                pcall(function() mSummaryUi.update(state, 999) end)
                rt.storage:set(rt.toggle, "done")
            end
        end
    end
end

-- ============================================================
-- LIFECYCLE
-- ============================================================

local function doInit()
    V.playSecondsBuffer = 0
    resetPersonalRecordBuffer()
    V.unlockPollAccumulator = 0
    initProfileId()
    resetPollTaskAccumulators()
    loadBooksSeenCache()
    loadArtifactsSeenCache()
    loadDiseasesSeenCache()
    loadCreatureKillsCache()
    loadSpellEffectsSeenCache()
    loadWeaponTallyCache()
    loadSpellTallyCache()
    loadPeopleMetCache()
    -- Reset spell poll state so the first poll seeds the seen set
    -- with all currently active effects (prevents re-counting on load)
    V.seenActiveSpellIds = {}
    V.spellPollInitialised = false
    -- Reset distance tracking to avoid false deltas after load/teleport
    V.lastPosition = nil
    V.distFootBuf = 0
    V.distLevBuf = 0
    V.distJumpBuf = 0
    V.distSwimBuf = 0
    V.distMountBufs = {}
    V.mountSamplePos = nil
    V.lastMountSampleTime = nil
    V.racerRidingActive = false
    V.fallStartZ = nil
    V.wasOnGroundForFall = true
    V.speedLastPos = nil
    V.speedLastTime = nil
    V.lastBountyFrame = nil
    registerSkillHandlers()
    registerCombatDamageHandler()
    V.handlersRegistered = true
    state.getTopCreatureKills = getTopCreatureKills
    state.getCreatureKillsByType = getCreatureKillsByType
    state.getTopWeapons = getTopWeapons
    state.getTopSpells = getTopSpells
    V.statsWindowRetryAccumulator = 0
    V.statsWindowReady = (mStatsUi.setStatsWindow(state) == true)
    mSummaryUi.init(state)
    mSummaryUi.setState(state)
    applyLuckModifier()
end

-- ============================================================
-- QUICKLOAD TRACKING via GameSession storage
-- Player storage is overwritten on every load, so we can't use
-- it to detect quickloads. Instead, we use a session-scoped
-- storage section (GameSession lifetime) that survives across
-- save loads within the same OpenMW session. We track whether
-- the player was actively in gameplay (onUpdate ran) before
-- the load — loads from the main menu don't count.
-- ============================================================
local sessionSection = storage.playerSection("SC_session")
sessionSection:setLifeTime(storage.LIFE_TIME.GameSession)

V.pendingQuickloadSync = false  -- sync session count to persistent storage

local function onInit()
    -- New game: clear gameplay flag and state
    sessionSection:set("wasInGameplay", false)
    V.pendingQuickloadSync = false
    state = {
        savedGameVersion = mDef.savedGameVersion,
        profileId        = nil,
    }
    profileSection = nil
    doInit()
    sessionSection:set("playthroughId", state.playthroughId)
end

local function onLoad(data)
    -- Only count as quickload if the player was actively playing
    -- (onUpdate had run at least once since the previous load).
    -- Loads from the main menu have wasInGameplay = false.
    local wasPlaying = sessionSection:get("wasInGameplay")
    if wasPlaying then
        V.pendingQuickloadSync = true
    end
    -- Reset the gameplay flag — it will be set true on first onUpdate
    sessionSection:set("wasInGameplay", false)

    state = {
        savedGameVersion = mDef.savedGameVersion,
        profileId        = nil,
    }
    profileSection = nil
    if data and data.playthroughId then
        state.playthroughId = data.playthroughId
    end
    doInit()
    sessionSection:set("playthroughId", state.playthroughId)
end

local function onSave()
    flushPlaySeconds()
    flushPersonalRecords()
    state.savedGameVersion = mDef.savedGameVersion
    local saveState = {}
    for k, v in pairs(state) do
        if type(v) ~= "function" then
            saveState[k] = v
        end
    end
    return saveState
end

local function onUpdate(deltaTime)
    if not state.profileId then return end
    if deltaTime == 0 then return end

    -- Stats Window Extender may finish exposing its interface after this
    -- player script initialises. Retry registration briefly in gameplay;
    -- setStatsWindow itself is idempotent.
    if not V.statsWindowReady and mStatsUi.canRetryStatsWindow and mStatsUi.canRetryStatsWindow() then
        V.statsWindowRetryAccumulator = (V.statsWindowRetryAccumulator or 0) + deltaTime
        if V.statsWindowRetryAccumulator >= 1.0 then
            V.statsWindowRetryAccumulator = 0
            V.statsWindowReady = (mStatsUi.setStatsWindow(state) == true)
        end
    end

    -- Mark that we're actively in gameplay (for quickload detection).
    -- This flag persists in the GameSession section across loads.
    if not sessionSection:get("wasInGameplay") then
        sessionSection:set("wasInGameplay", true)
    end

    -- Deferred quickload increment: storage is now loaded and stable
    if V.pendingQuickloadSync then
        V.pendingQuickloadSync = false
        increment("quickloadCount")
    end

    local activeSpells = T.Actor.activeSpells(self)

    -- Total damage tracking: poll HP every frame for any source of loss
    pollDamageTaken()

    -- Knockdown detection: poll every frame for canMove changes
    pollKnockdown()

    -- Recall + Intervention detection via activeSpells (both use same mechanism)
    pollTeleportSpells(activeSpells)

    -- Spell cast tracking: must run every frame to catch short-duration
    -- spells, scrolls, and enchanted weapon procs before they expire.
    pollSpellsCast(activeSpells)

    -- Enchanted item use tracking: detects touch/target enchanted items
    -- (Ring of Fireballs etc.) by watching charge decrease, since their
    -- effects land on the target and never appear in the player's activeSpells.
    pollEnchantedItemUse()

    -- Distance tracking: measure movement each frame and classify it
    pollDistance(activeSpells)

    -- Personal records: highest point, deepest dive, fall, speed
    pollPersonalRecords()

    -- Crime detection: watch for bounty increases each frame
    pollCrimes()

    -- Lock/open tracking: catches spell, scroll, key, and lockpick unlocks
    V.unlockPollAccumulator = V.unlockPollAccumulator + deltaTime
    if V.unlockPollAccumulator >= UNLOCK_POLL_INTERVAL then
        V.unlockPollAccumulator = V.unlockPollAccumulator - UNLOCK_POLL_INTERVAL
        pollUnlocks()
    end

    -- NPC travel detection: after dialogue closes, watch for a teleport.
    -- Travel services (silt strider, boat, guild guide) teleport the player
    -- >5000 units while staying same cell type (ext→ext or int→int).
    -- Door transitions flip cell type (int→ext or ext→int).
    if V.travelCheckActive then
        V.travelCheckTimeout = V.travelCheckTimeout - 1

        local cell = self.object.cell
        if cell and V.travelPosSnapshot then
            local nowExtOk, nowExterior = pcall(function() return cell.isExterior end)

            if nowExtOk then
                -- Cell type flipped? Door transition — cancel watch.
                if V.travelWasExterior ~= nil and nowExterior ~= V.travelWasExterior then
                    V.travelCheckActive  = false
                    V.travelPosSnapshot  = nil
                    V.travelCellSnapshot = nil
                    V.travelWasExterior  = nil
                    V.travelCheckTimeout = 0
                -- Same cell type — count either a large movement OR a same-type cell change.
                elseif V.travelWasExterior ~= nil and nowExterior == V.travelWasExterior then
                    local currentPos = self.object.position
                    local dx = currentPos.x - V.travelPosSnapshot.x
                    local dy = currentPos.y - V.travelPosSnapshot.y
                    local dz = currentPos.z - V.travelPosSnapshot.z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if dist > 5000 or (V.travelCellSnapshot ~= nil and cell ~= V.travelCellSnapshot) then
                        increment("travelCount")
                        V.travelCheckActive  = false
                        V.travelPosSnapshot  = nil
                        V.travelCellSnapshot = nil
                        V.travelWasExterior  = nil
                        V.travelCheckTimeout = 0
                    end
                end
            end
            -- If nowExtOk is false (cell transitioning), skip this frame
        end

        -- Timeout expired without triggering — cancel watch
        if V.travelCheckActive and V.travelCheckTimeout <= 0 then
            V.travelCheckActive  = false
            V.travelPosSnapshot  = nil
            V.travelWasExterior  = nil
        end
    end

    if state.profileId and deltaTime and deltaTime > 0 then
        V.playSecondsBuffer = V.playSecondsBuffer + deltaTime
    end

    pollPeakValues(deltaTime)
    if mSummaryUi then
        if type(mSummaryUi.update) == 'function' then
            mSummaryUi.update(state, deltaTime)
        elseif type(mSummaryUi.onUpdate) == 'function' then
            mSummaryUi.onUpdate(deltaTime)
        end
    end
end

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

local function onPlayerDeath()
    if not state.profileId then return end
    increment("deathCount")
    applyLuckModifier(true)
end

local function onRecentCombatHit()
    V.markRecentCombatHit()
end

local function onCombatSwing(data)
    if not state.profileId then return end
    increment("swingCount")
    if data.hit then
        increment("hitCount")
    end
end

-- Name patterns for creatures that are lore-undead but use the
-- Humanoid (type 2) skeleton in the engine. Matched against the
-- lowercase creature name. Covers vanilla MW, Tribunal, Bloodmoon,
-- Tamriel Rebuilt, and common mod undead.
local UNDEAD_NAME_PATTERNS = {
    "skeleton", "bonewalker", "bonelord", "bone lord",
    "draugr", "lich", "zombie", "wight",
    "revenant", "wraith", "corprus",
    "ash ghoul", "ash slave", "ash zombie",
    "ascended sleeper",
}

local function isUndeadByName(name)
    if not name then return false end
    local lower = name:lower()
    for _, pattern in ipairs(UNDEAD_NAME_PATTERNS) do
        if lower:find(pattern, 1, true) then return true end
    end
    return false
end

local function onKilledActor(data)
    if not state.profileId then return end
    increment("killCount")
    recordWeaponKill()
    if data.actorType == "npc" then
        increment("npcKillCount")
        -- Check NPC class for special kill counters
        if data.npcClass then
            local cls = data.npcClass:lower()
            if cls == "witch" then
                increment("witchesHunted")
            elseif cls == "necromancer" then
                increment("necromancersSlain")
            elseif cls == "warlock" then
                increment("warlocksSlain")
            end
        end
        -- Check NPC record ID against known Daedra worshippers
        if data.npcRecordId and WORSHIPPER_IDS[data.npcRecordId:lower()] then
            increment("worshippersSlain")
        end
    elseif data.actorType == "creature" then
        -- Classify the kill. The engine's Creature.TYPE is based on
        -- animation skeleton, not lore category, so many undead
        -- (skeletons, bonewalkers, bonelords, draugr) are typed as
        -- Humanoid (2). We override with name-based detection.
        local category
        if data.creatureType == 3 or isUndeadByName(data.creatureName) then
            category = "undead"
        elseif data.creatureType == 1 then
            category = "daedra"
        elseif data.creatureType == 2 then
            category = "humanoid"
        else
            category = "creature"
        end

        if category == "undead" then
            increment("undeadKillCount")
        elseif category == "daedra" then
            increment("daedraKillCount")
        elseif category == "humanoid" then
            increment("humanoidKillCount")
        else
            increment("creatureKillCount")
        end

        if data.creatureName then
            recordCreatureKill(data.creatureName, data.creatureType)
        end
    end

    -- Essential NPC/creature killed = "thread of prophecy severed"
    if data.isEssential then
        increment("worldsDoomed")
    end

    -- God killed / Regicide — check record ID against lookup tables
    if data.recordId then
        local rid = data.recordId:lower()
        if GOD_IDS[rid] then
            increment("godsKilled")
        end
        if REGICIDE_IDS[rid] then
            increment("regicides")
        end
    end
end

-- ============================================================
-- MOD INTEGRATION: BRUTE FORCE
-- When Brute Force successfully smashes a lock, it sends
-- GiveCurrWeaponXp to the player. We intercept this to count
-- brute-forced locks. We must also forward the event so
-- Brute Force's own handler still fires.
-- ============================================================

local function onBruteForceUnlock()
    if not state.profileId then return end
    increment("bruteForceCount")
end

-- ============================================================
-- MOD INTEGRATION: SUN'S DUSK — BATHS
-- Sun's Dusk sends SunsDusk_finishedBath to the player when
-- a bath is completed. Simple event handler.
-- ============================================================

local function onSunsDuskBath()
    if not state.profileId then return end
    increment("sdBathCount")
end

-- ============================================================
-- MOD INTEGRATION: SUN'S DUSK — COOKING
-- Sun's Dusk sends SunsDusk_addConsumable to the player when
-- a meal is cooked. The data[2] table has isCookedMeal = true.
-- ============================================================

local function onSunsDuskAddConsumable(data)
    if not state.profileId then return end
    -- data is { recordId, entryTable }
    if type(data) == "table" and data[2] and data[2].isCookedMeal then
        increment("sdCookCount")
    end
end

-- ============================================================
-- MOD INTEGRATION: SUN'S DUSK — MEALS & DRINKS
-- Uses the onConsume engine handler, which fires for every
-- item the player consumes (ingredients and potions).
-- We only count when Sun's Dusk is active (I.SunsDusk exists).
-- Meals: Ingredient items (raw food) + cooked meals (potions
--        created by Sun's Dusk cooking, which have a timestamp
--        in their item data from Sun's Dusk's save system).
-- Drinks: Potion-type items whose name matches known Morrowind
--         beverages (alcohol, water, tea, milk, juice, etc.).
--         Excludes player-brewed alchemy potions.
-- ============================================================

-- Known beverage name patterns (lower-cased substrings)
local DRINK_PATTERNS = {
    "mazte", "sujamma", "flin", "shein", "greef", "brandy",
    "wine", "mead", "beer", "ale ", "grog", "rum", "whiskey",
    "vodka", "liquor", "skooma", "musa", "sillapi", "yamuz",
    "bevonche", "kumiss", "cider", "lager", "stout", "sake",
    "tea", "milk", "juice", "water",
}

local function isDrinkByName(name)
    local lower = name:lower()
    for _, pattern in ipairs(DRINK_PATTERNS) do
        if lower:find(pattern, 1, true) then return true end
    end
    return false
end

local function onConsumeItem(item)
    if not state.profileId then return end

    if T.Potion.objectIsInstance(item) then
        local nameOk, recName = pcall(function() return T.Potion.record(item).name end)
        if nameOk and recName and recName:lower():find("skooma", 1, true) then
            increment("skoomaCount")
        end
    end

    -- INGREDIENTS EATEN: always count when any raw ingredient is consumed
    if T.Ingredient.objectIsInstance(item) then
        increment("ingredientsEaten")
        return
    end

    -- SUN'S DUSK INTEGRATION: only count meals/drinks when Sun's Dusk is active
    local ok, sd = pcall(function() return I.SunsDusk end)
    if not ok or not sd then return end

    -- MEALS: Cooked meals from Sun's Dusk are Potion-type items
    -- that have been registered with a timestamp in Sun's Dusk's
    -- save data. We detect them via getSaveData().registeredConsumables.
    if T.Potion.objectIsInstance(item) then
        local sdOk, sdData = pcall(function() return sd.getSaveData() end)
        if sdOk and sdData and sdData.registeredConsumables then
            local entry = sdData.registeredConsumables[item.recordId]
            if entry and entry.foodValue and entry.foodValue > 0 then
                increment("sdMealCount")
                -- Cooked meals are MEALS only, even if they have drinkValue
                return
            end
            if entry and entry.drinkValue and entry.drinkValue > 0 then
                increment("sdDrinkCount")
                return
            end
        end

        -- DRINKS: Fall back to name-based detection for vanilla
        -- beverages (alcohol, water, etc.) that are in the static
        -- database we can't access from outside Sun's Dusk.
        local nameOk, recName = pcall(function() return T.Potion.record(item).name end)
        if nameOk and recName and isDrinkByName(recName) then
            increment("sdDrinkCount")
        end
    end
end

-- ============================================================
-- MOD INTEGRATION: ERNBURGLARY — STOLEN ITEMS
-- Our global script (scripts/SC/burglary_global.lua) registers
-- with I.ErnBurglary.onStolenCallback and forwards item data
-- to the player via SC_StolenItems events.
-- ============================================================

local function onStolenItems(data)
    if not state.profileId then return end
    local count = data.count or 1
    local value = data.value or 0
    addTo("stolenItemCount", count)
    if value > 0 then
        addTo("stolenItemValue", value)
    end
end

-- ============================================================
-- MOD INTEGRATION: BLACK SOUL GEMS
-- BSG sends BSG_ShowMessage to the player when an NPC soul is
-- successfully trapped. We intercept this to count black souls.
-- ============================================================

local function onBSGShowMessage(msg)
    if not state.profileId then return end
    -- BSG sends the sSoultrapSuccess GMST string on successful trap
    increment("blackSoulsTrapped")
end

-- ============================================================
-- SNEAK ATTACK DETECTION
-- When the player lands a successful hit while sneaking, the
-- actor script sends SC_SuccessfulHit. We check if the player
-- is currently sneaking — if so, it's a sneak attack.
-- ============================================================

local function onSuccessfulHit(data)
    if not state.profileId then return end
    if self.controls.sneak then
        increment("sneakAttackCount")
    end
end

-- ============================================================
-- INSULT VOICE LINE TRACKING (requires OpenMW 0.51+)
-- Uses the DialogueResponse event (Feature #8966, merged Feb 2025)
-- to detect NPC "hello" voice barks containing insults.
-- On OpenMW 0.49/0.50 the event never fires, so this is inert.
--
-- Event data fields (from docs):
--   e.type     — dialogue type string (e.g. "voice")
--   e.recordId — dialogue record ID
--   e.infoId   — unique info record ID (the numeric CS identifier)
--   e.actor    — the NPC who spoke
-- ============================================================

-- Voice line info IDs categorized by insult type.
-- These are the numeric info record IDs from Morrowind.esm's
-- Voice dialogue entries, as listed in the Construction Set.
-- IDs are stored as strings for hash-set lookup against e.infoId.
local SWIT_VOICE_IDS = {
    ["530230356222187880"]  = true,  -- "Filthy s'wit!"
    ["4308193263001812896"] = true,  -- "Filthy s'wit!"
    ["188122352300623914"]  = true,  -- "Filthy S'wit!"
    ["2992730408848915825"] = true,  -- "Filthy S'wit!"
    ["8702158311262415515"] = true,  -- "This is the end of you, s'wit."
    ["1092418785295565404"] = true,  -- "This is the end of you, s'wit."
    -- SWIT mod
    ["1796410065417120692"]  = true, -- "Mages' Guild? As if any of you feckless s'wits..."
    ["11464251652094619756"] = true, -- "I'd call you a s'wit but even s'wits have their uses."
}

local FETCHER_VOICE_IDS = {
    ["2557395332266924542"] = true,  -- "Fetcher."
    ["558376492984428444"]  = true,  -- "Stupid fetcher!"
    ["1888220718252088814"] = true,  -- "Die, fetcher."
    ["14054180582060016307"] = true, -- "Die, fetcher."
    ["62652024743128147"]   = true,  -- "Fetcher!"
    ["1002343791074431478"] = true,  -- "Fetcher!"
    -- SWIT mod
    ["8902123672855924393"]  = true, -- "Mages' Guild... As if any of you fetchers..."
}

local NWAH_VOICE_IDS = {
    ["24610257047534695"]    = true, -- "What, n'wah?"
    ["2043642502037723323"]  = true, -- "What, n'wah?"
    ["28709294402365525299"] = true, -- "You n'wah!"
    ["1282210422208319210"]  = true, -- "You n'wah!"
    -- SWIT mod
    ["2934163501950915345"]  = true, -- "I don't like your N'wah name..."
    ["189161132415858866"]   = true, -- "Calling you an N'wah would be an insult to N'wahs."
}

local SCUM_VOICE_IDS = {
    ["315429440117462959"]  = true,  -- "Keep moving, scum."
    ["876442932119414429"]  = true,  -- "We're watching you. Scum."
    ["864124413152019289"]  = true,  -- "Keep moving, scum."
    -- SWIT mod
    ["21880151872667316362"]  = true, -- "Legion scum."
    ["9262158011217017172"]   = true, -- "Go and find an Imperial boot to lick, you Hlaalu scum."
    ["125595095894914130"]    = true, -- "Go and find an Imperial boot to lick, you Hlaalu scum."
    ["46171392134911587"]     = true, -- "Legion scum."
    ["2144571931974211411"]   = true, -- "Go find an Imperial boot to lick, you Hlaalu scum."
    ["1266511204886318851"]   = true, -- "Go find an Imperial boot to lick, you Hlaalu scum."
    ["15542262921780724795"]  = true, -- "I don't like you, scum..."
    ["158248193146929324"]    = true, -- "Don't think just because you're a Dunmer... outlander scum."
    ["327362062249429951"]    = true, -- "You befoul this land... outlander scum."
}

local function onDialogueResponse(e)
    if not state.profileId then return end

    -- Track unique NPCs met (any dialogue type, requires 0.51+)
    if e.actor and e.actor.recordId then
        local npcId = e.actor.recordId:lower()
        if not V.peopleMetCache[npcId] then
            V.peopleMetCache[npcId] = true
            -- Rebuild serialized string
            local parts = {}
            for id in pairs(V.peopleMetCache) do
                parts[#parts + 1] = id
            end
            set("peopleMetStr", table.concat(parts, "\n"))
            set("peopleMet", #parts)
        end
    end

    -- Only count voice-type dialogue for insult tracking
    if e.type ~= "voice" then return end
    local infoId = tostring(e.infoId or "")
    if SWIT_VOICE_IDS[infoId] then
        increment("switCount")
    elseif FETCHER_VOICE_IDS[infoId] then
        increment("fetcherCount")
    elseif NWAH_VOICE_IDS[infoId] then
        increment("nwahCount")
    elseif SCUM_VOICE_IDS[infoId] then
        increment("scumCount")
    end
end

-- ============================================================
-- MOD INTEGRATION: BULLSEYE — HEADSHOT TRACKING
-- Bullseye sends Bullseye_PlayHeadshotSFX to the player when
-- a ranged headshot lands (requires SFX volume > 0 in settings).
-- ============================================================

local function onBullseyeHeadshot()
    if not state.profileId then return end
    increment("headshotCount")
end

return {
    engineHandlers = {
        onInit    = onInit,
        onLoad    = onLoad,
        onSave    = onSave,
        onUpdate  = onUpdate,
        onConsume = onConsumeItem,
        onFrame   = pollSettingsCascade,  -- runs during pause (settings menu)
    },
    eventHandlers = {
        Died              = onPlayerDeath,
        UiModeChanged     = onUiModeChanged,
        ScribPetted       = onScribPetted,
        CombatSwing       = onCombatSwing,
        SC_RecentCombatHit = onRecentCombatHit,
        KilledActor       = onKilledActor,
        GiveCurrWeaponXp  = onBruteForceUnlock,
        SunsDusk_finishedBath = onSunsDuskBath,
        SunsDusk_addConsumable = onSunsDuskAddConsumable,
        SC_StolenItems    = onStolenItems,
        BSG_ShowMessage   = onBSGShowMessage,
        SC_SuccessfulHit  = onSuccessfulHit,
        openMarkMenu      = onLmmOpenMarkMenu,  -- LuaMultiMark recall hook
        DialogueResponse  = onDialogueResponse,  -- NPC insult voice lines (OpenMW 0.51+)
        Bullseye_PlayHeadshotSFX = onBullseyeHeadshot,  -- Bullseye headshot tracking
        RacerRidingActivated = function() V.racerRidingActive = true end,
        RacerRidingStart = function() V.racerRidingActive = true end,
    },
}
