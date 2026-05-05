local self = require("openmw.self")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local anim = require("openmw.animation")
local types = require("openmw.types")

local target
local action
local player
local isCreature

local onUpdateFired = false

local function applyTrapFancy(spell)
    local effectsWithParams = core.magic.spells.records[spell.id].effects
    local effects = {}
    for _, effect in ipairs(effectsWithParams) do
        table.insert(effects, effect.index)
    end
    self.type.activeSpells(self):add {
        id = spell.id,
        ---@diagnostic disable-next-line: assign-type-mismatch
        effects = effects
    }

    local effectId = effectsWithParams[1].effect.id
    local effectRecord = core.magic.effects.records[effectId]
    local magicSchoolSfx = core.stats.Skill.records[effectRecord.school].school.hitSound
    local effectSfx = effectRecord.hitSound or magicSchoolSfx
    local effectVfx = types.Static.records[effectRecord.hitStatic].model
    local openSfx = target.type.records[target.recordId].openSound

    anim.addVfx(self, effectVfx)
    core.sound.playSound3d(effectSfx, self)
    core.sound.playSound3d(openSfx, self)
end

local function freeSelf()
    self:enableAI(true)
    core.sendGlobalEvent(
        "FollowerCommands_detachScript",
        { follower = self, action = action }
    )
    player:sendEvent(
        "FollowerCommands_objectFreed",
        { target = target, follower = self, action = action }
    )
end

local function onInit(data)
    action = data.action
    target = data.target
    player = data.player
    isCreature = types.Creature.objectIsInstance(self)

    if isCreature then
        I.AnimationController.addTextKeyHandler(
            "attack1",
            function(groupname, key)
                if key == "stop" then
                    applyTrapFancy(target.type.getTrapSpell(target))
                    core.sendGlobalEvent("FollowerCommands_untrap", target)
                    freeSelf()
                end
            end
        )
    else
        I.AnimationController.addTextKeyHandler(
            "handtohand",
            function(groupname, key)
                if key == "slash hit" then
                    applyTrapFancy(target.type.getTrapSpell(target))
                    core.sendGlobalEvent("FollowerCommands_untrap", target)
                elseif key == "slash large follow stop" then
                    freeSelf()
                end
            end
        )
    end
end

local function onUpdate(dt)
    if onUpdateFired or I.AI.getActivePackage().type ~= "Follow" then
        return
    end

    onUpdateFired = true
    self:enableAI(false)
    if isCreature then
        I.AnimationController.playBlendedAnimation(
            "attack1",
            {
                startKey = 'start',
                stopKey = 'stop',
                priority = anim.PRIORITY.Scripted,
            }
        )
    else
        I.AnimationController.playBlendedAnimation(
            "handtohand",
            {
                startKey = 'equip start',
                stopKey = 'slash large follow stop',
                priority = anim.PRIORITY.Scripted,
            }
        )
    end
end

local function onLoad(data)
    if not data then return end
    target = data.target or target
    action = data.action or action
    player = data.player or player
    isCreature = data.isCreature or isCreature
end

local function onSave()
    return {
        target = target,
        action = action,
        player = player,
        isCreature = isCreature,
    }
end

return {
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
        onLoad = onLoad,
        onSave = onSave,
    },
}
