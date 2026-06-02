local self     = require('openmw.self')
local types    = require('openmw.types')
local core     = require('openmw.core')
local input    = require('openmw.input')
local async    = require('openmw.async')
local nearby   = require('openmw.nearby')
local ui       = require('openmw.ui')
local util     = require('openmw.util')
local I        = require('openmw.interfaces')
local ambient  = require('openmw.ambient')
local storage  = require('openmw.storage')

local shared   = require('scripts.bastard_shared')

local v2  = util.vector2
local rgb = util.color.rgb

local settingsGen      = storage.playerSection('SettingsBastardGeneral')
local settingsFormulas = storage.playerSection('SettingsBastardFormulas')
local settingsLoot     = storage.playerSection('SettingsBastardLoot')

-- ======================================================================================================
-- logging

local function log(...)
    if settingsGen:get('LOG') then
        print('[Bastard][player]', ...)
    end
end

-- ======================================================================================================
-- colours

local function getColorFromGameSettings(tag)
    local result = core.getGMST(tag)
    if not result then return rgb(1, 1, 1) end
    local parts = {}
    for c in string.gmatch(result, '(%d+)') do
        table.insert(parts, tonumber(c))
    end
    if #parts ~= 3 then return rgb(1, 1, 1) end
    return rgb(parts[1] / 255, parts[2] / 255, parts[3] / 255)
end

local fontNormal  = getColorFromGameSettings('FontColor_color_normal')
local fontOver    = getColorFromGameSettings('FontColor_color_normal_over')
local fontPressed = getColorFromGameSettings('FontColor_color_normal_pressed')
local fontCount   = getColorFromGameSettings('FontColor_color_count')
local fontMagic   = getColorFromGameSettings('FontColor_color_magic')
local fontFatigue = getColorFromGameSettings('FontColor_color_fatigue')
local fontHealth  = getColorFromGameSettings('FontColor_color_health')

-- ======================================================================================================
-- declarations

local destroyUI
local openRobUI
local handleResponse
local handleUiModeChanged
local onKeyPress
local onMouseButtonPress

-- ======================================================================================================
-- states

local uiOpen        = false
local uiMain        = nil
local currentActor  = nil
local windowOwnsMode = false

-- ======================================================================================================
-- helpers

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function tableContains(list, val)
    for _, v in ipairs(list) do if v == val then return true end end
    return false
end

local function getClassBucket(npcRecord)
    local className = npcRecord.class and npcRecord.class:lower() or ''
    local bucket = shared.CLASS_BUCKETS[className]
    if bucket then return bucket end

    local stripped = className:gsub('%s+service$', '')
                              :gsub('%s+svc$', '')
                              :gsub('%s+merchant$', '')
    if stripped ~= className then
        bucket = shared.CLASS_BUCKETS[stripped]
        if bucket then return bucket end
    end

    local rid = (npcRecord.id or ''):lower()
    for _, pat in ipairs(shared.GUARD_PATTERNS) do
        if string.find(rid, pat, 1, true) then return 'guard' end
    end
    return 'commoner'
end

local function getFactionId(npcRecord)
    if npcRecord.primaryFaction and npcRecord.primaryFaction ~= '' then
        return npcRecord.primaryFaction:lower()
    end
    return 'none'
end

-- returns true if any other live, conscious, non-victim guard is within radius of the player
local function hasGuardWitness(victim, radius)
    if not radius or radius <= 0 then return false end
    local r2 = radius * radius
    local pp = self.position
    for _, actor in ipairs(nearby.actors) do
        if actor and actor:isValid()
           and actor ~= victim
           and types.NPC.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
        then
            local d = actor.position - pp
            if d:length2() <= r2 then
                local rec = types.NPC.record(actor)
                if rec and getClassBucket(rec) == 'guard' then
                    return true, actor
                end
            end
        end
    end
    return false
end

local function getFactionMods(factionId)
    return shared.FACTION_MODS[factionId] or shared.FACTION_MODS['none']
end

local function getRaceMod(record)
    local race = record.race and record.race:lower() or ''
    return (shared.RACE_MODS[race] or { intimidate = 0 }).intimidate
end

