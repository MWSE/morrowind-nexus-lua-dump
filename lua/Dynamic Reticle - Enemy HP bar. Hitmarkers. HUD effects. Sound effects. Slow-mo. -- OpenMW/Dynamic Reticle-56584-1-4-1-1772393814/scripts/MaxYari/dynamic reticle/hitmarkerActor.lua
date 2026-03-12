local mp = "scripts/MaxYari/dynamic reticle/"

local omwself = require('openmw.self')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local core = require("openmw.core")
local types = require("openmw.types")

local gutils = require(mp.."gutils")
local AnimManager = require(mp.."anim_manager")
local EventsManager = require(mp .. "events_manager")
local DEFS = require(mp .. "defs")

local selfActor = gutils.Actor:new(omwself)
local selfObject = omwself.object

local onDamageEvents = EventsManager:new()

DebugLevel = 2

local recordBlackList = {"ab01alsonar","ab01bird01"} -- From where all birds going, don't need to process those, only wastes performance.
if gutils.foundInList(recordBlackList, omwself.recordId) then return end

local imAGuard = selfActor:isAGuard()
local healthData = selfActor.stats.dynamic.health()
local lastHealth = healthData.current

local damageEventData = {} -- Allegedly making a new table every frame is bad for performance, probably a microoptimisation, but whatever, better than nothing

local function onUpdate(dt)
    if dt <= 0 then return end
   
    local baseHealth = healthData.base
    local currentHealth = healthData.current

    lastHealth = math.min(lastHealth, baseHealth) -- In case max health changed - this should not trigger damage

    local damageValue = lastHealth - currentHealth

    if damageValue > 0 then
        -- Should probably only fetch active packages here
        local activeAiPackage = I.AI.getActivePackage()
        if not activeAiPackage then return end        
        if activeAiPackage.type == "Combat" or (imAGuard and activeAiPackage.type == "Pursue") then
                        
            damageEventData.hostile = selfObject
            damageEventData.damage = damageValue
            damageEventData.damageFrac = damageValue/baseHealth
            damageEventData.currentHealth = currentHealth
            damageEventData.glancedHit = false
            
            if I.GlancedHits and I.GlancedHits.lastHitInfo then
                local now = core.getRealTime()
                if now - I.GlancedHits.lastHitInfo.time <= 0.1 then
                    damageEventData.glancedHit = I.GlancedHits.lastHitInfo.glancedHit
                end
            end

            local targets = I.AI.getTargets(activeAiPackage.type)
            for _, actor in ipairs(targets) do
                actor:sendEvent(DEFS.e.HostileDamaged, damageEventData)
            end

            onDamageEvents:emit(damageEventData)
        end
    end
    
    lastHealth = currentHealth
end


I.Combat.addOnHitHandler(function(attackInfo)
    if types.Player.objectIsInstance(attackInfo.attacker) and not attackInfo.successful then
        attackInfo.attacker:sendEvent(DEFS.e.MissedAttack)
    end
end)


return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    interfaceName = "DynamicReticle",
    interface = {
        version=1.1, 
        onDamage = onDamageEvents,
    }
}