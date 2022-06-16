local config = require("AccurateTooltipStats.config")
local modInfo = require("AccurateTooltipStats.modInfo")
local mod = string.format("[%s %s]", modInfo.mod, modInfo.version)

local weaponTooltipIds = {
    chop = tes3ui.registerID("HelpMenu_chop"),
    slash = tes3ui.registerID("HelpMenu_slash"),
    thrust = tes3ui.registerID("HelpMenu_thrust"),
}

local armorTooltipId = tes3ui.registerID("HelpMenu_armorRating")
local invMenuId = tes3ui.registerID("MenuInventory")
local invMenuArDisplay = tes3ui.registerID("MenuInventory_ArmorRating")

local function getArmorText(ar)
    if config.armorPrecision then
        return string.format("Armor Rating: %.1f", ar)
    else
        return string.format("Armor Rating: %.0f", ar)
    end
end

-- Bound to Balance doesn't take the bound armor's actual AR into account at all in its calculations, which is why this
-- has its own function called directly from changeArmorTooltip. We have to basically reproduce the mod's AR
-- calculations here for compatibility.
local function getBoundToBalanceAr(object)
    local id = object.id
    local skill

    local boundToBalanceConfig = mwse.loadConfig("Bound_to_Balance", {
        Govern = true,
        Mult = 10,
        Friend = false,
    })

    if boundToBalanceConfig.Govern then
        skill = tes3.mobilePlayer.conjuration.current
    else
        skill = tes3.mobilePlayer.willpower.current
    end

    local helmBase = 75
    local otherBase = 80
    local skillMult = ( config.armorSkill and (skill / 100) ) or 1

    if id == "bound_helm" then
        return math.ceil(helmBase * skillMult * (boundToBalanceConfig.Mult / 10))
    elseif string.sub(id, 1, 6) == "bound_"
    or string.sub(id, 1, 11) == "OJ_ME_Bound" then
        return math.ceil(otherBase * skillMult * (boundToBalanceConfig.Mult / 10))
    else
        return nil
    end
end

local function getArmorCondMult(object, itemData)
    if not config.armorCondition then
        return 1
    end

    local maxCondition = object.maxCondition
    local curCondition = ( itemData and itemData.condition ) or maxCondition
    return curCondition / maxCondition
end

local function getArmorSkillMult(object)
    if not config.armorSkill then
        return 1
    end

    -- The "perk" entries are solely in case the player is using 4NM.
    local skills = {
        [tes3.armorWeightClass.light] = {
            skill = tes3.skill.lightArmor,
            perk = "lig0",
        },
        [tes3.armorWeightClass.medium] = {
            skill = tes3.skill.mediumArmor,
            perk = "med0",
        },
        [tes3.armorWeightClass.heavy] = {
            skill = tes3.skill.heavyArmor,
            perk = "hev0",
        },
    }

    local weightClass = object.weightClass
    local skillUsed = skills[weightClass].skill
    local skillValue = tes3.mobilePlayer:getSkillValue(skillUsed)
    local baseArmorSkill = tes3.findGMST(tes3.gmst.iBaseArmorSkill).value

    -- These three mods all change how AR is calculated in very similar, but slightly different, ways.
    if tes3.isLuaModActive("Armor Rating")
    or tes3.isLuaModActive("ChimCombat")
    or tes3.isLuaModActive("4NM") then
        local armorSkillDivisor = 100
        local conjDivisor = 200

        if tes3.isLuaModActive("4NM") then
            if not tes3.player.data.perks then
                armorSkillDivisor = 200
                conjDivisor = 400
            else
                if not tes3.player.data.perks[skills[weightClass].perk] then
                    armorSkillDivisor = 200
                end

                if not tes3.player.data.perks.con9 then
                    conjDivisor = 400
                end
            end
        end

        local mult = 1 + ( skillValue / armorSkillDivisor )

        if object.weight == 0
        and (tes3.isLuaModActive("Armor Rating")
        or tes3.isLuaModActive("4NM")) then
            mult = mult * ( 0.5 + ( tes3.mobilePlayer.conjuration.current / conjDivisor ) )
        end

        return mult

    -- The vanilla game does not take armor skill into account at all when calculating AR for bound armor. Useful Bound
    -- Armor causes it to be treated like any other light armor.
    elseif object.weight == 0
    and not tes3.isLuaModActive("Useful Bound Armor") then
        return 1
    else
        return skillValue / baseArmorSkill
    end
end

local function getWeaponTexts(object, mins, maxs)
    local texts

    if config.weaponPrecision then
        -- Marksman weapons use only chop damage, and it displays as "Attack" in the tooltip, but for some reason the
        -- tooltip element for thrust damage is used.
        if object.skillId == tes3.skill.marksman then
            texts = {
                chop = "",
                slash = "",
                thrust = string.format("Attack: %.1f - %.1f", mins.chop, maxs.chop),
            }
        else
            texts = {
                chop = string.format("Chop: %.1f - %.1f", mins.chop, maxs.chop),
                slash = string.format("Slash: %.1f - %.1f", mins.slash, maxs.slash),
                thrust = string.format("Thrust: %.1f - %.1f", mins.thrust, maxs.thrust),
            }
        end
    else
        if object.skillId == tes3.skill.marksman then
            texts = {
                chop = "",
                slash = "",
                thrust = string.format("Attack: %.0f - %.0f", mins.chop, maxs.chop),
            }
        else
            texts = {
                chop = string.format("Chop: %.0f - %.0f", mins.chop, maxs.chop),
                slash = string.format("Slash: %.0f - %.0f", mins.slash, maxs.slash),
                thrust = string.format("Thrust: %.0f - %.0f", mins.thrust, maxs.thrust),
            }
        end
    end

    return texts
