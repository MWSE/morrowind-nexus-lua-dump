local self = require('openmw.self')

-- =============================================================================

local MyPatchQuests = {
    {
        id = "AA_BountyCaldera",
        name = "Bounty Hunter: Caldera",
        category = "Notices",
        subcategory = "Bounties",
        text = "Bandits have sprung up near the Caldera Mining Company."
    },
    {
        id = "AA_BountyRedMountain",
        name = "Bounty Hunter: Red Mountain",
        category = "Notices",
        subcategory = "Bounties",
        text = "A rouge is hiding where no outlaw would dare to go..."
    },
	{
        id = "AA_BountySheogorad",
        name = "Bounty Hunter: Sheogorad",
        category = "Notices",
        subcategory = "Bounties",
        text = "Jobs for bounty hunters in the Sheogorad."
    },
	{
        id = "AA_BountySolstheim",
        name = "Bounty Hunter: Solstheim",
        category = "Notices",
        subcategory = "Bounties",
        text = "The East Empire company is having trouble with outlaws"
    },
	{
        id = "KJS_Andrani_Request",
        name = "Bolnor's Dagger",
        category = "Notices",
        subcategory = "Requests",
        text = "Someone has misplaced his family dagger."
    },
	{
        id = "KJS_arathor_request",
        name = "Arathor's Bow",
        category = "Notices",
        subcategory = "Requests",
        text = "A mer needs to retrieve his bow."
    },
	{
        id = "KJS_bols_request",
        name = "Ebony for the Craftsman",
        category = "Notices",
        subcategory = "Requests",
        text = "A craftsman in Mournhold is looking for some Ebony."
    },
	{
        id = "KJS_catia_request",
        name = "A book for Catia Sosia",
        category = "Notices",
        subcategory = "Requests",
        text = "A smith in the Mournhold Bazaar is requesting a certain book."
    },
	{
        id = "KJS_Crabmeat",
        name = "Crab Meat for a Fishwife",
        category = "Notices",
        subcategory = "Requests",
        text = "Someone risks going hungry in Seyda Neen."
    },
	{
        id = "KJS_DB_contract",
        name = "The Assassin's Creed",
        category = "Notices",
        subcategory = "Requests",
        text = "Shady operations are abound in Caldera."
    },
	{
        id = "KJS_Delivery",
        name = "The Saint Delyn Courier",
        category = "Notices",
        subcategory = "Requests",
        text = "The local Vivec paper is looking for a courier."
    },
	{
        id = "KJS_junallei_request",
        name = "The Pearl Diver's Mishap",
        category = "Notices",
        subcategory = "Requests",
        text = "An Argonian diver has lost his pearls."
    },
	{
        id = "KJS_Missing_Amulet",
        name = "The Lady's Heirloom",
        category = "Notices",
        subcategory = "Requests",
        text = "Someone and something has gone missing from Ules Manor."
    },
	{
        id = "KJS_Nalcaraya_request",
        name = "Nalcarya's Request",
        category = "Notices",
        subcategory = "Requests",
        text = "An alchemist needs a special ingredient."
    },
	{
        id = "KJS_omavel_bounty",
        name = "Bounty Hunter: Dravil Omavel",
        category = "Notices",
        subcategory = "Bounties",
        text = "An outlaw has been spotted near Pelegiad."
    },
}

-- =============================================================================
-- REGISTRATION LOGIC
-- =============================================================================
local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
            -- Sends the quest packet to the main tracker on the first frame
            if not hasSent then
                self:sendEvent("bb_Completion_RegisterPack", MyPatchQuests)
                
                print("[bb_Completion Patch] Quests registered successfully.")
                
                hasSent = true
            end
        end
    }
}