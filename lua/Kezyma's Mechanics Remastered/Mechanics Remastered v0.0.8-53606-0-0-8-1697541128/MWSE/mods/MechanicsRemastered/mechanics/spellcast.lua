local config = require('MechanicsRemastered.config')

-- Spellcasting Overhaul

local K = require('MechanicsRemastered.mechanics.common')

local function costForMobileActor(spell, cost, caster)
    local calcChance = K.spellChanceForMobileActor(spell, caster)
    if (calcChance) then
        -- Adjust the cost of the spell by the modifier
        local costModifier = 100 / calcChance
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
        local newCost = costForMobileActor(spell, cost, caster)
        e.cost = newCost
    end
end

--- @param e spellCastEventData
local function spellCastCallback(e)
    if (config.SpellcastEnabled == true) then
        if (e.castChance > 0) then
            e.castChance = 100
        end
    end
end

local function updateMagicMenu(e)
    if (config.SpellcastEnabled == true) then
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
            spellCostList.children[ix].text = ""
            spellPercentList.children[ix].text = roundedCost .. ""
        end
        magicMenu:findChild("MagicMenu_spell_cost_title").text = "Cost"
    end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    e.element:registerAfter(tes3.uiEvent.preUpdate, updateMagicMenu)
end

event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuMagic" })
event.register(tes3.event.spellCast, spellCastCallback)
event.register(tes3.event.spellMagickaUse, spellMagickaUseCallback)
mwse.log(config.Name .. ' Spellcasting Module Initialised.')