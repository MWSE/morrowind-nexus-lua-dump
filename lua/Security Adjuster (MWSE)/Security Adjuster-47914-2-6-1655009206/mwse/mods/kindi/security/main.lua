--[[v2.6]]
local data = require("kindi.security.data")
local config
local UIExpansionInstalled = lfs.fileexists(tes3.installDirectory .. "\\data files\\mwse\\mods\\UI Expansion\\main.lua")
local QuickLootInterop = include("QuickLoot.interop")

local function pickIsEquipped()
    return tes3.player.mobile.readiedWeapon and
        tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.lockpick
end

local function probeIsEquipped()
    return tes3.player.mobile.readiedWeapon and
        tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.probe
end

local function getLocked(reference)
    return reference.lockNode.locked
end

local function getTrap(reference)
    return tes3.getTrap {reference = reference}
end

local function getKey(reference)
    return reference.lockNode.key
end

local function getUnlockChance(reference)
    if tes3.getLockLevel {reference = reference} == 0 then
        return 0
    else
        return math.max(
            0,
            ((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                tes3.mobilePlayer.security.current) *
                tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick}).object.quality *
                (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                    tes3.findGMST(tes3.gmst.fFatigueMult).value *
                        (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base)) +
                tes3.findGMST(tes3.gmst.fPickLockMult).value * tes3.getLockLevel {reference = reference}
        )
    end
end

local function getDisarmChance(reference)
    return math.max(
        0,
        (((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
            tes3.mobilePlayer.security.current) +
            (tes3.findGMST(tes3.gmst.fTrapCostMult).value * tes3.getTrap {reference = reference}.magickaCost)) *
            tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe}).object.quality *
            (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                tes3.findGMST(tes3.gmst.fFatigueMult).value *
                    (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base))
    )
end

local function addTooltipInfo(e, chanceLabel, keyOrTrapLabel, effectsDesc)
    local block = e.tooltip:createBlock {id = tes3ui.registerID("SA_mainBlock")}

    block.maxWidth = 1600
    block.autoWidth = true
    block.autoHeight = true
    block.paddingTop = 1
    block.paddingBottom = 3
    block.flowDirection = "top_to_bottom"

    if not UIExpansionInstalled then
        block:createDivider {id = tes3ui.registerID("SA_blockDividerNoUIExpansion")}
    end

    local label
    local div
    
    local firstBlock = block:createBlock {id = tes3ui.registerID("SA_firstBlock")}
    firstBlock.maxWidth = 256
    firstBlock.autoWidth = true
    firstBlock.autoHeight = true
    firstBlock.flowDirection = "top_to_bottom"
    firstBlock.widthProportional = 1
    if config.showUnlockChance and pickIsEquipped() then
        label = firstBlock:createLabel {id = tes3ui.registerID("SA_chanceLabel"), text = string.format("%s", chanceLabel)}
    elseif config.showDisarmChance and probeIsEquipped() then
        label = firstBlock:createLabel {id = tes3ui.registerID("SA_chanceLabel"), text = string.format("%s", chanceLabel)}
    end

    if config.showKeyName and pickIsEquipped() then
        label = firstBlock:createLabel {id = tes3ui.registerID("SA_keyLabel"), text = string.format("%s", keyOrTrapLabel)}
    elseif config.showTrapName and probeIsEquipped() then
        label = firstBlock:createLabel {id = tes3ui.registerID("SA_trapLabel"), text = string.format("%s", keyOrTrapLabel)}
    end

    local secondBlock = block:createBlock {id = tes3ui.registerID("SA_secondBlock")}
    secondBlock.maxWidth = 200
    secondBlock.autoWidth = true
    secondBlock.autoHeight = true
    secondBlock.flowDirection = "top_to_bottom"
    secondBlock.widthProportional = 1
    if probeIsEquipped() and effectsDesc and table.size(effectsDesc) > 0 then
        div = secondBlock:createDivider{id = tes3ui.registerID("SA_effectsDivider")}
        if config.trapEffectsDisplay == "Simple" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createLabel {
                id = tes3ui.registerID("SA_effectsLabel".._),
                text = effect.effectName..effect.attributeOrSkillName
            }                
            end
        elseif config.trapEffectsDisplay == "Verbose" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createLabel {
                id = tes3ui.registerID("SA_effectsLabel".._),
                text = effect.effectsLabel
            }                
            end
        elseif config.trapEffectsDisplay == "VerboseIcon" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createImage{id = tes3ui.registerID("SA_effectsIcon"), path = effect.effectIcon}
                secondBlock:createLabel {
                id = tes3ui.registerID("SA_effectsLabel".._),
                text = effect.effectsLabel
            }                
            end        
        else
            div:destroy()
        end
    end
    --fix not align center?
    for element in table.traverse(block.children) do
        if element.name ~= "SA_effectsDivider" and element.name ~= "SA_blockDividerNoUIExpansion" then
            element.wrapText = true
            element.justifyText = "center"
            element.borderTop = 2
            element.borderBottom = 2
            element.paddingLeft = 2
            element.paddingRight = 2
        end
    end

    if pickIsEquipped() and not config.showUnlockChance and not config.showKeyName then
        block:destroy()
    end

    local function destroyDiv()
        if div then
            div.visible = false
        end    
    end

    if probeIsEquipped() and not config.showDisarmChance and not config.showTrapName then
        destroyDiv()
        if config.trapDisplay == "Hidden" and config.trapEffectsDisplay == "Hidden" then
            block:destroy()
        elseif config.trapEffectsDisplay == "Hidden" then
            block:destroy()
        end
    end

    e.tooltip:updateLayout()
