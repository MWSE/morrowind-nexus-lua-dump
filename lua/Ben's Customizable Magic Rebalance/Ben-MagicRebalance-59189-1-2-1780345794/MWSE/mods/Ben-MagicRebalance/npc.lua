local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()

local loaded = false
local autoCalcSpells = {} -- school[effect[range[spells[]]]]

local function getHasOnlyWeakEffects(spell)

    for i = 1, 8 do
        local effect = spell.effects[i]
        if effect.id >= 0 and gameConfig.spell.weakEffectIds[effect.id] ~= true then return false end
    end

    return true

end

local function getMaxMagickaCosts(reference)

    local attributes = reference.object.attributes
    local willpower = attributes[tes3.attribute.willpower + 1]
    local luck = attributes[tes3.attribute.luck + 1]
    local skills = reference.object.skills

    local magicSchoolSkills = {
        [tes3.magicSchool.alteration] = skills[tes3.skill.alteration + 1],
        [tes3.magicSchool.conjuration] = skills[tes3.skill.conjuration + 1],
        [tes3.magicSchool.destruction] = skills[tes3.skill.destruction + 1],
        [tes3.magicSchool.illusion] = skills[tes3.skill.illusion + 1],
        [tes3.magicSchool.mysticism] = skills[tes3.skill.mysticism + 1],
        [tes3.magicSchool.restoration] = skills[tes3.skill.restoration + 1],
        [tes3.magicSchool.none] = 0,
    }

    local maxMagickaCosts = {}

    for magicSchool, skill in pairs(magicSchoolSkills) do

        local baseCastChance = skill * 2 + willpower / 5 + luck / 10
        baseCastChance = math.floor(util.round(baseCastChance, 0))

        -- NPCs will only be assigned spells they have at least an 80% chance to cast.
        -- This matches the behavior seen in the construction set.

        local maxMagickaCost = baseCastChance - 80
        maxMagickaCosts[magicSchool] = maxMagickaCost

    end

    return maxMagickaCosts

end

local function addNpcSpellPicks_ForMagicSchool(npcSpellPicks, magicSchool, maxMagickaCost)

    if maxMagickaCost <= 0 then return end

    local autoCalcSpells_EffectRangeSpells = autoCalcSpells[magicSchool] -- effect[range[spells[]]]
    local bestSpells_EffectRangeSpell = {} -- effect[range[spell]]

    for effectId, rangeSpells in pairs(autoCalcSpells_EffectRangeSpells) do
        for rangeType, spells in pairs(rangeSpells) do
            for _, spell in pairs(spells) do
                if spell.magickaCost <= maxMagickaCost then
                    -- store the best (AKA highest magicka cost) castable spell of each effect/range combo
                    bestSpells_EffectRangeSpell[effectId] = bestSpells_EffectRangeSpell[effectId] or {}
                    bestSpells_EffectRangeSpell[effectId][rangeType] = spell
                    break
                end
            end
        end
    end

    local validSpells = {} -- array of spells

    for effectId, rangeSpell in pairs(bestSpells_EffectRangeSpell) do
        for rangeType, spell in pairs(rangeSpell) do
            table.insert(validSpells, spell)
        end
    end

    local validSpellCount = util.count(validSpells)
    local remainingSpellPicks = util.clamp(gameConfig.spell.npcSpellPicksPerMagicSchool, nil, validSpellCount)

    -- if NPC has multiple conjuration spells, they will cast all of them before doing anything else
    if magicSchool == tes3.magicSchool.conjuration then remainingSpellPicks = util.clamp(remainingSpellPicks, nil, 1) end

    while remainingSpellPicks > 0 do

        local spellIndex = math.random(1, validSpellCount)
        local spell = validSpells[spellIndex]

        table.remove(validSpells, spellIndex)
        table.insert(npcSpellPicks, spell)

        validSpellCount = validSpellCount - 1
        remainingSpellPicks = remainingSpellPicks - 1

    end

end

local function sumStringBytes(value)

    local numbers = {string.byte(value, 1, 5)}
    local total = 0

    for _, number in pairs(numbers) do
        total = total + number
    end

    return total

end

local function getNpcSpellPicks(reference)

    local maxMagickaCosts = getMaxMagickaCosts(reference)
    local npcSpellPicks = {}

    -- spell picks should not change if save is reloaded
    math.randomseed(sumStringBytes(reference.baseObject.id))

    for magicSchool, maxMagickaCost in pairs(maxMagickaCosts) do
        addNpcSpellPicks_ForMagicSchool(npcSpellPicks, magicSchool, maxMagickaCost)
    end

    return npcSpellPicks

