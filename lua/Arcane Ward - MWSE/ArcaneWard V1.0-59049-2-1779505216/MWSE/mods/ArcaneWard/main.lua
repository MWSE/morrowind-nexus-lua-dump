--[[
    ArcaneWard/main.lua

    Handles:
    - Arcane Ward damage reduction
    - Player stats menu display
    - Optional NPC / creature support
]]

local modName = "Arcane Ward"

local configModule = require("ArcaneWard.config")
local config = configModule.current

if config.debugMessages == nil then
    config.debugMessages = false
end

if config.minAlteration == nil then
    config.minAlteration = 20
end

if config.onlyCombatDamage == nil then
    config.onlyCombatDamage = false
end

if config.playProcSound == nil then
    config.playProcSound = true
end

if config.procSoundId == nil then
    config.procSoundId = "alteration hit"
end

if config.playProcVFX == nil then
    config.playProcVFX = true
end

if config.procVFXId == nil then
    config.procVFXId = "VFX_ShieldHit"
end

if config.procVFXDuration == nil then
    config.procVFXDuration = 0.35
end

if config.applyToPlayer == nil then
    config.applyToPlayer = true
end

if config.applyToNPCs == nil then
    config.applyToNPCs = false
end

if config.applyToCreatures == nil then
    config.applyToCreatures = false
end

require("ArcaneWard.mcm")

local UI_ID_ArcaneWardBlock = tes3ui.registerID("ArcaneWard:StatsBlock")
local UI_ID_ArcaneWardText = tes3ui.registerID("ArcaneWard:StatsText")

