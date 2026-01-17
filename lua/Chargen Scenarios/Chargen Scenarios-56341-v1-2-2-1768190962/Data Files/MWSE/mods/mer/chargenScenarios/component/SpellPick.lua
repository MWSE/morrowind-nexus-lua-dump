local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("SpellPick")
local Validator = require("mer.chargenScenarios.util.validator")

---@class SpellEffectsTable
---@field id number @required tes3.effect.*
---@field attribute? `tes3effect.attribute` @optional tes3.attributes.*
---@field skill? `tes3.skill` @optional deafalt -1 (tes3.skill.*)
---@field rangeType? number @optional default tes3.effectRange.self
---@field min number @required default 0
---@field max number @required defualt 0
---@field radius? number @optional default 0
spellEffectSchema = {
    name = "SpellEffectSchema",
    fields = {
        id = { type = "number", required = true },
        attribute = { type = "number", required = false },
        skill = { type = "number", required = false },
        rangeType = { type = "number", required = false },
        min = { type = "number", required = true },
        max = { type = "number", required = true },
        radius = { type = "number", required = false },
    }
}

---@class ChargenScenariosSpellPickInput
---@field id? string @The id of the spell
---@field ids? table<number, string> @The ids of multiple spells. If this is used instead of 'id', one will be chosen at random. Don't use if making a custom spell.
---@field name? string @The name of the spell
---@field spellType? number @optoinal default tes3.spellType.spell.
---@field effects? table<number, SpellEffectsTable> @The effects of the spell

---@class ChargenScenariosSpellPick
---@field ids table<number, string> @the list of spell ids the spell pick is chosen from
---@field name string @The name of the spell
---@field spellType number @optoinal default tes3.spellType.spell.
---@field effects table<number, SpellEffectsTable> @The effects of the spell
local SpellPick = {
    schema = {
        name = "SpellPick",
        fields = {
            id = { type = "string", required = false },
            ids = { type = "table", childType = "string", required = false },
            name = { type = "string", required = false },
            spellType = { type = "number", required = false },
            effects = { type = "table", childType = spellEffectSchema, required = false },
        }
    }
}


--Constructor
---@param data ChargenScenariosSpellPickInput
---@return ChargenScenariosSpellPick|nil
function SpellPick:new(data)
    if not data then return nil end
    local spellPick = table.deepcopy(data)
    ---Validate
    Validator.validate(data, self.schema)
    assert(spellPick.id or spellPick.ids, "SpellPick must have either an id or ids")
    --Build
    if not spellPick.ids then
        spellPick.ids = { spellPick.id }
    end
    if spellPick.id then
        table.insert(spellPick.ids, spellPick.id)
        spellPick.id = nil
    end
    --go through ids and remove any where the object doesn't exist
    -- for i, id in ipairs(spellPick.ids) do
    --     if not tes3.getObject(id) then
    --         table.remove(spellPick.ids, i)
    --     end
    -- end
    if #spellPick.ids == 0 then
        return nil
    end
    ---Create SpellPick
    setmetatable(spellPick, self)
    self.__index = self
    return spellPick
end


---@return tes3spell|string|nil
function SpellPick:pick()
    local spell
    if self.name and self.effects then
        logger:debug("returning %s", self.ids[1])
        return self:createSpell()
    end
    if self.ids then
        for i=1, 1000 do
            local spellId = table.choice(self.ids)
            logger:debug("Picked spell id: %s", spellId)
            spell = tes3.getObject(spellId)
            if spell then return spell end
        end
    end
end

function SpellPick:createSpell()
    local spellId = self.ids[1]
    logger:debug("Creating Spell")
    if not ( spellId and self.effects) then return end
    logger:debug("Has id and effects")

    local spell = tes3.getObject(spellId)
    if not spell then
        logger:debug("Spell not found, creating with id: %s and name: %s", spellId, self.name)
        ---@diagnostic disable-next-line
        spell = tes3spell.create(self.id, self.name)
        logger:debug("Setting cast type to %s", self.spellType or tes3.spellType.spell)
        spell.castType = self.spellType or tes3.spellType.spell
        for i=1, #self.effects do

            local spellEffect = spell.effects[i]
            local effectData = self.effects[i]
            logger:debug("Effect: %s", effectData.id)

            logger:debug("spellEffect.id: %s", spellEffect.id)
            logger:debug("spellEffect.attribute: %s", spellEffect.attribute)
            logger:debug("spellEffect.skill: %s", spellEffect.skill)
            logger:debug("spellEffect.rangeType: %s", spellEffect.rangeType)
            logger:debug("spellEffect.min: %s", spellEffect.min)
            logger:debug("spellEffect.max: %s", spellEffect.max)
            logger:debug("spellEffect.radius: %s", spellEffect.radius)

            spellEffect.id = effectData.id
            spellEffect.attribute = effectData.attribute
            spellEffect.skill = effectData.skill
            spellEffect.rangeType = tes3.effectRange.self
            spellEffect.min = effectData.min or 0
            spellEffect.max = effectData.max or 0
            spellEffect.radius = effectData.radius

            return spell
        end
    else
        logger:debug("spell already exists!")
    end
end
return SpellPick