end

local function addNewAutoCalcSpells(reference)

    local npcSpellPicks = getNpcSpellPicks(reference)
    if next(npcSpellPicks) == nil then return end

    common.log("Adding New AutoCalc Spells | NPC ID: %s | Name: %s",
        reference.baseObject.id,
        reference.baseObject.name)

    for _, spell in pairs(npcSpellPicks) do

        if reference.object.spells:contains(spell) == false then
            common.log("Spell ID: %s | Name: %s | Cost: %s", spell.id, spell.name, spell.magickaCost)
            common.logEffects(spell)
            tes3.addSpell({reference = reference, spell = spell, updateGUI = false})
        end

    end

end

local function removeOldAutoCalcSpells(reference)

    local spellsToRemove = {}

    for _, spell in pairs(reference.object.spells) do
        if spell.isSpell and common.getHasModdedEffect(spell) == false then
            table.insert(spellsToRemove, spell)
        end
    end

    if next(spellsToRemove) == nil then return end

    common.log("Removing Old AutoCalc Spells | NPC ID: %s | Name: %s",
        reference.baseObject.id,
        reference.baseObject.name)

    for _, spell in pairs(spellsToRemove) do
        common.log("Spell ID: %s | Name: %s | Cost: %s", spell.id, spell.name, spell.magickaCost)
        common.logEffects(spell)
        tes3.removeSpell({reference = reference, spell = spell, updateGUI = false})
    end

end

local function addAutoCalcSpellsToNonMerchants(reference)

    if gameConfig.spell.addNpcSpells == false then return end
    if reference.object.aiConfig.offersSpells == true then return end
    if reference.baseObject.autoCalc == false then return end

    -- autoCalc NPCs get randomly assigned spells
    -- this spell assignment happens after magicEffectsResolved and before initialized
    -- it does not seem safe to update spells on magicEffectsResolved, so I'm doing it on loaded instead
    -- so I need to remove any original autoCalc spells and add in my new spells

    reference.data.Ben_MagicRebalance = reference.data.Ben_MagicRebalance or {}
    if reference.data.Ben_MagicRebalance.lastUpdated == gameConfig.lastUpdated then return end

    removeOldAutoCalcSpells(reference)
    addNewAutoCalcSpells(reference)

    reference.data.Ben_MagicRebalance.lastUpdated = gameConfig.lastUpdated

end

local function sortFunction_ByMagickaCostDesc(spellA, spellB)

    if spellA.magickaCost ~= spellB.magickaCost then return spellA.magickaCost > spellB.magickaCost end
    return spellA.id < spellB.id

end

local function cacheAutoCalcSpell(spell)

    if spell.IsSpell == false then return end
    if spell.autoCalc == false then return end
    if gameConfig.spell.npcOnlyUseBenAutoCalcSpells and string.find(spell.id, "^Ben_NPC_") == nil then return end
    if gameConfig.spell.removeWeakSpellsFromNonMerchants and getHasOnlyWeakEffects(spell) then return end

    local effect = spell.effects[1]
    local magicSchool = effect.object.school

    autoCalcSpells[magicSchool][effect.id] = autoCalcSpells[magicSchool][effect.id] or {}
    autoCalcSpells[magicSchool][effect.id][effect.rangeType] = autoCalcSpells[magicSchool][effect.id][effect.rangeType] or {}

    table.insert(autoCalcSpells[magicSchool][effect.id][effect.rangeType], spell)

end

local function cacheAutoCalcSpells()

    autoCalcSpells = {
        [tes3.magicSchool.alteration] = {},
        [tes3.magicSchool.conjuration] = {},
        [tes3.magicSchool.destruction] = {},
        [tes3.magicSchool.illusion] = {},
        [tes3.magicSchool.mysticism] = {},
        [tes3.magicSchool.restoration] = {},
        [tes3.magicSchool.none] = {},
    }

    for spell in common.sortedIterateObjects({ tes3.objectType.spell }) do
        cacheAutoCalcSpell(spell)
    end

    for _, effectRangeSpells in pairs(autoCalcSpells) do
        for _, rangeSpells in pairs(effectRangeSpells) do
            for _, spells in pairs(rangeSpells) do
                table.sort(spells, sortFunction_ByMagickaCostDesc)
            end
        end
    end

end

