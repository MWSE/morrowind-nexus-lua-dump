local common = require("mer.darkShard.common")
local logger = common.createLogger("SpellMaker")

---@class SpellMaker.params
---@field id string
---@field name string
---@field effects table
---@field castType tes3.spellType

local SpellMaker = {}

---@param params SpellMaker.params
---@return tes3spell
function SpellMaker.createSpell(params)
    logger:trace("Creating spell %s", params.id)
    local spell = tes3.getObject(params.id)
    spell = spell or tes3.createObject{
        id = params.id,
        objectType = tes3.objectType.spell,
        castType = params.castType
    }
    spell.name = params.name
    for i, effect in ipairs(params.effects) do
        local newEffect = spell.effects[i]
        newEffect.id = effect.id
        newEffect.rangeType = effect.rangeType
        newEffect.attribute = effect.attribute
        newEffect.min = effect.min
        newEffect.max = effect.max
    end
    return spell
end

return SpellMaker