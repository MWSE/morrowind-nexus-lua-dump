local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType
local random = require("scripts.morrowind_world_randomizer.utils.random")
local log = require("scripts.morrowind_world_randomizer.utils.log")

require("scripts.morrowind_world_randomizer.generator.spells")

local self = require('openmw.self')
local types = require('openmw.types')
local Actor = types.Actor
local core = require('openmw.core')

local this = {}
this.objectType = nil

---@class mwr.actor.statsParams
---@field health number
---@field fatigue number
---@field magicka number

---@class mwr.actor.attributesParams
---@field agility integer
---@field endurance integer
---@field intelligence integer
---@field luck integer
---@field personality integer
---@field speed integer
---@field strength integer
---@field willpower integer

local magicSchoolStr = {Alteration = "alteration", Conjuration = "conjuration", Destruction = "destruction", Illusion = "illusion", Mysticism = "mysticism", Restoration = "restoration"}

function this.randomizeInventory(data)
    if not data or not data.config then return end
    if data.config.item.randomize then
        local equipment = Actor.getEquipment(self)
        local slotById = {}
        for i, item in pairs(equipment) do
            slotById[item.id] = i
        end
        local items = {}
        for i, item in pairs(Actor.inventory(self):getAll()) do
            local advItemData = data.itemsData.items[item.recordId]
            if advItemData then
                table.insert(items, {item = item, advData = advItemData})
                local slot = slotById[item.id]
                if slot then
                    equipment[slot] = nil
                    items[#items].slot = slot
                end
            end
        end
        Actor.setEquipment(self, equipment)
        core.sendGlobalEvent("mwr_updateInventory", {items = items, object = self.object, objectType = this.objectType})
    end
end

function this.setEquipment(equipment)
    Actor.setEquipment(self, equipment)
end

---@param data mwr.actor.statsParams
function this.setDynamicBaseStats(data)
    if data.health then
        local var = Actor.stats.dynamic.health(self)
        local mul = math.min(var.current / var.base, 1)
        var.base = data.health
        var.current = data.health * mul
    end
    if data.magicka then
        local var = Actor.stats.dynamic.magicka(self)
        local mul = math.min(var.current / var.base, 1)
        var.base = data.magicka
        var.current = data.magicka * mul
    end
    if data.fatigue then
        local var = Actor.stats.dynamic.fatigue(self)
        local mul = math.min(var.current / var.base, 1)
        var.base = data.fatigue
        var.current = data.fatigue * mul
    end
end

---@param data mwr.actor.statsParams
function this.setDynamicStats(data)
    local calc = function(var, val)
        local diff = math.max(var.current - var.base, 0)
        local mul = var.base ~= 0 and math.min(var.current / var.base, 1) or 0
        return val * mul + diff
    end
    if data.health then
        local var = Actor.stats.dynamic.health(self)
        var.current = calc(var, data.health)
    end
    if data.magicka then
        local var = Actor.stats.dynamic.magicka(self)
        var.current = calc(var, data.magicka)
    end
    if data.fatigue then
        local var = Actor.stats.dynamic.fatigue(self)
        var.current = calc(var, data.fatigue)
    end
end

---@param data mwr.actor.attributesParams
function this.setAttributeBase(data)
    if data.agility then
        local var = Actor.stats.attributes.agility(self)
        var.base = data.agility
    end
    if data.endurance then
        local var = Actor.stats.attributes.endurance(self)
        var.base = data.endurance
    end
    if data.intelligence then
        local var = Actor.stats.attributes.intelligence(self)
        var.base = data.intelligence
    end
    if data.luck then
        local var = Actor.stats.attributes.luck(self)
        var.base = data.luck
    end
    if data.personality then
        local var = Actor.stats.attributes.personality(self)
        var.base = data.personality
    end
    if data.speed then
        local var = Actor.stats.attributes.speed(self)
        var.base = data.speed
    end
    if data.strength then
        local var = Actor.stats.attributes.strength(self)
        var.base = data.strength
    end
    if data.willpower then
        local var = Actor.stats.attributes.willpower(self)
        var.base = data.willpower
    end
end

function this.randomizeSkillBaseValues(data)
    local config = data.config
    ---@type mwr.localStorage.actorData
    local actorData = data.actorData
    local skillValues = actorData.skills
    local skills = types.NPC.stats.skills
    local skillConfig = config.stat.skills
    local getVal = function(val)
        if skillConfig.additive then
            return math.floor(math.max(0, math.min(skillConfig.limit, val + random.getBetween(skillConfig.vregion.min, skillConfig.vregion.max))))
        else
            return math.floor(math.max(0, math.min(skillConfig.limit, val * random.getBetween(skillConfig.vregion.min, skillConfig.vregion.max))))
        end
    end
    local skillsTable = {}
    table.insert(skillsTable, skills.block(self))
    table.insert(skillsTable, skills.armorer(self))
    table.insert(skillsTable, skills.mediumarmor(self))
    table.insert(skillsTable, skills.heavyarmor(self))
    table.insert(skillsTable, skills.bluntweapon(self))
    table.insert(skillsTable, skills.longblade(self))
    table.insert(skillsTable, skills.axe(self))
    table.insert(skillsTable, skills.spear(self))
    table.insert(skillsTable, skills.athletics(self))
    table.insert(skillsTable, skills.enchant(self))
    table.insert(skillsTable, skills.destruction(self))
    table.insert(skillsTable, skills.alteration(self))
    table.insert(skillsTable, skills.illusion(self))
    table.insert(skillsTable, skills.conjuration(self))
    table.insert(skillsTable, skills.mysticism(self))
    table.insert(skillsTable, skills.restoration(self))
    table.insert(skillsTable, skills.alchemy(self))
    table.insert(skillsTable, skills.unarmored(self))
    table.insert(skillsTable, skills.security(self))
    table.insert(skillsTable, skills.sneak(self))
    table.insert(skillsTable, skills.acrobatics(self))
    table.insert(skillsTable, skills.lightarmor(self))
    table.insert(skillsTable, skills.shortblade(self))
    table.insert(skillsTable, skills.marksman(self))
    table.insert(skillsTable, skills.mercantile(self))
    table.insert(skillsTable, skills.speechcraft(self))
    table.insert(skillsTable, skills.handtohand(self))

    for i, skill in ipairs(skillsTable) do
        skill.base = getVal(skillValues[i])
    end
end

---@param spellsData mwr.spellsData
local function chooseNewSpellId(spellsData, oldId, config, skipChecks)
    local id = oldId and oldId:lower()
    local advSpellData = id and spellsData.objects[id]
    if advSpellData or skipChecks then
        local group
        local pos
        if config.bySkill then
            local tb = {}
            local skills = types.NPC.stats.skills
            table.insert(tb, {magicSchoolStr.Alteration, skills.alteration(self)})
            table.insert(tb, {magicSchoolStr.Conjuration, skills.conjuration(self)})
            table.insert(tb, {magicSchoolStr.Destruction, skills.destruction(self)})
            table.insert(tb, {magicSchoolStr.Illusion, skills.illusion(self)})
            table.insert(tb, {magicSchoolStr.Mysticism, skills.mysticism(self)})
            table.insert(tb, {magicSchoolStr.Restoration, skills.restoration(self)})
            table.sort(tb, function(a, b) return a[2].modified > b[2].modified end)
            local school = tb[math.random(1, math.min(6, config.bySkillMax))][1]
            local level = Actor.stats.level(self).current
            group = spellsData.groups[core.magic.SPELL_TYPE.Spell][school]
            pos = math.min(1, level / config.levelReference) * #group
        elseif config.bySchool then
            local schoolPos, school = random.getRandomFromTable(advSpellData.schPoss)
            pos = schoolPos
            if school then
                group = spellsData.groups[core.magic.SPELL_TYPE.Spell][school]
            end
        else
            group = spellsData.groups[core.magic.SPELL_TYPE.Spell].all
            pos = advSpellData and advSpellData.pos or math.min(1, Actor.stats.level(self).current / config.levelReference) * #group
        end
        if group then
            local newSpellPos = random.getRandom(pos, #group, config.rregion.min, config.rregion.max)
            return group[newSpellPos]
        end
    end
    return nil
end

---@param actorData mwr.localStorage.actorData
local function restoreSpells(actorData)
    local spells = Actor.spells(self)
    local spellList = {}
    for _, spell in pairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spellList, spell)
        end
    end
    for _, spell in pairs(spellList) do
        spells:remove(spell)
    end
    for _, spellId in pairs(actorData.spells) do
        spells:add(spellId)
    end
end

function this.randmizeSpells(data)
    log("Actor spells", self)
    local spellConfig = data.config.spell
    ---@type mwr.spellsData
    local spellsData = data.spellsData
    local actorData = data.actorData
    restoreSpells(actorData)
    local spells = Actor.spells(self)
    local spellList = {}
    for _, spell in pairs(spells) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            table.insert(spellList, spell)
        end
    end
    local removeCount = spellConfig.remove.count
    while removeCount > 0 do
        if #spellList > 0 then
            local pos = math.random(1, #spellList)
            local spell = spellList[pos]
            log("removing", spell)
            spells:remove(spell)
            table.remove(spellList, pos)
            removeCount = removeCount - 1
        else
            break
        end
    end
    if spellConfig.randomize then
        for _, spell in pairs(spellList) do
            local id = spell.id:lower()
            local newSpellId = chooseNewSpellId(spellsData, id, spellConfig)
            if newSpellId then
                log("new spell", newSpellId)
                spells:add(newSpellId)
            end
        end
    end
    local addCount = spellConfig.add.count
    while addCount > 0 do
        local newSpellId = chooseNewSpellId(spellsData, nil, spellConfig.add, true)
        if newSpellId then
            log("new spell", newSpellId)
            spells:add(newSpellId)
            addCount = addCount - 1
        end
    end
end

return function(type)
    this.objectType = type
    return this
end
