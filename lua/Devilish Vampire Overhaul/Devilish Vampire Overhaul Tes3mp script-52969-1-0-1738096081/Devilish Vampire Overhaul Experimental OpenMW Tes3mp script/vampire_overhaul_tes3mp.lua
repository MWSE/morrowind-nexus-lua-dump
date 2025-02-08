-- Devilish Vampire Overhaul for TES3MP
-- Refactored to work with TES3MP's API

local Methods = {}

Methods.OnObjectActivate = function(eventStatus, pid, cellDescription, objects, players)
    tes3mp.LogMessage(2, "OnObjectActivate triggered for PID: " .. pid)

    -- Check if the player is sneaking
    local IsSneaking = tes3mp.GetSneakState(pid)
    if not IsSneaking then
        return -- Exit the function if the player is not sneaking
    end

    -- Iterate over activated objects
    for _, object in pairs(objects) do
        local deathPackets = LoadedCells[cellDescription].data.packets.death
        local actor_index = object.uniqueIndex

        -- Check if the object is a valid corpse (dead actor)
        if tableHelper.containsValue(deathPackets, actor_index) then
            tes3mp.LogMessage(2, "Actor with uniqueIndex " .. actor_index .. " is found in death packets. Proceeding with death handling.")


            -- Example feeding action: restore health
            local currentHealth = Players[pid].data.stats.healthCurrent
            local maxHealth = Players[pid].data.stats.healthBase
            local healthRestored = math.min(maxHealth - currentHealth, 25) -- Restore up to 25 health

            Players[pid].data.stats.healthCurrent = currentHealth + healthRestored
            Players[pid]:LoadStatsDynamic()

            tes3mp.LogMessage(2, "Player " .. pid .. " restored " .. healthRestored .. " health by feeding.")

            -- Use console command to add the Bloodthirst_Drink_Option spell to the player
            logicHandler.RunConsoleCommandOnPlayer(pid, "player->addspell \"Bloodthirst_Drink_Option\"")
            tes3mp.LogMessage(2, "Attempted to add spell 'Bloodthirst_Drink_Option' to player " .. pid)
        else
            tes3mp.LogMessage(2, "Actor with uniqueIndex " .. actor_index .. " is NOT found in death packets.")
        end
    end
end

-- Log registration to confirm the script is loaded
tes3mp.LogMessage(2, "Vampire Overhaul script loaded successfully")

-- Register the OnObjectActivate handler
customEventHooks.registerHandler("OnObjectActivate", Methods.OnObjectActivate)

-- Debugging to confirm event hook registration
tes3mp.LogMessage(2, "OnObjectActivate event handler registered.")

return Methods