end

local function objectTooltip(e)
    if not e.reference then
        return
    end

    local lockLabel = e.tooltip:findChild("HelpMenu_locked")
    local trapLabel = e.tooltip:findChild("HelpMenu_trapped")

    if e.reference.lockNode and (e.reference.lockNode.locked or e.reference.lockNode.trap) then
        --[skip quickloot menu if this object is locked or trapped]
        if QuickLootInterop then
            QuickLootInterop.skipNextTarget = true
        end
    end

    --[hack for quickloot compatibility]
    if QuickLootInterop and mwse.loadConfig("QuickLoot") then
        if e.reference.object.inventory and #e.reference.object.inventory == 0 then
            if not (tes3.getLocked {reference = e.reference} or tes3.getTrap {reference = e.reference}) then
                if mwse.loadConfig("QuickLoot").modDisabled == false then
                    if tes3ui.findMenu("QuickLoot:Menu") then
                        tes3ui.findMenu("QuickLoot:Menu").visible = true
                    end
                end
            end
        end
    end

    if lockLabel then
        if config.lockLevelDisplay == "Difficulty" then
            lockLabel.text =
                string.gsub(
                lockLabel.text,
                "%d+",
                function(str)
                    local repl = tonumber(str)
                    if repl <= 20 then
                        return "Novice"
                    elseif repl <= 40 then
                        return "Apprentice"
                    elseif repl <= 60 then
                        return "Adept"
                    elseif repl <= 80 then
                        return "Expert"
                    else
                        return "Master"
                    end
                end
            )
        elseif config.lockLevelDisplay == "Hidden" then
            lockLabel.visible = false
        elseif config.lockLevelDisplay == "Normal" then
            lockLabel.visible = true
        end
    end

    if trapLabel then
        if config.trapDisplay == "Hidden" then
            trapLabel.visible = false
        elseif config.trapDisplay == "Normal" then
            trapLabel.visible = true
        end
    end

    if not e.reference.lockNode then
        return
    end

    timer.delayOneFrame(
        function()
            tes3ui.refreshTooltip()
        end
    )

    if not getLocked(e.reference) and not getTrap(e.reference) then
        return
    end

    if not pickIsEquipped() and not probeIsEquipped() then
        return
    end

    local chanceLabel
    local keyOrTrapLabel
    local trapPoints = getTrap(e.reference) and getTrap(e.reference).magickaCost

    if pickIsEquipped() and getLocked(e.reference) then
        if not getKey(e.reference) then
            keyOrTrapLabel = string.format("Key: %s", "No key")
        else
            keyOrTrapLabel = string.format("Key: %s", getKey(e.reference).name)
        end
        chanceLabel = string.format("Unlock Chance: %.2f", getUnlockChance(e.reference))
        addTooltipInfo(e, chanceLabel, keyOrTrapLabel)
    elseif probeIsEquipped() and getTrap(e.reference) then
        local effectsLabel
        local trap = getTrap(e.reference)
        local effectsDesc = {}
        local effectName
        for i = 1, #trap.effects do
            if trap.effects[i].id >= 0 then
                local attributeOrSkillName =
                    tes3.attributeName[trap.effects[i].attribute] or tes3.attributeName[trap.effects[i].skill]
                if attributeOrSkillName then
                    attributeOrSkillName = " " .. attributeOrSkillName:gsub("^%a", string.upper)
                else
                    attributeOrSkillName = ""
                end
                effectName = tes3.findGMST(1283 + trap.effects[i].id).value
                effectsLabel =
                    string.format(
                    "%s%s %s to %s pts for %s secs in %s ft on %s",
                    effectName,
                    attributeOrSkillName,
                    trap.effects[i].min,
                    trap.effects[i].max,
                    trap.effects[i].duration,
                    trap.effects[i].radius,
                    tes3.findGMST(1442 + trap.effects[i].rangeType).value
                )
                table.insert(effectsDesc, {effectName = effectName, effectsLabel = effectsLabel, attributeOrSkillName = attributeOrSkillName, effectIcon = "icons\\"..trap.effects[i].object.icon})
            end
        end

        local chanceLabel = string.format("Disarm Chance: %.2f", getDisarmChance(e.reference))
        local keyOrTrapLabel = string.format("Trap: %s (%s)", e.reference.lockNode.trap.name, trapPoints)
        addTooltipInfo(e, chanceLabel, keyOrTrapLabel, effectsDesc)
    end

    --enchantment effect on trapped objects. not good to use for now because we cannot remove the effect later!
    if false and config.showTrapEnchantmentEffect and getTrap(e.reference) then
        tes3.worldController:applyEnchantEffect(e.reference.sceneNode, getTrap(e.reference))
        e.reference.sceneNode:updateEffects()
    end
end

local function registers()
    event.register("uiObjectTooltip", objectTooltip)
    dofile("kindi.security.statRecord")

    --[[gmst resets to default every game session (i think), we restore it here]]
    tes3.findGMST(1081).value = tonumber(config.fpicklockmult)
    tes3.findGMST(1082).value = tonumber(config.ftrapcostmult)
end

event.register("initialized", registers)
event.register(
    "modConfigReady",
    function()
        require("kindi.security.mcm")
        config = require("kindi.security.config")
    end
)