local function getTimeBand()
    local hour = (core.getGameTime() / 3600) % 24
    for _, band in ipairs(shared.TIME_BANDS) do
        if hour >= band[1] and hour < band[2] then
            return { label = band[3], fightMod = band[4], giveInMod = band[5] }
        end
    end
    return { label = 'Alert', fightMod = 0, giveInMod = 0 }
end

local function getEquippedWeaponSkillName(actor)
    local equipment = types.Actor.getEquipment(actor) or {}
    local SLOT = types.Actor.EQUIPMENT_SLOT
    local weaponObj = equipment[SLOT.CarriedRight]
    if not weaponObj or not weaponObj:isValid() then
        return 'handtohand'
    end
    if not types.Weapon.objectIsInstance(weaponObj) then
        return 'handtohand'
    end
    local rec = types.Weapon.record(weaponObj)
    if types.Weapon.TYPE then
        for name, idx in pairs(types.Weapon.TYPE) do
            if idx == rec.type then
                local skill = shared.WEAPON_SKILL_BY_TYPE[name]
                if skill then return skill end
            end
        end
    end
    return 'handtohand'
end

local function getArmorRating(actor)
    if types.Actor.getEquipment then
        local eq = types.Actor.getEquipment(actor) or {}
        local total = 0
        for _, obj in pairs(eq) do
            if obj and obj:isValid() and types.Armor.objectIsInstance(obj) then
                local rec = types.Armor.record(obj)
                total = total + (rec.baseArmor or 0)
            end
        end
        return total
    end
    return 0
end

local function safeSkill(actor, skillName)
    local s = types.NPC.stats.skills
    local fn = s and s[skillName]
    if fn then
        local stat = fn(actor)
        return math.min(100, stat.modified or stat.base or 0)
    end
    return 0
end

local function safeAttr(actor, attrName)
    local stat = types.Actor.stats.attributes[attrName](actor)
    return stat.modified or stat.base or 0
end

local function fatigueRatio(actor)
    local f = types.Actor.stats.dynamic.fatigue(actor)
    local b = f.base or 1
    if b <= 0 then return 0 end
    return clamp(f.current / b, 0, 1)
end

local function countNpcGold(actor)
    local inv = types.Actor.inventory(actor)
    if not inv then return 0 end
    local total = 0
    for _, item in ipairs(inv:getAll()) do
        if item:isValid() and shared.GOLD_IDS[item.recordId] then
            total = total + (item.count or 0)
        end
    end
    return total
end

-- ======================================================================================================
-- recommendation labels

