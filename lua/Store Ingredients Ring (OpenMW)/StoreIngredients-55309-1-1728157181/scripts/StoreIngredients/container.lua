Self = require('openmw.self')
Core = require('openmw.core')
return {
	engineHandlers = {
		onActivated = function(actor)
			Core.sendGlobalEvent( 'toxStoreIngredients', { container = Self.object, actor = actor, toPlayer = false })
		end
	}
}
