-- customEventHooks.registerHandler("OnPlayerAuthentified", function(_, pid)
--     if not KRL_IsPlayerValid(pid) then return end

--     KRL_PrintPlayerAngle(pid)

--     -- local cellDescription = player.data.location.cell
-- end)


-- local werewolfGuiId = 19208
-- local forgetWerewolfKnownCost = 1000

-- local function isPlayerValid(pid)
--     local player = Players[pid]

--     if not player then return false end
--     if not player:IsLoggedIn() then return false end

--     return player.data.shapeshift.werewolfHealthBase ~= nil
-- end

-- local function logWerewolf(pid, message)
--     tes3mp.LogMessage(enumerations.log.INFO, "pid ["..tostring(pid).."] "..tostring(message))
-- end

-- local function messageBoxWerewolf(pid, message)
--     tes3mp.MessageBox(pid, -1, tostring(message))
-- end

-- local function logBoxWerewolf(pid, message)
--     logWerewolf(pid, message)
--     messageBoxWerewolf(pid, message)
-- end

-- customCommandHooks.registerCommand("werewolf", function(pid, cmd)
--     if not isPlayerValid(pid) then return end
--     tes3mp.CustomMessageBox(pid, werewolfGuiId, "[Werewolf Menu]", "Fix Zero Max Mana;Remove Known Werewolf Status;Cancel")
-- end)

-- customEventHooks.registerValidator("OnGUIAction", function(eventStatus, pid, guiId, data)
--     if not isPlayerValid(pid) then return end

--     if guiId ~= werewolfGuiId then return end

--     local selection = tonumber(data)

--     if selection == 0 then
--         if Players[pid].data.stats.magickaBase > 0 then
--             messageBoxWerewolf(pid, "Your mana is fine silly :)")
--             return
--         end

--         local customVariables = Players[pid].data.customVariables

--         if not customVariables then logBoxWerewolf(pid, "Failed to fix mana :c\nNo custom variables.") return end

--         local patchedStats = customVariables.werewolfPatch

--         if not patchedStats then
--             logBoxWerewolf(pid, "Failed to fix mana :c\nNo patched stats.")
--             return
--         end

--         tes3mp.SetMagickaBase(pid, patchedStats.magickaBase)
--         tes3mp.SetFatigueBase(pid, patchedStats.fatigueBase)
--         tes3mp.SetMagickaCurrent(pid, 0)
--         tes3mp.SetFatigueCurrent(pid, 0)
--         tes3mp.SendStatsDynamic(pid)

--         messageBoxWerewolf(pid, "Mana fix complete :)")
--     elseif selection == 1 then
--         local globalClientVariables = Players[pid].data.clientVariables.globals

--         if not globalClientVariables.pcknownreset or globalClientVariables.pcknownreset.intValue ~= 1 then
--             messageBoxWerewolf(pid, "You are not a known werewolf.")
--             return
--         end

--         local goldIndex = inventoryHelper.getItemIndex(Players[pid].data.inventory, "gold_001")

--         if not goldIndex then logBoxWerewolf(pid, "Failed to remove known werewolf status.\nNo gold index, What?!") return end

--         local gold = Players[pid].data.inventory[goldIndex]

--         if not gold then logBoxWerewolf(pid, "Failed to remove known werewolf status.\nNo gold object, What?!") return end

--         local goldCount = gold.count

--         if not goldCount then logBoxWerewolf(pid, "Failed to remove known werewolf status.\nNo gold count, What?!") return end

--         if goldCount < forgetWerewolfKnownCost then
--             messageBoxWerewolf(pid, "You need at least "..tostring(forgetWerewolfKnownCost).." gold for this!")
--             return
--         end

--         logWerewolf(pid, "removing gold for known werewolf removal")

--         tes3mp.ClearInventoryChanges(pid)
--         tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
--         tes3mp.AddItemChange(pid, "gold_001", forgetWerewolfKnownCost, -1, -1, "")
--         tes3mp.SendInventoryChanges(pid)

--         logWerewolf(pid, "removing known werewolf status")

--         local newGlobals = {}

--         for key, value in pairs(globalClientVariables) do
--             if key ~= "pcknownreset" then
--                 newGlobals[key] = value
--             end
--         end

--         Players[pid].data.clientVariables.globals = newGlobals
--         Players[pid]:QuicksaveToDrive()

--         messageBoxWerewolf(pid, "You spent 1000 gold to remove the known werewolf status.")
--     end
-- end)

-- customEventHooks.registerHandler("OnPlayerCellChange", function(_, pid, newCell)
--     if not isPlayerValid(pid) then return end

--     if not Players[pid].data.customVariables then
--         Players[pid].data.customVariables = {}
--     end

--     if not Players[pid].data.customVariables.werewolfPatch then
--         Players[pid].data.customVariables.werewolfPatch = {}
--     end
    
--     local stats = Players[pid].data.stats

--     if stats.magickaBase > 0 then
--         logWerewolf(pid, "saving werewolf magic and fatigue")

--         Players[pid].data.customVariables.werewolfPatch = {
--             magickaBase = stats.magickaBase,
--             fatigueBase = stats.fatigueBase
--         }
--     end
-- end)