local function labelFor(value, table)
    for _, entry in ipairs(table) do
        if value >= entry[1] then return entry[2] end
    end
    return table[#table][2]
end

local function confidenceLabel(diff)
    return labelFor(diff, shared.CONFIDENCE_LABELS)
end

-- ======================================================================================================
-- score

local function revealScore()
    local sc  = safeSkill(self, 'speechcraft')
    local per = safeAttr(self, 'personality')
    local int = safeAttr(self, 'intelligence')
    return (sc + per + int) / 3
end

-- ======================================================================================================
-- formulas

local function safeAlarm(actor)
    -- types.Actor.stats.ai.alarm(actor) returns an AIStat with base/modified.
    local ai = types.Actor.stats.ai
    if not ai or not ai.alarm then return 0 end
    local stat = ai.alarm(actor)
    if not stat then return 0 end
    local v = stat.modified or stat.base or 0
    return clamp(v, 0, 100)
end

local function computePercentages(actor)
    local record = types.NPC.record(actor)
    local bucket = getClassBucket(record)
    local base   = shared.CLASS_BASE[bucket]

    -- player stats
    local pStr  = safeAttr(self, 'strength')
    local pAgi  = safeAttr(self, 'agility')
    local pPer  = safeAttr(self, 'personality')
    local pInt  = safeAttr(self, 'intelligence')
    local pWil  = safeAttr(self, 'willpower')
    local pSpc  = safeSkill(self, 'speechcraft')
    local pWS   = getEquippedWeaponSkillName(self)
    local pWeaponSkill = safeSkill(self, pWS)
    local pArmor = getArmorRating(self)
    local pLevel = types.Actor.stats.level(self).current or 1
    local pRace  = types.NPC.record(self).race and types.NPC.record(self).race:lower() or ''
    local pIntimidate = (shared.RACE_MODS[pRace] or { intimidate = 0 }).intimidate

    -- NPC stats
    local nStr  = safeAttr(actor, 'strength')
    local nAgi  = safeAttr(actor, 'agility')
    local nPer  = safeAttr(actor, 'personality')
    local nInt  = safeAttr(actor, 'intelligence')
    local nWil  = safeAttr(actor, 'willpower')
    local nSpc  = safeSkill(actor, 'speechcraft')
    local nWS   = getEquippedWeaponSkillName(actor)
    local nWeaponSkill = safeSkill(actor, nWS)
    local nArmor = getArmorRating(actor)
    local nLevel = types.Actor.stats.level(actor).current or 1
    local nAlarm = safeAlarm(actor)

    -- modifiers
    local factionId  = getFactionId(record)
    local factionMod = getFactionMods(factionId)
    local time       = getTimeBand()

    local pFatigue = fatigueRatio(self)
    local fatigueDelta = pFatigue - 0.5

    local levelDiff = nLevel - pLevel

    local fatigueWeight  = settingsFormulas:get('FATIGUE_WEIGHT') or 25
    local levelWeight    = settingsFormulas:get('LEVEL_DIFF_WEIGHT') or 4
    local levelCap       = settingsFormulas:get('LEVEL_DIFF_CAP') or 30
    local combatDiv      = settingsFormulas:get('COMBAT_DIVISOR') or 4
    local socialDiv      = settingsFormulas:get('SOCIAL_DIVISOR') or 4

    -- ======================================================================================================
    -- FIGHT: how likely the NPC is to attack rather than comply
    -- higher when: NPC is the stronger combatant, high level, in an aggressive faction, daytime, and player looks weak/non-scary/tired
    local combatGap = ((nStr + nAgi + nWeaponSkill + nArmor) -
                       (pStr + pAgi + pWeaponSkill + pArmor)) / combatDiv

    local fightLevelMod = clamp(levelDiff * levelWeight, -levelCap, levelCap)

    -- more player's fatigue, less likely to fight
    local fightFatigueMod = -fatigueDelta * fatigueWeight

    local fight = base.fight
                + combatGap
                + factionMod.fight
                + fightLevelMod
                + time.fightMod
                + fightFatigueMod
                - (pIntimidate * 0.7)

    fight = clamp(fight, 0, 100)

    -- ======================================================================================================
    -- GIVE-IN: how likely the NPC is to surrender belongings
    -- higher when: player has high social stats / is intimidating, player is fresh, in a pliable faction, evening
    local socialGap = ((pPer + pInt + pWil + pSpc) -
                       (nPer + nInt + nWil + nSpc)) / socialDiv

    local giveInLevelMod = -clamp(levelDiff * levelWeight, -levelCap, levelCap)

    local giveInFatigueMod = fatigueDelta * fatigueWeight

    local giveIn = base.giveIn
                 + socialGap
                 + factionMod.giveIn
                 + giveInLevelMod
                 + time.giveInMod
                 + giveInFatigueMod
                 + pIntimidate

    giveIn = clamp(giveIn, 0, 100)

    return fight, giveIn, nAlarm, {
        bucket    = bucket,
        faction   = factionId,
        levelDiff = levelDiff,
        time      = time,
    }
end

-- =========================================================================
-- choose loot

local function pickLootItems(actor, bucket)
    local inv = types.Actor.inventory(actor)
    if not inv then return {} end
    local equipment = types.Actor.getEquipment(actor) or {}
    local equippedSet = {}
    for _, obj in pairs(equipment) do
        if obj and obj:isValid() then
            equippedSet[obj.id] = true
        end
    end

    local pool      = {}
    local equippedWeapon = nil
    local equippedShield = nil
    local SLOT = types.Actor.EQUIPMENT_SLOT
    if SLOT then
        if equipment[SLOT.CarriedRight] and types.Weapon.objectIsInstance(equipment[SLOT.CarriedRight]) then
            equippedWeapon = equipment[SLOT.CarriedRight]
        end
        if equipment[SLOT.CarriedLeft] and types.Armor.objectIsInstance(equipment[SLOT.CarriedLeft]) then
            equippedShield = equipment[SLOT.CarriedLeft]
        end
    end

    for _, item in ipairs(inv:getAll()) do
        if item:isValid() and not shared.GOLD_IDS[item.recordId] and not equippedSet[item.id] then
            -- skip equipped armour pieces and weapons
            local include = false
            if types.Miscellaneous.objectIsInstance(item)
               or types.Ingredient.objectIsInstance(item)
               or types.Potion.objectIsInstance(item)
               or types.Book.objectIsInstance(item)
               or types.Apparatus.objectIsInstance(item)
               or types.Lockpick.objectIsInstance(item)
               or types.Probe.objectIsInstance(item)
               or types.Repair.objectIsInstance(item)
               or types.Clothing.objectIsInstance(item) then
                include = true
            end
            if include then
                table.insert(pool, item)
            end
        end
    end

    -- shuffle
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local minN = settingsLoot:get('VALUABLES_MIN') or 0
    local maxN = settingsLoot:get('VALUABLES_MAX') or 3
    if maxN < minN then maxN = minN end
    local takeN = math.random(minN, maxN)
    takeN = math.min(takeN, #pool)

    local picked = {}
    for i = 1, takeN do
        table.insert(picked, pool[i])
    end

    -- weapon / shield surrender chance, gated by caste
    local gearChance = settingsLoot:get('DROP_GEAR_CHANCE') or 25
    if bucket == 'warrior' or bucket == 'noble' or bucket == 'mage' then
        gearChance = gearChance * 0.4
    end
    if equippedWeapon and math.random(0, 99) < gearChance then
        table.insert(picked, equippedWeapon)
    end
    if equippedShield and math.random(0, 99) < gearChance then
        table.insert(picked, equippedShield)
    end

    return picked
end


-- ======================================================================================================
-- UI helpers

local function paddedBox(layout, template)
    return {
        template = template,
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                content = ui.content { layout },
            },
        },
    }