end

local function getWeaponCondMult(object, itemData)
    if not config.weaponCondition then
        return 1
    end

    -- Projectiles (thrown weapons, arrows, bolts) have no condition data.
    local hasCond = object.hasDurability
    local maxCondition = ( hasCond and object.maxCondition ) or 1
    local curCondition = ( hasCond and itemData and itemData.condition ) or maxCondition
    return curCondition / maxCondition
end

local function getWeaponStrMult()
    if not config.weaponStrength then
        return 1
    end

    local curStrength = tes3.mobilePlayer.strength.current
    local strBase, strMult

    -- This MCP feature causes the game to use these GMSTs in its weapon damage calculations instead of the hardcoded
    -- values used by the vanilla game. With default values for the GMSTs the outcome is the same.
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.gameFormulaRestoration) then
        strBase = tes3.findGMST(tes3.gmst.fDamageStrengthBase).value
        strMult = 0.1 * tes3.findGMST(tes3.gmst.fDamageStrengthMult).value
    else
        strBase = 0.5
        strMult = 0.01
    end

    return strBase + ( strMult * curStrength )
end

local function getWeaponBaseDamage(object)
    local mins = {
        chop = object.chopMin,
        slash = object.slashMin,
        thrust = object.thrustMin,
    }

    local maxs = {
        chop = object.chopMax,
        slash = object.slashMax,
        thrust = object.thrustMax,
    }

    -- The vanilla game doubles the official damage values for thrown weapons. The mod Thrown Projectiles Revamped
    -- halves the actual damage done, so don't double the displayed damage if that mod is in use.
    if object.type == tes3.weaponType.marksmanThrown
    and not tes3.isLuaModActive("DQ.ThroProjRev") then
        mins.chop = 2 * mins.chop
        maxs.chop = 2 * maxs.chop
    end

    return mins, maxs
end

local function changeArmorTooltip(tooltip, object, itemData)
    local ar = object.armorRating
    local arMultSkill = getArmorSkillMult(object)
    local arMultCond = getArmorCondMult(object, itemData)

    local boundToBalanceAr = nil

    -- This mod (Bound to Balance) does its AR calculations in a weird way, not taking the item's actual AR into
    -- account, so it has to be handled like this.
    if tes3.isLuaModActive("OEA.OEA6 Bound") then
        boundToBalanceAr = getBoundToBalanceAr(object)
    end

    ar = boundToBalanceAr or ( ar * arMultSkill )
    ar = ar * arMultCond

    local text = getArmorText(ar)
    local elem = tooltip:findChild(armorTooltipId)

    if elem then
        if elem.text ~= text then
            elem.text = text
        end
    end
end

local function changeWeaponTooltip(tooltip, object, itemData)
    local mins, maxs = getWeaponBaseDamage(object)
    local damageMultStr = getWeaponStrMult()
    local damageMultCond = getWeaponCondMult(object, itemData)

    for type, _ in pairs(weaponTooltipIds) do
        mins[type] = mins[type] * damageMultStr * damageMultCond
        maxs[type] = maxs[type] * damageMultStr * damageMultCond
    end

    local texts = getWeaponTexts(object, mins, maxs)

    for type, toolId in pairs(weaponTooltipIds) do
        local elem = tooltip:findChild(toolId)

        if elem then
            if elem.text ~= texts[type] then
                elem.text = texts[type]
            end
        end
    end
end

--[[ Every frame check to see if the game has reverted the inventory menu AR display back to an integer (which it does
whenever the inventory menu is updated), and if so, make it display the more precise value again. It's actually possible
to do this check only on an inventory menu update, but in that case I have to use nested timer.frame.delayOneFrame to
change the text three frames in a row (because for some reason the game resets the displayed value for multiple frames
afterward?) and that's just ugly. ]]--
local function onEnterFrame()
    if not config.menuArPrecision then
        return
    end

    if not tes3.mobilePlayer then
        return
    end

    local menu = tes3ui.findMenu(invMenuId)

    if not menu then
        return
    end

    local arElem = menu:findChild(invMenuArDisplay)

    if not arElem then
        return
    end

    local ar = tes3.mobilePlayer.armorRating
    local text = string.format("Armor: %.1f", ar)

    if arElem.text == text then
        return
    end

    arElem.text = text
end

local function onTooltip(e)
    local object = e.object
    local objectType = object.objectType

    local tooltip = e.tooltip
    local itemData = e.itemData

    if objectType == tes3.objectType.weapon
    or objectType == tes3.objectType.ammunition then
        changeWeaponTooltip(tooltip, object, itemData)
    elseif objectType == tes3.objectType.armor then
        changeArmorTooltip(tooltip, object, itemData)
    end
end

local function onInitialized()
    event.register(tes3.event.uiObjectTooltip, onTooltip)
    event.register(tes3.event.enterFrame, onEnterFrame)
    mwse.log("%s initialized.", mod)
end

event.register(tes3.event.initialized, onInitialized)

local function onModConfigReady()
    dofile("AccurateTooltipStats.mcm")
end

event.register(tes3.event.modConfigReady, onModConfigReady)