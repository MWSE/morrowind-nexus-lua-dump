--- A table that holds the spells added to the player that need to be removed later
local spellsAdded = {}

-- Holds the tes3npc
local enchanter = nil

local costMatrix = require("EnchantmentImproved.costMatrix")
local spellTable = require("EnchantmentImproved.spellTable")
local config = require("EnchantmentImproved.config")

local function hasEnchantableEffects(spell)

    for _, effect in pairs(spell.effects) do

        if effect.id ~= -1 then

            if effect.object.allowEnchanting == true then

                return true

            end

        end

    end

    return false

end

local function getHighestValues(effects)

    local highestCostMatrix = 0
    local highestMagnitude = 0
    local highestDuration = 0
    local highestArea = 0

    for _, effect in pairs(effects) do

        if effect.effect.id ~= -1 then
        
            if effect.magnitudeHigh > highestMagnitude then highestMagnitude = effect.magnitudeHigh end

            if effect.area > highestArea then highestArea = effect.area end

            if effect.duration > highestDuration then highestDuration = effect.duration end

            if spellTable[effect.effect.id] == -1 then

                return {
                    ["costMatrix"] = nil,
                    ["area"] = nil,
                    ["duration"] = nil,
                    ["magnitude"] = nil,
                    ["noCalc"] = true
                }
            
            elseif spellTable[effect.effect.id] > highestCostMatrix then

                highestCostMatrix = spellTable[effect.effect.id]

            end

        end       

    end

    return {
        ["costMatrix"] = highestCostMatrix,
        ["area"] = highestArea,
        ["duration"] = highestDuration,
        ["magnitude"] = highestMagnitude,
        ["noCalc"] = false
    }

end

local function clearSpells()

    for id, spell in pairs(spellsAdded) do

        tes3.removeSpell({
            reference = tes3.player,
            spell = spell,
            updateGUI = true
        })

    end

    spellsAdded = {}

end

local function hookClearSpells(e)

    if e.newlyCreated then

        local enchantID = tes3ui.registerID("MenuEnchantment")
        local buyButtonID = tes3ui.registerID("MenuEnchantment_Buybutton")
        local cancelButtonID = tes3ui.registerID("MenuEnchantment_Cancelbutton")
        local enchantMenu = tes3ui.findMenu(enchantID)
        local enchantBuy = enchantMenu:findChild(buyButtonID)
        local enchantCancel = enchantMenu:findChild(cancelButtonID)

        enchantBuy:registerAfter(tes3.uiEvent.mouseClick, clearSpells)
        enchantCancel:registerAfter(tes3.uiEvent.mouseClick, clearSpells)

    end

end

local function addSpellsOnActivator(e)

    if (e.activator ~= tes3.player) then return end
    if (e.target.object.objectType ~= tes3.objectType.npc) then return end

    if e.target.object:offersService(tes3.merchantService.enchanting) then

        mwse.log("EI: Got new Enchanter.")
        mwse.log("EI: Attempting to add spells.")
        enchanter = e.target.object

        for _, spell in pairs(e.target.object.spells) do

            if hasEnchantableEffects(spell) then

                local testSpell = tes3.hasSpell({
                    reference = tes3.player,
                    spell = spell
                })

                if not testSpell then

                    spellsAdded[spell.id] = spell
                    tes3.addSpell({
                        reference = tes3.player,
                        spell = spell,
                        updateGUI = false
                    })

                end

            end

        end

    end

end

local function priceEnchantment(e)

    if not config.priceEnchantments then return end

    local totalPrice, basePrice, highestMatrix
    local numberEffects = #e.effects
    local dispositionMod = ((enchanter.disposition * .1)/100)-0.05
    local mercantileMod = ((tes3.mobilePlayer.mercantile.current * .1)/100)

    highestMatrix = getHighestValues(e.effects)

    if highestMatrix.noCalc then return end

    local matrixMod = costMatrix[highestMatrix.costMatrix]

    basePrice = 1000 * matrixMod

    totalPrice = basePrice + ((25*numberEffects)*matrixMod) + (50*(math.max(1, highestMatrix.magnitude)*matrixMod)) + (15*(math.max(1, highestMatrix.area)*matrixMod)) + (50*(math.max(1, highestMatrix.duration)*matrixMod))

    e.price = totalPrice - ((totalPrice*dispositionMod) + (totalPrice*mercantileMod))

end

local function buildMCM(e)

    dofile("EnchantmentImproved.mcm")

end

event.register(tes3.event.initialized, buildMCM)
event.register(tes3.event.activate, addSpellsOnActivator)
event.register(tes3.event.uiActivated, hookClearSpells, {filter="MenuEnchantment"})
event.register(tes3.event.calcEnchantmentPrice, priceEnchantment)