local log = mwse.Logger.new()

local config = require("HP_SA.config")


local util = {}
-- Joinking code from Merlord's Dark Shard - SpellMaker

---@class SpellMaker.params
---@field id string
---@field name string
---@field effects table
---@field castType tes3.spellType

---@param params SpellMaker.params
---@return tes3spell
function util.createSpell(params)
    log:trace("Creating spell %s", params.id)
    local spell = tes3.createObject{
        id = params.id,
        name = params.name,
        objectType = tes3.objectType.spell,
        castType = params.castType
    } ---@cast spell tes3spell

    for i, effect in ipairs(params.effects) do
        local newEffect = spell.effects[i]
        newEffect.id = effect.id
        newEffect.rangeType = effect.rangeType or tes3.effectRange["self"]
        newEffect.attribute = effect.attribute or nil
        newEffect.min = effect.min
        newEffect.max = effect.max
        newEffect.duration = effect.duration
    end
    return spell
end

return util
