local self = require('openmw.self')

-- =============================================================================
-- STANDALONE QUEST PATCH TEMPLATE
-- =============================================================================
-- Instructions:
-- 0. Replace the file and folder names with a unique name.
-- 1. Replace the table name 'MyPatchQuests' with a unique name.
-- 2. Insert your quest data into the table below.
-- 3. Ensure each 'id' is unique to avoid conflicts.
-- 4. Register this script in your .omwscripts file.
-- 5. Replace 'MyPatchQuests' in 'self:sendEvent("Completionist_RegisterPack", MyPatchQuests)' with your table name.
-- =============================================================================

local MyPatchQuests = {
    {
        -- Simple ID: Marked as complete when this Journal ID is finished.
        id = "MyMod_Quest_01",
        name = "The Mystery of the Missing Spoon",
        category = "Amazing Quests",
        subcategory = "Town Mysteries",
        text = "Help the local baker find his favorite lucky spoon.",
	master = "My Mod"
    },
    {
        -- AND Logic: Player must finish BOTH IDs (separated by a comma).
        id = "Quest_Part_A, Quest_Part_B",
        name = "The Ancient Trial",
        category = "Amazing Quests",
        subcategory = "Trials",
        text = "Prove your worth by completing both the Trial of Fire and the Trial of Water.",
	master = "My Mod"
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
                -- This automatically registers your quests with Completionist
                self:sendEvent("Completionist_RegisterPack", MyPatchQuests)
                
                -- Confirmation log in the console (F10)
                print("[Completionist Patch] Quests registered successfully.")
                
                hasSent = true
            end
        end
    }
}