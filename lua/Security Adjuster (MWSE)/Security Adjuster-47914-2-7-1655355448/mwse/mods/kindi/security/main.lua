--[[v2.7]]
--add option to enable and disable mod
--add option to configure tooltip refresh frequency
--add option to show trapped status by severity
--add option to show tooltip without needing to equip a security tool
--add option to show enchantment-like visual effect on trapped objects
--improve text justification
--fix displaying the wrong skill name of trap
local data = require("kindi.security.data")
local config
local UIExpansionInstalled = lfs.fileexists(tes3.installDirectory .. "\\data files\\mwse\\mods\\UI Expansion\\main.lua")
local QuickLootInterop = include("QuickLoot.interop")
local canKill = table.invert {14, 15, 16, 18, 23, 27, 86}
local nuisance = table.invert {46, 47, 48}
local unsafe = table.invert {17, 19, 20, 21, 22, 24, 25, 26, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 45, 87, 88, 89}
local trapSeverity = {"Safe", "Harmless", "Unsafe", "Painful", "Dangerous", "Deadly"}

local function inventorySize(ref)
    if ref.object.inventory then
        return #ref.object.inventory
    end
end

local function isContainerOrDoor(reference, type)
    if type then
        return reference.object.objectType == type
    else
    return (reference.object.objectType == tes3.objectType.container or
        reference.object.objectType == tes3.objectType.door)
    end
end

local function pickIsEquipped()
    return tes3.player.mobile.readiedWeapon and
        tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.lockpick
end

local function probeIsEquipped()
    return tes3.player.mobile.readiedWeapon and
        tes3.player.mobile.readiedWeapon.object.objectType == tes3.objectType.probe
end

local function getLocked(reference)
    return tes3.getLocked {reference = reference}
end

local function getTrap(reference)
    return tes3.getTrap {reference = reference}
end

local function getKey(reference)
    return reference.lockNode and reference.lockNode.key
end

local function getLockDifficulty(lvl)
    if lvl <= 20 then
        return "Novice"
    elseif lvl <= 40 then
        return "Apprentice"
    elseif lvl <= 60 then
        return "Adept"
    elseif lvl <= 80 then
        return "Expert"
    else
        return "Master"
    end
end

local function getTrapSeverity(reference)
    local trap = getTrap(reference)
    local severity = 1
    local mag = 0
    local minMag = 0
    local maxMag = 0
    if trap then
        for i = 1, #trap.effects do
            local trapEffect = trap.effects[i]
            if canKill[trapEffect.id] then
                local duration = trapEffect.duration ~= 0 and trapEffect.duration or 1
                local mag = (trapEffect.min + trapEffect.max) / 2 * duration + mag
                local minMag = trapEffect.min * duration + minMag
                local maxMag = trapEffect.max * duration + maxMag
                if minMag >= tes3.player.mobile.health.current then
                    severity = severity < 6 and 6 or severity
                elseif mag >= tes3.player.mobile.health.current then
                    severity = severity < 5 and 5 or severity
                elseif maxMag >= tes3.player.mobile.health.current then
                    severity = severity < 5 and 5 or severity
                else
                    severity = severity < 4 and 4 or severity
                end
            elseif unsafe[trapEffect.id] then
                severity = severity < 3 and 3 or severity
            elseif nuisance[trapEffect.id] then
                severity = severity < 2 and 2 or severity
            end
        end
    end
    return trapSeverity[severity]
end

local function getUnlockChance(reference)
    if not pickIsEquipped() then
        return "Equip a lockpick"
    end
    if tes3.getLockLevel {reference = reference} == 0 then
        return 0
    end
    local chance =
        math.max(
        0,
        ((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
            tes3.mobilePlayer.security.current) *
            tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick}).object.quality *
            (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                tes3.findGMST(tes3.gmst.fFatigueMult).value *
                    (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base)) +
            tes3.findGMST(tes3.gmst.fPickLockMult).value * tes3.getLockLevel {reference = reference}
    )
    return string.format("%.2f", chance)
end

