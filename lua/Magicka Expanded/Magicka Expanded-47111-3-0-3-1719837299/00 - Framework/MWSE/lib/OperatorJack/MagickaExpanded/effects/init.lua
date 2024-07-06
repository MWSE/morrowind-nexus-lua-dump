---@class MagickaExpanded.Effects
local this = {}

---@class MagickaExpanded.Effects.BasicEffectParams: tes3.addMagicEffect.params

---@class MagickaExpanded.Effects.Effect
---@field id tes3.effect
---@field min number?
---@field max number?
---@field rangeType tes3.effectRange?
---@field duration number?
---@field radius number?
---@field attribute tes3.attribute?
---@field skill tes3.skill?
---@field cost number?
---@field object tes3magicEffect?

--[[
    Contains all effect methods for the school of Illusion.
]]
this.illusion = require("OperatorJack.MagickaExpanded.effects.illusion")

--[[
    Contains all effect methods for the school of Conjuration.
]]
this.conjuration = require("OperatorJack.MagickaExpanded.effects.conjuration")

--[[
    Contains all effect methods for the school of Alteration.
]]
this.alteration = require("OperatorJack.MagickaExpanded.effects.alteration")

--[[
    Contains all effect methods for the school of Destruction.
]]
this.destruction = require("OperatorJack.MagickaExpanded.effects.destruction")

--[[
    Contains all effect methods for the school of Mysticisim.
]]
this.mysticism = require("OperatorJack.MagickaExpanded.effects.mysticism")

--[[
    Contains all effect methods for the school of Restoration.
]]
this.restoration = require("OperatorJack.MagickaExpanded.effects.restoration")

return this
