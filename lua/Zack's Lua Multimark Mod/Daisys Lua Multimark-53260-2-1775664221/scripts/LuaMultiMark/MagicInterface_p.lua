local prefix = "LMM" --Change this
local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local monitoredEffects = {}
local activeEffects = {}
local function isActive(effectId)
    local state = types.Actor.activeEffects(self):getEffect(effectId)
    return state and state.magnitude > 0
end
local function onFrame(dt)
    --check for player effects:
    for effect, state in pairs(monitoredEffects) do

        local active = activeEffects[effect]
        if active then
            if not isActive(effect) then
                self:sendEvent("EffectEnded", { effectId = effect, target = self })
                activeEffects[effect] = nil
            else
                self:sendEvent("EffectTick", { effectId = effect, target = self })
            end
        else
            if isActive(effect) then
                self:sendEvent("EffectStarted", { effectId = effect, target = self })
                activeEffects[effect] = true
            end
        end
    end
end

local function registerSpell(spellId, spellChance, spellRequired)

   local data = {spellId = spellId, chance = spellChance, spellRequired = spellRequired }
   core.sendGlobalEvent(prefix .. "_registerSpell",data)
end
return {
    interfaceName = prefix .. "_" .. "MagicInterface",
    interface = {
        ["monitorEffect"] = function(id)
            monitoredEffects[id:lower()] = true
        end,
        registerSpell = registerSpell,
    },
    engineHandlers = {
        onFrame = onFrame,
        onSave = function()
            return {

                activeEffects = activeEffects,
            }
        end,
        onLoad = function(data)
            if data then
                activeEffects = data.activeEffects
            end
        end
    }
}
