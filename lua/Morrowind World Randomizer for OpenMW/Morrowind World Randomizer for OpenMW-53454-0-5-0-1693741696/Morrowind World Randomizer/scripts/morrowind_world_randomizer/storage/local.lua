local world = require('openmw.world')
local types = require('openmw.types')
local Actor = types.Actor

---@class mwr.localStorage
local this = {}

this.data = {lastRand = {}, cellLastRand = {}, creatureParent = {}, deletionList = {}, actorBase = {}, other = {lastItems = {}}, scale = {}}

function this.setRefRandomizationTimestamp(reference, timestamp)
    this.data.lastRand[reference.id] = timestamp or world.getGameTime()
end

---@return integer|nil
function this.getRefRandomizationTimestamp(reference)
    return this.data.lastRand[reference.id]
end

function this.clearRefRandomizationTimestamp(reference)
    this.data.lastRand[reference.id] = nil
end

function this.setCellRandomizationTimestamp(cellName)
    this.data.cellLastRand[cellName] = world.getGameTime()
end

---@return integer|nil
function this.getCellRandomizationTimestamp(cellName)
    return this.data.cellLastRand[cellName]
end

function this.removeObjectData(reference)
    this.data.lastRand[reference.id] = nil
end

function this.setCreatureParentIdData(crea, parent)
    this.data.creatureParent[crea.id] = parent.id
end

function this.clearCreatureParentIdData(crea)
    this.data.creatureParent[crea.id] = nil
end

function this.getCreatureParentData(crea)
    return this.data.creatureParent[crea.id]
end

function this.addIdToDeletionList(id)
    this.data.deletionList[id] = true
end

---@return boolean
function this.isIdInDeletionList(id)
    return this.data.deletionList[id]
end

function this.removeIdFromDeletionList(id)
    this.data.deletionList[id] = nil
end

function this.loadData(data)
    if not data then return end
    this.data = data
end

function this.getData()
    return this.data
end


---@return mwr.localStorage.actorData|nil
function this.saveActorData(actor, rewrite)
    if not actor or not actor.type then return end
    if this.data.actorBase[actor.recordId] and not rewrite then return this.data.actorBase[actor.recordId] end
    ---@class mwr.localStorage.actorData
    local data = {}
    data.health = Actor.stats.dynamic.health(actor).base
    data.magicka = Actor.stats.dynamic.magicka(actor).base
    data.fatigue = Actor.stats.dynamic.fatigue(actor).base
    if actor.type == types.NPC then
        data.attributes = {}
        data.attributes.agility = Actor.stats.attributes.agility(actor).base
        data.attributes.endurance = Actor.stats.attributes.endurance(actor).base
        data.attributes.intelligence = Actor.stats.attributes.intelligence(actor).base
        data.attributes.luck = Actor.stats.attributes.luck(actor).base
        data.attributes.personality = Actor.stats.attributes.personality(actor).base
        data.attributes.speed = Actor.stats.attributes.speed(actor).base
        data.attributes.strength = Actor.stats.attributes.strength(actor).base
        data.attributes.willpower = Actor.stats.attributes.willpower(actor).base

        local skills = types.NPC.stats.skills
        data.skills = {}
        table.insert(data.skills, skills.block(actor).base)
        table.insert(data.skills, skills.armorer(actor).base)
        table.insert(data.skills, skills.mediumarmor(actor).base)
        table.insert(data.skills, skills.heavyarmor(actor).base)
        table.insert(data.skills, skills.bluntweapon(actor).base)
        table.insert(data.skills, skills.longblade(actor).base)
        table.insert(data.skills, skills.axe(actor).base)
        table.insert(data.skills, skills.spear(actor).base)
        table.insert(data.skills, skills.athletics(actor).base)
        table.insert(data.skills, skills.enchant(actor).base)
        table.insert(data.skills, skills.destruction(actor).base)
        table.insert(data.skills, skills.alteration(actor).base)
        table.insert(data.skills, skills.illusion(actor).base)
        table.insert(data.skills, skills.conjuration(actor).base)
        table.insert(data.skills, skills.mysticism(actor).base)
        table.insert(data.skills, skills.restoration(actor).base)
        table.insert(data.skills, skills.alchemy(actor).base)
        table.insert(data.skills, skills.unarmored(actor).base)
        table.insert(data.skills, skills.security(actor).base)
        table.insert(data.skills, skills.sneak(actor).base)
        table.insert(data.skills, skills.acrobatics(actor).base)
        table.insert(data.skills, skills.lightarmor(actor).base)
        table.insert(data.skills, skills.shortblade(actor).base)
        table.insert(data.skills, skills.marksman(actor).base)
        table.insert(data.skills, skills.mercantile(actor).base)
        table.insert(data.skills, skills.speechcraft(actor).base)
        table.insert(data.skills, skills.handtohand(actor).base)
    end

    data.spells = {}

    for _, spell in pairs(Actor.spells(actor)) do
        table.insert(data.spells, spell.id:lower())
    end

    data.items = {}

    for _, item in pairs(Actor.inventory(actor):getAll()) do
        table.insert(data.items, {id = item.recordId, count = item.count})
    end

    this.data.actorBase[actor.recordId] = data
    return data
end

function this.getActorData(recordId)
    return this.data.actorBase[recordId]
end

return this