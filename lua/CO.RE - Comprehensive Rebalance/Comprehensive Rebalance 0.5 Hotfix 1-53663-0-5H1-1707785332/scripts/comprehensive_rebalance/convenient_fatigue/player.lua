local self = require('openmw.self')
local types = require('openmw.types')

local settings = require("scripts.comprehensive_rebalance.lib.settings")
local Actor = types.Actor

local delay = 0
local actorSpells = Actor.spells(self)

local function removeSpell()
    actorSpells:remove('fatigue resting')
    actorSpells:remove('fatigue resting faster')
end

local function addSpell(faster)
    if faster then
        actorSpells:add('fatigue resting faster')
    else
        actorSpells:add('fatigue resting')
    end
end

local function restHandler(dt)
    local section = settings.GetSection("char")
    local convenientSetting = section:get("convenientFatigueSetting")
	if self.controls.sneak == true and Actor.getStance(self) == Actor.STANCE.Nothing and convenientSetting ~= "disabled" and self.controls.movement == 0 and self.controls.sideMovement == 0 then
        delay = delay + dt
    else
        delay = 0
        removeSpell()
    end

    --if we've been crouched and still for 2 seconds, allow recharging
    if delay > section:get("convenientFatigueDelay") then
        addSpell(convenientSetting == "fast")
    end
end

return
{
	engineHandlers =
	{
		onUpdate = restHandler,
        --onSave = onSave,
        --onLoad = onLoad,
	}
}

