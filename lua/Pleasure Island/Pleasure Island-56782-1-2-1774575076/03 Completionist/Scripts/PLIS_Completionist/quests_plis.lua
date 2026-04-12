local Mechanics = require('scripts.Completionist.mechanics')

local quests = {

	{
		id = "PleasureIsland",
		name = "Pleasure Island",
		category = "Pleasure Island",
		subcategory = "Pleasure Island",
		text = "Someone in Llothanis has an offer..."
	},

}

-- =============================================================================
-- SENDS DATA
-- =============================================================================
local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
            
            if not hasSent then
                print("[PLIS_Completionist] Sending quest data...")
                
                self:sendEvent("Completionist_RegisterPack", quests)
                
                print("[PLIS_Completionist] Data sent successfully!")
                hasSent = true
            end
        end
    }
}