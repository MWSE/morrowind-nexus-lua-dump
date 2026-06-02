local self = require('openmw.self')

local theMananautsMessageQuests = {

	{
		id = "mdSM_Journal",
		name = "Alberius' Third Peregrination",
		category = "The Mananaut's Message",
		subcategory = "Tel Fyr",
		text = "Royal Imperial Mananaut Alberius comes from an outer realm on the authority of Koor-in-Ymne to capture/punish one Yagrum."
	},

}

local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
           
            if not hasSent then
                print("[Completionist] Sending quest data...")
               
                self:sendEvent("Completionist_RegisterPack", theMananautsMessageQuests)
               
                print("[Completionist] Data sent successfully!")
                hasSent = true
            end
        end
    }
}