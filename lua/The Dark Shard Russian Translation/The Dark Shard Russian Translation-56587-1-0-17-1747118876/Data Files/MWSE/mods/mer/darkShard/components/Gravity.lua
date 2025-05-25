local common = require("mer.darkShard.common")
local logger = common.createLogger("Gravity")
local SpellMaker = require("mer.darkShard.components.SpellMaker")

---@class DarkShard.Gravity
local Gravity = {}
local GRAV_SPELL_ID = "afq_gravity"
local SLOW_FALL_MAGNITUDE = 1
local JUMP_MAGNITUDE = 30

local function getOrCreateLowGravAbility()
    return SpellMaker.createSpell{
        id = GRAV_SPELL_ID,
        name = "Низкая гравитация",
        castType = tes3.spellType.ability,
        effects = {
            {
                id = tes3.effect.slowFall,
                rangeType = tes3.effectRange.self,
                min = SLOW_FALL_MAGNITUDE,
                max = SLOW_FALL_MAGNITUDE
            },
            {
                id = tes3.effect.jump,
                rangeType = tes3.effectRange.self,
                min = JUMP_MAGNITUDE,
                max = JUMP_MAGNITUDE
            },
        },
    }
end


local function lowGravSpellExists()
    return tes3.getObject(GRAV_SPELL_ID) ~= nil
end

---Enable low gravity on a reference
---@param ref tes3reference? Default: tes3.player
function Gravity.enableLowGravity(ref)
    ref = ref or tes3.player
    logger:debug("Enabling low gravity on %s", ref.object.id)
    tes3.addSpell{ reference = ref, spell = getOrCreateLowGravAbility() }
end

---Disable low gravity on a reference
---@param ref tes3reference? Default: tes3.player
function Gravity.disableLowGravity(ref)
    if lowGravSpellExists() then
        ref = ref or tes3.player
        logger:debug("Disabling low gravity on %s", ref.object.id)
        tes3.removeSpell{ reference = ref, spell = GRAV_SPELL_ID }
    end
end

return Gravity