end

local function textRow(text, color, size)
    return {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            multiline = true,
            text      = text,
            textSize  = size or 16,
            textColor = color or fontNormal,
        },
    }
end

local function spacerV()
    return {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = { multiline = true, text = '\n', textSize = 6 },
    }
end

local function progressBar(amt, maximum, barSize, barColor, labelOverride)
    local box = ui.create {
        template = I.MWUI.templates.box,
        content  = ui.content {},
    }
    local barFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size     = barSize,
            align    = ui.ALIGNMENT.Start,
            horizontal = false,
        },
        content = ui.content {},
    }
    box.layout.content:add(barFlex)

    local barX = barSize.x * (amt / math.max(1, maximum))
    barFlex.content:add({
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            tileH = false, tileV = false,
            relativePosition = v2(0, 0),
            size  = v2(barX, barSize.y),
            alpha = 1,
            color = barColor,
        },
    })

    local textFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size     = barSize,
            arrange  = ui.ALIGNMENT.Center,
            align    = ui.ALIGNMENT.Center,
            horizontal = false,
        },
        content = ui.content {},
    }
    box.layout.content:add(textFlex)
    local label = labelOverride or (math.floor(amt) .. '%')
    textFlex.content:add(textRow(label, fontCount))
    return box
end

local function textButton(label, size, sound, fn, args)
    local box = ui.create {
        type = ui.TYPE.Container,
        props = {},
        content = ui.content {},
    }
    local flex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            size     = size,
            align    = ui.ALIGNMENT.Center,
            horizontal = true,
        },
        content = ui.content {},
    }
    box.layout.content:add(flex)
    local button = {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            multiline = true,
            text      = tostring(label),
            relativePosition = v2(0.5, 1),
            textSize  = 16,
            textColor = fontNormal,
        },
    }
    flex.events = {
        focusGain = async:callback(function(data, elem)
            button.props.textColor = fontOver
        end),
        focusLoss = async:callback(function(data, elem)
            button.props.textColor = fontNormal
        end),
        mousePress = async:callback(function(data, elem)
            button.props.textColor = fontPressed
            if uiOpen then box:update() end
        end),
        mouseRelease = async:callback(function(data, elem)
            button.props.textColor = fontNormal
            if sound and sound ~= '' then
                ambient.playSound(sound, { volume = 0.9 })
            end
            fn(args)
            if uiOpen then box:update() end
        end),
    }
    flex.content:add(button)
    return box
