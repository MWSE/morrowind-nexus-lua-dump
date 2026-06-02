local types = require('openmw.types')


local function MLT_DamageItemCondition(eventData)
	print("Damaging shield: " .. eventData.damage)
	damage = eventData.damage
	itemData = types.Item.itemData(eventData.item)
	actor = eventData.actor
	itemCondition = itemData.condition - damage
	if itemCondition < 0 then
		itemData.condition = 0
		actor:sendEvent('Unequip', {item = eventData.item})
	else
		itemData.condition = itemCondition
	end
end

return {
    eventHandlers = {
        MLT_DirAttack_damageShield = MLT_DamageItemCondition
    },
}