local function removeBirthsignSpellsFromMerchants(reference)

    if gameConfig.spell.removeBirthsignSpellsFromMerchants == false then return end
    if reference.object.aiConfig.offersSpells == false then return end

    local spellsToRemove = {}

    for _, spell in pairs(reference.object.spells) do

        if gameConfig.spell.birthsignSpellIds[spell.id] then
            table.insert(spellsToRemove, spell)
        end

    end

    if next(spellsToRemove) == nil then return end

    common.log("Removing Birthsign Spells | NPC ID: %s | Name: %s",
        reference.baseObject.id,
        reference.baseObject.name)

    for _, spell in pairs(spellsToRemove) do
        common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
        tes3.removeSpell({reference = reference, spell = spell, updateGUI = false})
    end

end

local function getHasForbiddenEffect(spell)

    for i = 1, 8 do
        local effect = spell.effects[i]
        if effect.id >= 0 and gameConfig.spell.forbiddenEffectIds[effect.id] then return true end
    end

    return false

end

local function removeForbiddenEffectsFromMerchants(reference)

    if gameConfig.spell.removeForbiddenEffectsFromMerchants == false then return end
    if reference.object.aiConfig.offersSpells == false then return end

    local spellsToRemove = {}

    for _, spell in pairs(reference.object.spells) do
        if spell.isSpell and getHasForbiddenEffect(spell) then
            table.insert(spellsToRemove, spell)
        end
    end

    if next(spellsToRemove) == nil then return end

    common.log("Removing Forbidden Effects | NPC ID: %s | Name: %s",
        reference.baseObject.id,
        reference.baseObject.name)

    for _, spell in pairs(spellsToRemove) do
        common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
        tes3.removeSpell({reference = reference, spell = spell, updateGUI = false})
    end

end

local function removeWeakSpellsFromNonMerchants(reference)

    if gameConfig.spell.removeWeakSpellsFromNonMerchants == false then return end
    if reference.object.aiConfig.offersSpells == true then return end

    local spellsToRemove = {}

    for _, spell in pairs(reference.object.spells) do
        if spell.isSpell and getHasOnlyWeakEffects(spell) then
            table.insert(spellsToRemove, spell)
        end
    end

    if next(spellsToRemove) == nil then return end

    common.log("Removing Weak Spells | NPC ID: %s | Name: %s",
        reference.baseObject.id,
        reference.baseObject.name)

    for _, spell in pairs(spellsToRemove) do
        common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
        tes3.removeSpell({reference = reference, spell = spell, updateGUI = false})
    end

end

local function addStartSpellsToArrille(reference)

    if gameConfig.spell.addStartSpellsToArrille == false then return end
    if reference.baseObject.id ~= "arrille" then return end

    local startingSpells = {}

    for spell in tes3.iterateObjects({ tes3.objectType.spell }) do

        if string.find(spell.id, "^Ben_Start_") ~= nil then
            table.insert(startingSpells, spell)
        end

    end

    if next(startingSpells) == nil then return end

    common.log("Adding Starting Spells To Arrille")

    for _, spell in util.sortedPairs(startingSpells, util.getSortFunction_ByValueNameThenKey(startingSpells)) do

        if reference.object.spells:contains(spell) == false then
            common.log("Spell ID: %s | Name: %s", spell.id, spell.name)
            tes3.addSpell({reference = reference, spell = spell, updateGUI = false})
        end

    end

end

local function onNpcLoaded(reference)

    if reference.object.aiConfig == nil then return end

    addStartSpellsToArrille(reference)
    addAutoCalcSpellsToNonMerchants(reference)
    removeWeakSpellsFromNonMerchants(reference)
    removeForbiddenEffectsFromMerchants(reference)
    removeBirthsignSpellsFromMerchants(reference)

    tes3.updateMagicGUI({reference = reference})

end

local function onCellLoaded(cell)

    for reference in cell:iterateReferences({ tes3.objectType.npc }) do
        onNpcLoaded(reference)
    end

end

local this = {}

this.onCellActivated = function(e)

    if not loaded then return end
    onCellLoaded(e.cell)

end

this.onLoaded = function(e)

    if not gameConfig.spell.rebalanceEnabled then return end

    loaded = true

    cacheAutoCalcSpells()

    common.log("--------------------------------------------------")
    common.log("Initial onCellLoaded Start")
    common.log("--------------------------------------------------")

    for _, cell in pairs(tes3.getActiveCells()) do
        onCellLoaded(cell)
    end

    common.log("--------------------------------------------------")
    common.log("Initial onCellLoaded End")
    common.log("--------------------------------------------------")

end

this.onLoad = function(e)

    loaded = false

end

return this
