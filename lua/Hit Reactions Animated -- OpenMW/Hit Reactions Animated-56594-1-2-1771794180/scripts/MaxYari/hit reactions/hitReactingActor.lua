local self = require('openmw.self')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')

local mp = "scripts/MaxYari/hit reactions/"
local AnimManager = require(mp .. "anim_manager")

DebugLevel = 0

local recordBlackList = { ["ab01alsonar"] = true, ["ab01bird01"] = true } -- From where all birds going, don't need to process those, only wastes performance.
if recordBlackList[self.recordId] then return end

local healthData = self.type.stats.dynamic.health(self)
local lastHealth = healthData.current

local hitAnimGroups = { "hitreact1", "hitreact2", "hitreact3", "hitreact4" }
local hitAnimCount = #hitAnimGroups
local hitReactAnim = nil

local eventsSubbed = false
local frame = 0

local function onDamage(eventData)
    -- Some mods alter npc health during initialization. Skip first 10 frames to ignore those.
    if frame < 10 or not animation.hasGroup(self, "hitreact1") then return end

    if not hitReactAnim or not hitReactAnim:isPlaying() then
        hitReactAnim = AnimManager.Animation:play(
            hitAnimGroups[math.random(1, hitAnimCount)],
            {
                startKey = "start",
                stopKey = "stop",
                priority = animation.PRIORITY.Knockdown + 1,
                blendMask = animation.BLEND_MASK.Torso
            }
        )
    end
end

local function onUpdate(dt)
    if I.DynamicReticle and I.DynamicReticle.onDamage then
        if not eventsSubbed then
            I.DynamicReticle.onDamage:addEventHandler(onDamage)
            eventsSubbed = true
        end
    else
        local currentHealth = healthData.current
        local baseHealth = healthData.base
        lastHealth = math.min(lastHealth, baseHealth) -- In case max health changed - this should not trigger damage
        
        local damageValue = lastHealth - currentHealth

        if damageValue > 0 then
            onDamage(damageValue)
        end

        lastHealth = currentHealth
    end

    frame = frame + 1
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}