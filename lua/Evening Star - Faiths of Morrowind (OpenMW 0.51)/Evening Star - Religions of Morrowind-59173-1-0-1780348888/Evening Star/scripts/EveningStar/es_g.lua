ES = ES or {}
ES.DB = ES.DB or {}
require('scripts.EveningStar.gifts.gifts_g')

G_eventHandlers.EveningStar_warriorsCharge = function(data)
	if not data or not data.target then return end
	local target = data.target
	if not target:isValid() then return end
	if not types.Actor.objectIsInstance(target) then return end
	local health = types.Actor.stats.dynamic.health(target)
	local dmg = (health.base or 0) * (data.percent or 0)
	if dmg <= 0 then return end
	health.current = math.max(0, health.current - dmg)
end