local function getDisarmChance(reference)
    if not probeIsEquipped() then
        return "Equip a probe"
    end
    local chance =
        math.max(
        0,
        (((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
            tes3.mobilePlayer.security.current) +
            (tes3.findGMST(tes3.gmst.fTrapCostMult).value * tes3.getTrap {reference = reference}.magickaCost)) *
            tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe}).object.quality *
            (tes3.findGMST(tes3.gmst.fFatigueBase).value -
                tes3.findGMST(tes3.gmst.fFatigueMult).value *
                    (1 - tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base))
    )
    return string.format("%.2f", chance)
end

local function addTooltipInfo(e, chanceLabelPick, keyLabel, chanceLabelProbe, trapNameLabel, effectsDesc)
    local block = e.tooltip:createBlock {id = tes3ui.registerID("SA_mainBlock")}
    block.paddingTop = 1
    block.paddingBottom = 3
    block.flowDirection = "top_to_bottom"

    local noUIExpansionDivider = block:createDivider {id = tes3ui.registerID("SA_blockDividerNoUIExpansion")}

    local labelPick
    local labelProbe
    local labelkeyName
    local labelTrapName
    local div

    local firstBlock = block:createBlock {id = tes3ui.registerID("SA_firstBlock")}
    firstBlock.flowDirection = "top_to_bottom"
    firstBlock.widthProportional = 1

    if config.showUnlockChance and chanceLabelPick then
        labelPick =
            firstBlock:createLabel {
            id = tes3ui.registerID("SA_chanceLabelPick"),
            text = string.format("%s", chanceLabelPick)
        }
    end

    if config.showDisarmChance and chanceLabelProbe then
        labelProbe =
            firstBlock:createLabel {
            id = tes3ui.registerID("SA_chanceLabelProbe"),
            text = string.format("%s", chanceLabelProbe)
        }
    end

    if config.showKeyName then
        labelkeyName =
            firstBlock:createLabel {id = tes3ui.registerID("SA_keyLabel"), text = string.format("%s", keyLabel)}
    else
        keyLabel = nil
    end

    if config.showTrapName and trapNameLabel then
        labelTrapName =
            firstBlock:createLabel {id = tes3ui.registerID("SA_trapLabel"), text = string.format("%s", trapNameLabel)}
    end

    local secondBlock = block:createBlock {id = tes3ui.registerID("SA_secondBlock")}
    secondBlock.flowDirection = "top_to_bottom"
    secondBlock.widthProportional = 1

    if effectsDesc and table.size(effectsDesc) > 0 then
        div = secondBlock:createDivider {id = tes3ui.registerID("SA_effectsDivider")}
        if config.trapEffectsDisplay == "Simple" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createLabel {
                    id = tes3ui.registerID("SA_effectsLabel" .. _),
                    text = effect.effectName .. effect.attributeOrSkillName
                }
            end
        elseif config.trapEffectsDisplay == "Verbose" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createLabel {
                    id = tes3ui.registerID("SA_effectsLabel" .. _),
                    text = effect.effectsLabel
                }
            end
        elseif config.trapEffectsDisplay == "VerboseIcon" then
            for _, effect in ipairs(effectsDesc) do
                secondBlock:createImage {id = tes3ui.registerID("SA_effectsIcon"), path = effect.effectIcon}
                secondBlock:createLabel {
                    id = tes3ui.registerID("SA_effectsLabel" .. _),
                    text = effect.effectsLabel
                }
            end
        else
            div:destroy()
        end
    end

    --fix not align center?
    for element in table.traverse(tes3ui.findHelpLayerMenu("HelpMenu").children) do
        if element.contentType ~= tes3.contentType.image then
            element.maxWidth = 1600
            element.width = 256
            element.autoWidth = true
            element.autoHeight = true
        end
    end

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

    local function destroyDiv()
        if div then
            div.visible = false
        end
    end

    if pickIsEquipped() then
        if labelTrapName then
            labelTrapName:destroy()
            labelTrapName = nil
        end
        if labelProbe then
            labelProbe:destroy()
            labelProbe = nil
        end
        if not config.showKeyName and not config.showUnlockChance then
            firstBlock:destroy()
            firstBlock = nil
        end
        secondBlock:destroy()
        secondBlock = nil
    end

    if probeIsEquipped() then
        if labelkeyName then
            labelkeyName:destroy()
            labelkeyName = nil
        end
        if labelPick then
            labelPick:destroy()
            labelPick = nil
        end
        if config.trapEffectsDisplay == "Hidden" then
            secondBlock:destroy()
            secondBlock = nil
        end
        if not config.showTrapName and not config.showDisarmChance then
            firstBlock:destroy()
            firstBlock = nil
            destroyDiv()
        end
    end

    if firstBlock and #firstBlock.children == 0 then
        firstBlock:destroy()
        firstBlock = nil
        destroyDiv()
    end

    if secondBlock and #secondBlock.children == 0 then
        secondBlock:destroy()
        secondBlock = nil
    end

    if not block:findChild("SA_firstBlock") and not block:findChild("SA_secondBlock") then
        block:destroy()
    end

    if UIExpansionInstalled then
        noUIExpansionDivider.visible = false
    end

    e.tooltip:updateLayout()