end


-- ======================================================================================================
-- action handlers

local function showMessage(msg)
    ui.showMessage(msg)
end

local function actorName(actor)
    return types.NPC.record(actor).name or 'Someone'
end

-- Returns the message-flavor key for an actor (e.g. 'khajiit'), or nil for default.
local function raceMessageKey(actor)
    if not actor or not actor:isValid() then return nil end
    if not types.NPC.objectIsInstance(actor) then return nil end
    local rec = types.NPC.record(actor)
    if not rec then return nil end
    local race = (rec.race or ''):lower()
    return (shared.RACE_TO_MESSAGE_KEY or {})[race]
end

-- Pick a random line from a category, choosing a race-flavored variant if one exists
local function pickFlavoredLine(actor, baseTable, suffix)
    local key = raceMessageKey(actor)
    if key then
        local variantName = 'MESSAGES_' .. suffix .. '_' .. key:upper()
        local variant = shared[variantName]
        if variant and #variant > 0 then
            return variant[math.random(#variant)]
        end
    end
    return baseTable[math.random(#baseTable)]
end

local function actorFactionName(record)
    if record.primaryFaction and record.primaryFaction ~= '' then
        local f = core.factions.records[record.primaryFaction]
        if f and f.name then return f.name end
    end
    return 'None'
end

local function actorClassName(record)
    local c = record.class and types.NPC.classes.record(record.class)
    return (c and c.name) or 'Commoner'
end

local function hasVoiceline(actor, category)
    if not actor or not actor:isValid() then return false end
    if not types.NPC.objectIsInstance(actor) then return false end
    local rec = types.NPC.record(actor)
    if not rec then return false end
    local raceKey = (shared.RACE_TO_VOICE_KEY or {})[(rec.race or ''):lower()]
    if not raceKey then return false end
    local genderKey = rec.isMale and 'male' or 'female'
    local cat = shared.VOICELINES and shared.VOICELINES[category]
    if not cat then return false end
    local byRace = cat[raceKey]
    if not byRace then return false end
    local stems = byRace[genderKey]
    return stems ~= nil and #stems > 0
end

local function npcHasWeaponEquipped(actor)
    if not actor or not actor:isValid() then return false end
    local eq = types.Actor.getEquipment(actor) or {}
    local SLOT = types.Actor.EQUIPMENT_SLOT
    if not SLOT then return false end
    local w = eq[SLOT.CarriedRight]
    return w ~= nil and w:isValid() and types.Weapon.objectIsInstance(w)
end

local function itemDisplayName(item)
    if not item or not item:isValid() then return nil end
    local rec = item.type and item.type.record and item.type.record(item)
    if rec and rec.name and rec.name ~= '' then return rec.name end
    return item.recordId or 'Item'
end

local function buildLootSummary(picked, gold)
    -- group items by display name for a tidy listing
    local order = {}
    local counts = {}
    for _, item in ipairs(picked or {}) do
        local name = itemDisplayName(item)
        if name then
            local c = item.count or 1
            if counts[name] == nil then
                table.insert(order, name)
                counts[name] = c
            else
                counts[name] = counts[name] + c
            end
        end
    end

    local lines = {}
    for _, name in ipairs(order) do
        local c = counts[name]
        if c > 1 then
            table.insert(lines, ('%s x%d'):format(name, c))
        else
            table.insert(lines, name)
        end
    end
    if (gold or 0) > 0 then
        table.insert(lines, shared.MESSAGES_LOOT_GOLD:format(gold))
    end

    if #lines == 0 then return nil end

    local header = shared.MESSAGES_LOOT_SUMMARY[
        math.random(#shared.MESSAGES_LOOT_SUMMARY)]
    return header .. '\n' .. table.concat(lines, '\n')
end

local function commitRob(actor)
    if not actor or not actor:isValid() then
        log('commitRob: invalid actor; aborting')
        return
    end

    log('commitRob: target=', actor.recordId)

    -- ready weapon
    self.type.setStance(self, 1)

    local fight, giveIn, alarm, info = computePercentages(actor)

    local fightRoll  = math.random(0, 99)
    local fightHit   = fightRoll < fight
    log('  fight%=', math.floor(fight), 'roll=', fightRoll,
        'alarm=', math.floor(alarm), 'fightHit=', tostring(fightHit))

    local record = types.NPC.record(actor)
    local factionId = record.primaryFaction
    if factionId and factionId == '' then factionId = nil end

    if fightHit then
        -- failed attempt due to combat -> assault report
        showMessage(actorName(actor) .. ': "' ..
            pickFlavoredLine(actor, shared.MESSAGES_FIGHT, 'FIGHT') .. '"')

        core.sendGlobalEvent('Bastard_ReportCrime', {
            player      = self,
            victim      = actor,
            kind        = 'assault',
            arg         = 0,
            faction     = factionId,
            victimAware = true,
        })

        if info.bucket == 'guard' then
            log('  outcome=GUARD_PURSUE')
            core.sendGlobalEvent('Bastard_NPCPursue', { npc = actor, player = self })
        else
            log('  outcome=FIGHT; NPC starts combat')
            core.sendGlobalEvent('Bastard_NPCFight', { npc = actor, player = self })
        end
        return
    end

    -- fight passed, roll give-In
    local giveRoll = math.random(0, 99)
    local giveHit  = giveRoll < giveIn
    log('  giveIn%=', math.floor(giveIn), 'roll=', giveRoll, 'giveHit=', tostring(giveHit))

    if not giveHit then
        -- refused to hand anything over -> failed theft attempt
        log('  outcome=HOLD; reporting theft (failed attempt)')
        showMessage(actorName(actor) .. ': "' ..
            pickFlavoredLine(actor, shared.MESSAGES_HOLD, 'HOLD') .. '"')

        core.sendGlobalEvent('Bastard_ReportCrime', {
            player      = self,
            victim      = actor,
            kind        = 'theft',
            arg         = settingsFormulas:get('THEFT_BOUNTY_BONUS') or 25,
            faction     = factionId,
            victimAware = true,
        })
        return
    end

    -- give-in: pick loot, transfer, drop disposition, animate
    local picked = pickLootItems(actor, info.bucket)
    local goldOnNpc = countNpcGold(actor)
    log('  outcome=GIVE_IN; picked', #picked, 'item(s); gold=', goldOnNpc)

    -- no-loot path: NPC has nothing -> no animation, no crime, just message
    -- if they're armed, hint that the weapon is the only thing on them
    if #picked == 0 and goldOnNpc <= 0 then
        log('  NPC has no loot; aborting follow-through')
        if npcHasWeaponEquipped(actor) then
            showMessage(shared.MESSAGES_NO_LOOT_WEAPON_ONLY[
                math.random(#shared.MESSAGES_NO_LOOT_WEAPON_ONLY)])
        else
            showMessage(shared.MESSAGES_NO_LOOT[math.random(#shared.MESSAGES_NO_LOOT)])
        end
        return
    end

    core.sendGlobalEvent('Bastard_TransferLoot', {
        npc      = actor,
        player   = self,
        items    = picked,
        takeGold = true,
        replyEvent = 'Bastard_LootDone',
    })
    core.sendGlobalEvent('Bastard_DropDisposition', { player = self, npc = actor })
    core.sendGlobalEvent('Bastard_NPCGiveIn', { npc = actor, player = self })

    -- successful give-in: only a crime if a different guard saw it
    local witnessRadius = settingsGen:get('GUARD_WITNESS_RADIUS') or 0
    local seen, witness = hasGuardWitness(actor, witnessRadius)
    if seen then
        log('  guard witness within', witnessRadius, ':', witness and witness.recordId or '?',
            '-> reporting theft')
        core.sendGlobalEvent('Bastard_ReportCrime', {
            player      = self,
            victim      = actor,
            kind        = 'theft',
            arg         = settingsFormulas:get('THEFT_BOUNTY_BONUS') or 25,
            faction     = factionId,
            victimAware = true,
        })
    end
    if settingsLoot:get('SHOW_LOOT_SUMMARY') then
        local summary = buildLootSummary(picked, goldOnNpc)
        if summary then
            showMessage(summary)
        end
    end

    local voiceEnabled = settingsGen:get('PLAY_VOICELINES')
    local hasMercy     = hasVoiceline(actor, 'Mercy')
    local hasDisarm    = hasVoiceline(actor, 'MercyDisarm')

    if voiceEnabled and (hasMercy or hasDisarm) then
        if hasMercy then
            core.sendGlobalEvent('Bastard_NPCSay', { npc = actor, category = 'Mercy' })
        end
        if hasDisarm then
            async:newUnsavableSimulationTimer(1.5, function()
                core.sendGlobalEvent('Bastard_NPCSay', { npc = actor, category = 'MercyDisarm' })
            end)
        end
        log('  give-in voicelines played')
    else
        showMessage(actorName(actor) .. ': "' ..
            pickFlavoredLine(actor, shared.MESSAGES_GIVE_IN, 'GIVE_IN') .. '"')
        log('  give-in message shown')
    end
end

local function onLootDone(data)
    log('onLootDone: lootValue=', data and data.value or 0)
end

-- ======================================================================================================
-- UI build

local function fmtRecommend(val, reveal, table)
    if reveal >= shared.REVEAL_TIERS.recommendation then
        return labelFor(val, table)
    end
    return '???'
end

openRobUI = function(actor)
    if uiOpen then return end
    uiOpen = true
    currentActor = actor

    local record = types.NPC.record(actor)
    local reveal = revealScore()

    local fight, giveIn, alarm, info = computePercentages(actor)

    log('openRobUI', 'name=', record.name, 'class=', record.class,
        'bucket=', info.bucket, 'faction=', info.faction,
        'levelDiff=', info.levelDiff, 'time=', info.time.label,
        'reveal=', math.floor(reveal),
        'fight=', math.floor(fight), 'alarm=', math.floor(alarm),
        'giveIn=', math.floor(giveIn))

    -- info reveal
    local nameStr   = record.name or '???'
    local casteStr  = (reveal >= shared.REVEAL_TIERS.caste) and
                      (info.bucket:gsub('^%l', string.upper)) or '???'
    local classStr  = (reveal >= shared.REVEAL_TIERS.class) and
                      actorClassName(record) or '???'
    local factionStr = (reveal >= shared.REVEAL_TIERS.faction) and
                       actorFactionName(record) or '???'
    local confStr   = (reveal >= shared.REVEAL_TIERS.mood) and
                      confidenceLabel(info.levelDiff) or '???'
    local timeStr   = (reveal >= shared.REVEAL_TIERS.vigor) and
                      info.time.label or '???'

    local fightLabel  = fmtRecommend(fight, reveal, shared.FIGHT_LABELS)
    local giveInLabel = fmtRecommend(giveIn, reveal, shared.GIVEIN_LABELS)
    local alarmLabel  = fmtRecommend(alarm, reveal, shared.ALARM_LABELS)
    local numericVisible = reveal >= shared.REVEAL_TIERS.numeric


    -- ======================================================================================================
    -- Layout

    local WIDTH      = 380
    local BAR_SIZE   = v2(WIDTH - 8, 18)

    uiMain = ui.create {
        template = I.MWUI.templates.boxSolidThick,
        layer = 'Modal',
        type = ui.TYPE.Container,
        props = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
        },
        content = ui.content {},
    }

    local pad = ui.create {
        template = I.MWUI.templates.padding,
        type = ui.TYPE.Container,
        props = {},
        content = ui.content {},
    }
    uiMain.layout.content:add(pad)

    local mainFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize   = true,
            arrange    = ui.ALIGNMENT.Center,
            align      = ui.ALIGNMENT.Center,
            horizontal = false,
        },
        content = ui.content {},
    }
    pad.layout.content:add(mainFlex)

    local simpleMode = settingsGen:get('SIMPLE_MODE')

    if not simpleMode then
        local infoFlex = {
            type = ui.TYPE.Flex,
            props = {
                autoSize   = false,
                size       = v2(WIDTH - 8, 108),
                arrange    = ui.ALIGNMENT.Center,
                align      = ui.ALIGNMENT.Center,
                horizontal = true,
            },
            content = ui.content {},
        }
        mainFlex.content:add(paddedBox(infoFlex, I.MWUI.templates.box))

        local labelsCol = {
            template = I.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                multiline = true,
                text      = 'Name:\nClass:\nCaste:\nFaction:\nMood:\nVigor:',
                relativePosition = v2(0.5, 1),
                textSize  = 16,
                textColor = fontNormal,
            },
        }
        infoFlex.content:add(labelsCol)

        local valuesCol = {
            template = I.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                multiline = true,
                text      = nameStr   .. '\n' ..
                            classStr  .. '\n' ..
                            casteStr  .. '\n' ..
                            factionStr.. '\n' ..
                            confStr   .. '\n' ..
                            timeStr,
                relativePosition = v2(0.5, 1),
                textSize  = 16,
                textColor = fontCount,
            },
        }
        infoFlex.content:add(valuesCol)

        mainFlex.content:add(spacerV())

        -- stats
        local function statRow(name, label, color, value)
            local headerText
            if reveal >= shared.REVEAL_TIERS.recommendation then
                headerText = name .. ':  ' .. label
            else
                headerText = name .. ':  ???'
            end
            mainFlex.content:add(textRow(headerText, color, 16))

            local barAmt = numericVisible and value or 0
            local barLabel = nil
            if not numericVisible then barLabel = '???' end
            mainFlex.content:add(progressBar(barAmt, 100, BAR_SIZE, color, barLabel))
        end

        statRow('Fight',   fightLabel,  fontHealth,  fight)
        mainFlex.content:add(spacerV())
        statRow('Alarm',   alarmLabel,  fontFatigue, alarm)
        mainFlex.content:add(spacerV())
        statRow('Give In', giveInLabel, fontMagic,   giveIn)
        mainFlex.content:add(spacerV())
    end

    -- buttons
    local bSize = v2(WIDTH - 24, 18)

    local function onTryRob()
        log('button: Try to Rob')
        local act = currentActor
        destroyUI()
        commitRob(act)
    end

    local function onBackOff()
        log('button: Back Off')
        destroyUI()
    end

    mainFlex.content:add(paddedBox(
        textButton('Try to Rob', bSize, 'menu click', onTryRob, nil),
        I.MWUI.templates.boxSolidThick))
    mainFlex.content:add(paddedBox(
        textButton('Back Off', bSize, 'menu click', onBackOff, nil),
        I.MWUI.templates.boxSolidThick))

    windowOwnsMode = true
    I.UI.setMode('Interface', { windows = {} })
    log('UI opened, world paused via Interface mode')
end

destroyUI = function()
    if not uiOpen then return end
    log('destroyUI')
    if uiMain then
        uiMain:destroy()
    end
    uiOpen = false
    uiMain = nil
    currentActor = nil
    if windowOwnsMode then
        windowOwnsMode = false
        I.UI.removeMode('Interface')
        log('Interface mode removed, world resumed')
    end
end

-- ======================================================================================================
-- dialogue intercept

handleResponse = function(data)
    if not settingsGen:get('MOD_ENABLED') then return end
    local actor = data.actor
    local id = core.dialogue[data.type].records[data.recordId].id

    if not (id == 'idle') and not (id == 'hello')
       and not string.find(id, 'greeting') and not uiOpen then
        if id == '- rob' then
            log('dialogue intercept: - rob on', (actor and actor.recordId) or '?')
            destroyUI()
            -- close dialogue mode before opening our window
            I.UI.removeMode('Dialogue')
            openRobUI(actor)
        end
    end
end

handleUiModeChanged = function(data)
    if data and data.oldMode == 'Interface' and data.newMode == nil
       and uiOpen and windowOwnsMode then
        log('Interface mode closed externally; destroying UI')
        destroyUI()
    end
end

onKeyPress = function(key)
    if key.code == input.KEY.Escape and uiOpen then
        log('Escape pressed; closing UI')
        destroyUI()
    end
end

onMouseButtonPress = function(key)
    if key == 3 and uiOpen then
        log('right-click; closing UI')
        destroyUI()
    end
end



return {
    engineHandlers = {
        onKeyPress         = onKeyPress,
        onMouseButtonPress = onMouseButtonPress,
    },
    eventHandlers = {
        DialogueResponse  = handleResponse,
        UiModeChanged     = handleUiModeChanged,
        Bastard_LootDone  = onLootDone,
    },
}