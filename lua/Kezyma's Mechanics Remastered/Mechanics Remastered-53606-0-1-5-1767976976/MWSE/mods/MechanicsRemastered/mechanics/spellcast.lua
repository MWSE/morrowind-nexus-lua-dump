local config = require('MechanicsRemastered.config')
local K = require('MechanicsRemastered.mechanics.common')

-- Spellcasting Overhaul

local function costForMobileActor(spell, cost, caster)
    local calcChance = K.spellChanceForMobileActor(spell, caster)
    if (calcChance) then
        -- Adjust the cost of the spell by the modifier
        local costModifier = 100 / calcChance
        costModifier = K.limitToRange(costModifier, 1, 100)
        local newCost = cost * costModifier
        return math.floor(newCost+0.5)
    end
    return cost
end

--- @param e spellMagickaUseEventData
local function spellMagickaUseCallback(e)
    local success = e.spell.alwaysSucceeds
    -- If this spell would succeed anyway, do nothing.
    if (config.SpellcastEnabled == true and success == false) then
        local spell = e.spell
        local cost = e.cost
        local caster = e.caster.mobile

        -- Apply cost scaling if enabled
        if (config.SpellcastCostScaling == true) then
            local newCost = costForMobileActor(spell, cost, caster)
            e.cost = newCost
            cost = newCost
        end

        -- Apply speed scaling if enabled
        if (config.SpellcastSpeedScaling == true and cost <= e.caster.mobile.magicka.current) then
            local newSpeed = K.spellChanceForMobileActor(spell, caster) / 100
            newSpeed = K.limitToRange(newSpeed, 0.2, 1)
            e.caster.mobile.animationController.animationData.castSpeed = newSpeed
        else
            e.caster.mobile.animationController.animationData.castSpeed = 1
        end
    else
        e.caster.mobile.animationController.animationData.castSpeed = 1
    end
end

--- @param e spellCastEventData
local function spellCastCallback(e)
    if (config.SpellcastEnabled == true and config.SpellcastAlwaysCast == true) then
        if (e.castChance > 0) then
            e.castChance = 100
        end
    end
end

local function updateMagicMenu(e)
    if (config.SpellcastEnabled == true and config.SpellcastCostScaling == true) then
        local magicMenu = tes3ui.findMenu("MenuMagic")
        if (not magicMenu) then
            return
        end

        local spellNameList = magicMenu:findChild("MagicMenu_spell_names")
        local spellCostList = magicMenu:findChild("MagicMenu_spell_costs")
        local spellPercentList = magicMenu:findChild("MagicMenu_spell_percents")
        local player = tes3.mobilePlayer

        for ix, nameElement in ipairs(spellNameList.children) do
            local listSpell = nameElement:getPropertyObject("MagicMenu_Spell")
            local newCost = costForMobileActor(listSpell, listSpell.magickaCost, player)
            local roundedCost = tostring(newCost)
            spellCostList.children[ix].text = roundedCost .. ""
            spellPercentList.children[ix].text = "/" .. listSpell.magickaCost .. ""
        end
        magicMenu:findChild("MagicMenu_spell_cost_title").text = "Cost/Min"
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    e.element:registerAfter(tes3.uiEvent.preUpdate, updateMagicMenu)
end

--- @param e spellCastedEventData
local function spellCastedCallback(e)
    e.caster.mobile.animationController.animationData.castSpeed = 1
end

event.register(tes3.event.spellCasted, spellCastedCallback)
event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuMagic" })
event.register(tes3.event.spellCast, spellCastCallback)
event.register(tes3.event.spellMagickaUse, spellMagickaUseCallback)
mwse.log(config.Name .. ' Spellcasting Module Initialised.')