end

local function objectTooltip(e)
    if not e.reference then
        return
    end
    
    if not config.isModActive then
        return
    end
    
    local lockLabel = e.tooltip:findChild("HelpMenu_locked")
    local trapLabel = e.tooltip:findChild("HelpMenu_trapped")

    --createVisualEffect is better than applyEnchantEffect
    if isContainerOrDoor(e.reference) then
        if config.showTrapEnchantmentEffect ~= "No VFX" and getTrap(e.reference) then
            tes3.removeVisualEffect {reference = e.reference}
            tes3.createVisualEffect {reference = e.reference, magicEffectId = getTrap(e.reference).effects[1].id}
        else
            tes3.removeVisualEffect {reference = e.reference}
        end
    end
    
    --Hack for Quick Loot compatibility
    --This block of code will only run if Quick Loot is enabled
    if QuickLootInterop and mwse.loadConfig("QuickLoot") and not mwse.loadConfig("QuickLoot").modDisabled then
        if getLocked(e.reference) or getTrap(e.reference) then
            --Skip Quick Loot menu if this object is locked or trapped unless Quick Loot 'hide trapped' is enabled
            if mwse.loadConfig("QuickLoot").hideTooltip then 
                e.tooltip.maxWidth = 1600
                e.tooltip.maxHeight = 1600
            end
            if mwse.loadConfig("QuickLoot").hideLocked then
                e.tooltip.maxWidth = 0
                e.tooltip.maxHeight = 0
            end
            if mwse.loadConfig("QuickLoot").hideTrapped then
                QuickLootInterop.skipNextTarget = true
            else
                if getLocked(e.reference) or (inventorySize(e.reference) == 0 and not getTrap(e.reference)) then
                    QuickLootInterop.skipNextTarget = true
                end
            end
        else
            --Skip the rest of the code if this object is neither locked nor trapped with the following conditions
            if tes3ui.findMenu("QuickLoot:Menu") then
                tes3ui.findMenu("QuickLoot:Menu").visible = true
            end
            if mwse.loadConfig("QuickLoot").hideLocked then 
                e.tooltip.maxWidth = 1600
                e.tooltip.maxHeight = 1600
            end
            if mwse.loadConfig("QuickLoot").hideTooltip and isContainerOrDoor(e.reference, tes3.objectType.container) then 
                e.tooltip.maxWidth = 0
                e.tooltip.maxHeight = 0
            end
            return
        end
    end
    
    if not getLocked(e.reference) and not getTrap(e.reference) then
        return
    end
    
    if config.tooltipRefreshFrequency and not tes3.menuMode() then
        timer.start {
            duration = config.tooltipRefreshFrequency ~= 0 and config.tooltipRefreshFrequency or
                tes3.worldController.deltaTime,
            callback = function()
                tes3ui.refreshTooltip()
            end
        }
    end
    
    if lockLabel then
        if config.lockLevelDisplay == "Difficulty" then
            lockLabel.text =
                string.gsub(
                lockLabel.text,
                "%d+",
                function(str)
                    return getLockDifficulty(tonumber(str))
                end
            )
        elseif config.lockLevelDisplay == "Hidden" then
            lockLabel.visible = false
        elseif config.lockLevelDisplay == "Normal" then
            lockLabel.visible = true
        end
    end

    if trapLabel then
        if config.trapDisplay == "Severity" then
            trapLabel.text = string.format("%s Trap", getTrapSeverity(e.reference))
        elseif config.trapDisplay == "Hidden" then
            trapLabel.visible = false
        elseif config.trapDisplay == "Normal" then
            trapLabel.visible = true
        end
    end

    local chanceLabelPick
    local chanceLabelProbe
    local keyLabel
    local effectsDesc = {}
    local trapPoints = getTrap(e.reference) and getTrap(e.reference).magickaCost
    local trapNameLabel = getTrap(e.reference) and string.format("Trap: %s (%s)", getTrap(e.reference).name, trapPoints)

    if not getKey(e.reference) then
        keyLabel = string.format("Key: %s", "No key")
    else
        keyLabel = string.format("Key: %s", getKey(e.reference).name)
    end

    if getLocked(e.reference) then
        chanceLabelPick = string.format("Lockpick Chance: %s", getUnlockChance(e.reference))
    end

    if getTrap(e.reference) then
        local effectsLabel
        local trap = getTrap(e.reference)
        local effectName
        for i = 1, #trap.effects do
            local effect = trap.effects[i]
            if effect.id >= 0 then
                local attributeOrSkillName = tes3.attributeName[effect.attribute] or tes3.skillName[effect.skill]
                if attributeOrSkillName then
                    attributeOrSkillName = " " .. attributeOrSkillName:gsub("^%a", string.upper)
                else
                    attributeOrSkillName = ""
                end

                effectName = tes3.findGMST(1283 + effect.id).value

                effectsLabel =
                    string.format(
                    "%s%s %s to %s pts for %s secs in %s ft on %s",
                    effectName,
                    attributeOrSkillName,
                    effect.min,
                    effect.max,
                    effect.duration,
                    effect.radius,
                    tes3.findGMST(1442 + effect.rangeType).value
                )

                table.insert(
                    effectsDesc,
                    {
                        effectName = effectName,
                        effectsLabel = effectsLabel,
                        attributeOrSkillName = attributeOrSkillName,
                        effectIcon = "icons\\" .. effect.object.icon
                    }
                )
            end
        end
        chanceLabelProbe = string.format("Disarm Chance: %s", getDisarmChance(e.reference))
    end

    if config.toolsIsNeededToSee then
        if pickIsEquipped() or probeIsEquipped() then
            addTooltipInfo(e, chanceLabelPick, keyLabel, chanceLabelProbe, trapNameLabel, effectsDesc)
        end
        return
    else
        addTooltipInfo(e, chanceLabelPick, keyLabel, chanceLabelProbe, trapNameLabel, effectsDesc)
    end
end

local function activationTargetChanged(e)
    if not config.isModActive then
        return
    end
    if config.showTrapEnchantmentEffect ~= "Target" then
        return
    end
    if not e.previous then
        return
    end
    if not isContainerOrDoor(e.previous) then
        return
    end
    tes3.removeVisualEffect {reference = e.previous}
end

local function cellChanged(e)
    for ref in e.cell:iterateReferences() do
        if isContainerOrDoor(ref) and getTrap(ref) then
            tes3.removeVisualEffect {reference = ref}
            if config.showTrapEnchantmentEffect == "Always" then
                tes3.createVisualEffect {reference = ref, magicEffectId = getTrap(ref).effects[1].id}
            end
        end
    end
end

local function registers()
    event.register("uiObjectTooltip", objectTooltip)
    event.register("activationTargetChanged", activationTargetChanged)
    event.register("cellChanged", cellChanged)
    event.register("SA_KINDI_REFRESH_TRAPPED_VFX", cellChanged)
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
