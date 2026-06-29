ES = ES or {}
ES.DB = ES.DB or {}
require('scripts.EveningStar.db.es_shrines')
require('scripts.EveningStar.gifts.gifts_g')

-- ------------------------------ shrine activation relay -------------------
-- relay activation to the player; don't return false (shrine script opens the menu)
local shrineIds = ES.DB.shrines.shrineIds
I.Activation.addHandlerForType(types.Activator, function(object, actor)
	if not types.Player.objectIsInstance(actor) then return end
	if shrineIds[object.recordId:lower()] then
		actor:sendEvent("EveningStar_shrineActivated", object)
	end
end)

G_eventHandlers.EveningStar_warriorsCharge = function(data)
	if not data or not data.target then return end
	local target = data.target
	if not target:isValid() then return end
	if not types.Actor.objectIsInstance(target) then return end
	local dmg = (types.Actor.stats.dynamic.health(target).base or 0) * (data.percent or 0)
	if dmg <= 0 then return end
	target:sendEvent("ModifyStat", { name = "health", amount = -dmg })
end