local armorSlotPenalties = {
    [tes3.armorSlot.helmet] = 0.10,
    [tes3.armorSlot.cuirass] = 0.30,
    [tes3.armorSlot.leftPauldron] = 0.10,
    [tes3.armorSlot.rightPauldron] = 0.10,
    [tes3.armorSlot.greaves] = 0.20,
    [tes3.armorSlot.boots] = 0.10,
    [tes3.armorSlot.leftGauntlet] = 0.05,
    [tes3.armorSlot.rightGauntlet] = 0.05,
    [tes3.armorSlot.shield] = 0.75,
    [tes3.armorSlot.leftBracer] = 0.05,
    [tes3.armorSlot.rightBracer] = 0.05,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function debugLog(message, ...)
    if not config.debug then
        return
    end

    mwse.log("[%s] " .. message, modName, ...)
end

local function debugMessage(message, ...)
    if not config.debugMessages then
        return
    end

    local text = "[Arcane Ward] " .. string.format(message, ...)
    text = text:gsub("%%", "%%%%")

    tes3.messageBox(text)
end

local function getObjectType(reference)
    if not reference or not reference.object then
        return nil
    end

    return reference.object.objectType
end

local function isPlayer(reference)
    return reference == tes3.player
end

local function isNPC(reference)
    return getObjectType(reference) == tes3.objectType.npc
end

local function isCreature(reference)
    return getObjectType(reference) == tes3.objectType.creature
end

local function getMobile(reference)
    if not reference then
        return nil
    end

    if reference == tes3.player then
        return tes3.mobilePlayer
    end

    return reference.mobile
end

local function getActorName(reference)
    if not reference or not reference.object then
        return "Unknown"
    end

    return reference.object.name or reference.object.id or "Unknown"
end

local function isWardAllowedForReference(reference)
    if not reference then
        return false, "No target"
    end

    if isPlayer(reference) then
        if config.applyToPlayer then
            return true, "Player"
        end

        return false, "Disabled for player"
    end

    if isNPC(reference) then
        if config.applyToNPCs then
            return true, "NPC"
        end

        return false, "Disabled for NPCs"
    end

    if isCreature(reference) then
        if config.applyToCreatures then
            return true, "Creature"
        end

        return false, "Disabled for creatures"
    end

    return false, "Invalid actor type"
end

local function getSkill(mobile, skill)
    if not mobile or not mobile.skills then
        return 0
    end

    local skillData = mobile.skills[skill + 1]

    if not skillData then
        return 0
    end

    return skillData.current or 0
end

local function getArmorPenalty(actor)
    local totalPenalty = 0
    local wornSlots = 0

    for slot, slotPenalty in pairs(armorSlotPenalties) do
        local stack = tes3.getEquippedItem({
            actor = actor,
            objectType = tes3.objectType.armor,
            slot = slot,
        })

        if stack and stack.object then
            totalPenalty = totalPenalty + slotPenalty
            wornSlots = wornSlots + 1

            debugLog(
                "Armor penalty: actor=%s slot=%s item=%s penalty=%.3f",
                getActorName(actor),
                tostring(slot),
                stack.object.id or "unknown",
                slotPenalty
            )
        end
    end

    return clamp(totalPenalty, 0.0, 1.0), wornSlots
end

local function isMagicDamage(e)
    return e.source == tes3.damageSource.magic
        or e.magicSourceInstance ~= nil
        or e.magicEffect ~= nil
        or e.magicEffectInstance ~= nil
        or e.activeMagicEffect ~= nil
end

local function isCombatDamage(e)
    return e.source == tes3.damageSource.attack
        or e.source == tes3.damageSource.shield
        or e.attacker ~= nil
        or e.attackerReference ~= nil
        or e.projectile ~= nil
end

local function getWardPower(actor)
    local armorPenalty, wornSlots = getArmorPenalty(actor)
    local wardPower = clamp(1.0 - armorPenalty, 0.0, 1.0)

    return wardPower, armorPenalty, wornSlots
end

local function getWardChance(unarmored, alteration, wardPower)
    local wardScore = (unarmored * 0.6) + (alteration * 0.4)

    local baseChance = (wardScore - 10) * 0.39
    baseChance = clamp(baseChance, 0, config.maxChance)

    return baseChance * wardPower
end

local function getWardAmount(unarmored, alteration, wardPower)
    local baseAmount = 5 + (unarmored * 0.15) + (alteration * 0.25)

    return math.floor((baseAmount * wardPower) + 0.5)
end

local function getCurrentWardStats(reference)
    reference = reference or tes3.player

    local mobile = getMobile(reference)

    if not mobile then
        return {
            active = false,
            reason = "No mobile actor found",
            unarmored = 0,
            alteration = 0,
            wardPower = 0,
            armorPenalty = 0,
            wornSlots = 0,
            chance = 0,
            amount = 0,
        }
    end

    local allowed, allowedReason = isWardAllowedForReference(reference)

    local unarmored = getSkill(mobile, tes3.skill.unarmored)
    local alteration = getSkill(mobile, tes3.skill.alteration)

    local wardPower, armorPenalty, wornSlots = getWardPower(reference)
    local chance = getWardChance(unarmored, alteration, wardPower)
    local amount = getWardAmount(unarmored, alteration, wardPower)

    local active = true
    local reason = "Active"
    local reasons = {}

    if not allowed then
        table.insert(reasons, allowedReason)
    end

    if unarmored < config.minUnarmored then
        table.insert(reasons, string.format("Needs Unarmored %d", config.minUnarmored))
    end

    if alteration < config.minAlteration then
        table.insert(reasons, string.format("Needs Alteration %d", config.minAlteration))
    end

    if wardPower <= 0 then
        table.insert(reasons, "Armor fully suppresses ward")
    end

    if #reasons == 0 and (chance <= 0 or amount <= 0) then
        table.insert(reasons, "Chance or absorb is 0")
    end

    if #reasons > 0 then
        active = false
        reason = table.concat(reasons, "; ")
    end

    return {
        active = active,
        reason = reason,
        category = allowedReason,
        unarmored = unarmored,
        alteration = alteration,
        wardPower = wardPower,
        armorPenalty = armorPenalty,
        wornSlots = wornSlots,
        chance = chance,
        amount = amount,
    }
end

local function playWardSound(reference)
    if not config.playProcSound then
        return
    end

    tes3.playSound({
        sound = config.procSoundId,
        reference = reference or tes3.player,
    })

    debugLog("Played proc sound: %s", config.procSoundId)
end

local function playWardVFX(reference)
    if not config.playProcVFX then
        return
    end

    local vfx = tes3.createVisualEffect({
        object = config.procVFXId,
        reference = reference or tes3.player,
    })

    if vfx then
        timer.start({
            duration = config.procVFXDuration,
            type = timer.real,
            callback = function()
                vfx.expired = true
            end,
        })
    end
end

local function onDamage(e)
    if not config.enabled then
        return
    end

    local target = e.reference

    if not target then
        return
    end

    local allowed = isWardAllowedForReference(target)

    if not allowed then
        return
    end

    if not e.damage or e.damage <= 0 then
        return
    end

    debugLog(
        "Damage hook fired. target=%s damage=%.2f source=%s",
        getActorName(target),
        e.damage,
        tostring(e.source)
    )

    if isMagicDamage(e) and not config.allowMagicDamage then
        debugLog("Skipped: magic damage. target=%s damage=%.2f", getActorName(target), e.damage)

        if isPlayer(target) then
            debugMessage("Arcane Ward: did not deflect %.0f damage. Magic damage ignored.", e.damage)
        end

        return
    end

    if config.onlyCombatDamage and not isCombatDamage(e) then
        debugLog("Skipped: not combat damage. target=%s damage=%.2f", getActorName(target), e.damage)

        if isPlayer(target) then
            debugMessage("Arcane Ward: did not deflect %.0f damage. Non-combat damage ignored.", e.damage)
        end

        return
    end

    local stats = getCurrentWardStats(target)

    debugLog(
        "Stats check. target=%s category=%s active=%s reason=%s U=%d A=%d power=%.2f penalty=%.2f slots=%d chance=%.2f absorb=%d",
        getActorName(target),
        tostring(stats.category),
        tostring(stats.active),
        stats.reason,
        stats.unarmored,
        stats.alteration,
        stats.wardPower,
        stats.armorPenalty,
        stats.wornSlots,
        stats.chance,
        stats.amount
    )

    local oldDamage = e.damage

    if not stats.active then
        if isPlayer(target) then
            debugMessage("Arcane Ward: did not deflect %.0f damage. %s.", oldDamage, stats.reason)
        end

        return
    end

    local roll = math.random() * 100

    if roll > stats.chance then
        debugLog("Ward failed. target=%s roll=%.2f chance=%.2f", getActorName(target), roll, stats.chance)

        if isPlayer(target) then
            debugMessage(
                "Arcane Ward: did not deflect %.0f damage. Roll %.0f vs Chance %.0f.",
                oldDamage,
                roll,
                stats.chance
            )
        end

        return
    end

    local absorbed = math.min(oldDamage, stats.amount)

    e.damage = math.max(0, oldDamage - stats.amount)

    playWardSound(target)
    playWardVFX(target)

    debugLog(
        "WARD PROC. target=%s roll=%.2f chance=%.2f absorbed=%.2f damage %.2f -> %.2f",
        getActorName(target),
        roll,
        stats.chance,
        absorbed,
        oldDamage,
        e.damage
    )

    if isPlayer(target) then
        debugMessage(
            "Arcane Ward: deflected %.0f damage. Took %.0f damage.",
            absorbed,
            e.damage
        )
    end
end

event.register(tes3.event.damage, onDamage)

local function getWardDisplayText()
    local stats = getCurrentWardStats(tes3.player)

    if not stats.active then
        return string.format(
            "Arcane Ward: inactive | %s | Power %.0f%% | Chance %.0f%% | Absorb %d",
            stats.reason,
            stats.wardPower * 100,
            stats.chance,
            stats.amount
        )
    end

    return string.format(
        "Arcane Ward: Power %.0f%% | Chance %.0f%% | Absorb %d",
        stats.wardPower * 100,
        stats.chance,
        stats.amount
    )
end

local function updateStatsMenu()
    local menu = tes3ui.findMenu("MenuStat")

    debugLog("menuEnter fired. Checking MenuStat.")

    if not menu then
        debugLog("MenuStat not found")
        return
    end

    debugLog("MenuStat found. Adding/updating Arcane Ward UI.")

    local existing = menu:findChild(UI_ID_ArcaneWardBlock)

    if existing then
        existing:destroy()
    end

    if not config.showInStatsMenu then
        debugLog("Show in Stats Menu is off. Removed Arcane Ward UI.")
        menu:updateLayout()
        return
    end

    local parent =
        menu:findChild(tes3ui.registerID("MenuStat_scrollPane")) or
        menu:findChild(tes3ui.registerID("MenuStat_pane")) or
        menu:findChild(tes3ui.registerID("MenuStat_stats")) or
        menu:findChild(tes3ui.registerID("MenuStat_skills")) or
        menu

    debugLog("Arcane Ward UI parent: %s", tostring(parent))

    local block = parent:createBlock({
        id = UI_ID_ArcaneWardBlock,
    })

    block.flowDirection = tes3.flowDirection.topToBottom
    block.autoHeight = true
    block.autoWidth = true
    block.paddingTop = 8
    block.paddingBottom = 4
    block.paddingLeft = 8
    block.paddingRight = 8

    local label = block:createLabel({
        id = UI_ID_ArcaneWardText,
        text = getWardDisplayText(),
    })

    label.wrapText = false
    label.color = tes3ui.getPalette(tes3.palette.normalColor)

    menu:updateLayout()

    debugLog("Stats menu updated: %s", label.text)
end

event.register(tes3.event.menuEnter, function()
    timer.delayOneFrame(updateStatsMenu)
end)

mwse.log("[%s] Initialized. Debug=%s", modName, tostring(config.debug))