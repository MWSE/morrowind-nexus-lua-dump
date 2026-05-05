local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')

local currentlyPickpocketedNpc = nil
local simulatedItems = {}
local preCounts = {}
local isPlayerSneaking = false

local modConfig = {
    EnableVendorPickpocketing = false
}

local function restoreEquipment()
    if currentlyPickpocketedNpc then
        local inv = types.Actor.inventory(currentlyPickpocketedNpc)
        local postCounts = {}
        
        for _, item in pairs(inv:getAll()) do
            postCounts[item.recordId] = (postCounts[item.recordId] or 0) + item.count
        end
        
        local equipment = types.Actor.getEquipment(currentlyPickpocketedNpc)
        local equippedObjects = {}
        for _, equipped in pairs(equipment) do
            equippedObjects[equipped.id] = true
        end

        for recordId, data in pairs(simulatedItems) do
            local pre = preCounts[recordId] or 0
            local post = postCounts[recordId] or 0
            
            -- How many added/missing in total?
            local simulatedDelta = post - pre
            
            -- How many clones are left over? (Clamped so we only destroy up to the amount we cloned)
            local excessToDestroy = math.min(data.originalClonedAmount, math.max(0, simulatedDelta))
            
            -- Did they steal any? (If the delta is less than our cloned amount, they took some)
            local stolenAmount = math.max(0, data.originalClonedAmount - math.max(0, simulatedDelta))
            
            if excessToDestroy > 0 then
                local itemsInInv = inv:findAll(recordId)
                local remainingExcess = excessToDestroy
                for _, invItem in pairs(itemsInInv) do
                    if remainingExcess <= 0 then break end
                    -- ONLY destroy unequipped stacks so we don't accidentally undress the NPC
                    if invItem:isValid() and not equippedObjects[invItem.id] then
                        local toDestroy = math.min(invItem.count, remainingExcess)
                        pcall(function() invItem:remove(toDestroy) end)
                        remainingExcess = remainingExcess - toDestroy
                    end
                end
            end
            
            if stolenAmount > 0 then
                local remainingTheft = stolenAmount
                for _, realItem in ipairs(data.realItems) do
                    if remainingTheft <= 0 then break end
                    if realItem:isValid() then
                        local toSteal = math.min(realItem.count, remainingTheft)
                        
                        local success, _ = pcall(function()
                            realItem:remove(toSteal)
                        end)
                        
                        -- If calling remove with a count fails (which happens for objects lying in the cell),
                        -- fallback to removing the object entirely.
                        if not success then
                            pcall(function() realItem:remove() end)
                        end
                        
                        remainingTheft = remainingTheft - toSteal
                    end
                end
            end
        end
    end
    currentlyPickpocketedNpc = nil
    simulatedItems = {}
    preCounts = {}
end

I.Activation.addHandlerForType(types.NPC, function(npc, actor)
    if actor.type == types.Player then
        if currentlyPickpocketedNpc and currentlyPickpocketedNpc ~= npc then
            restoreEquipment()
        end
        
        if not isPlayerSneaking then return end
        if types.Actor.stats.dynamic.health(npc).current <= 0 then return end
        
        currentlyPickpocketedNpc = npc
        simulatedItems = {}
        preCounts = {}
        
        local success, err = pcall(function()
            local inv = types.Actor.inventory(npc)
            for _, item in pairs(inv:getAll()) do
                preCounts[item.recordId] = (preCounts[item.recordId] or 0) + item.count
            end
            
            -- 1. EQUIPPED ITEMS
            for slotName, slotId in pairs(types.Actor.EQUIPMENT_SLOT) do
                local item = types.Actor.getEquipment(npc, slotId)
                if item and item.count > 0 then
                    local clone = world.createObject(item.recordId, item.count)
                    clone:moveInto(npc)
                    
                    if not simulatedItems[item.recordId] then 
                        simulatedItems[item.recordId] = { originalClonedAmount = 0, realItems = {} }
                    end
                    simulatedItems[item.recordId].originalClonedAmount = simulatedItems[item.recordId].originalClonedAmount + item.count
                    table.insert(simulatedItems[item.recordId].realItems, item)
                end
            end
            
            -- 2. VENDOR CHESTS AND LOOSE SHOP ITEMS
            if modConfig.EnableVendorPickpocketing then
                -- Chests
                local containers = npc.cell:getAll(types.Container)
                for _, container in pairs(containers) do
                    if container.owner and container.owner.recordId and string.lower(container.owner.recordId) == string.lower(npc.recordId) then
                        local cinv = types.Container.inventory(container)
                        for _, vendorItem in pairs(cinv:getAll()) do
                            if vendorItem.count > 0 then
                                local clone = world.createObject(vendorItem.recordId, vendorItem.count)
                                clone:moveInto(npc)
                                
                                if not simulatedItems[vendorItem.recordId] then 
                                    simulatedItems[vendorItem.recordId] = { originalClonedAmount = 0, realItems = {} }
                                end
                                simulatedItems[vendorItem.recordId].originalClonedAmount = simulatedItems[vendorItem.recordId].originalClonedAmount + vendorItem.count
                                table.insert(simulatedItems[vendorItem.recordId].realItems, vendorItem)
                            end
                        end
                    end
                end
                
                -- Loose items scattered in the shop
                local typeToService = {
                    [types.Weapon] = "Weapon",
                    [types.Armor] = "Armor",
                    [types.Clothing] = "Clothing",
                    [types.Potion] = "Potions",
                    [types.Ingredient] = "Ingredients",
                    [types.Book] = "Books",
                    [types.Apparatus] = "Apparatus",
                    [types.Lockpick] = "Picks",
                    [types.Probe] = "Probes",
                    [types.Repair] = "RepairItems",
                    [types.Miscellaneous] = "Misc"
                }

                local npcRec = types.NPC.record(npc)
                local services = {}
                if npcRec then
                    services = npcRec.servicesOffered or npcRec.services or {}
                    
                    local isAuto = false
                    if npcRec.isAutocalc ~= nil then isAuto = npcRec.isAutocalc end
                    if npcRec.autoCalc ~= nil then isAuto = npcRec.autoCalc end
                    
                    if isAuto and npcRec.class then
                        local successClass, classRec = pcall(function() return types.Class.record(npcRec.class) end)
                        if successClass and classRec then
                            services = classRec.servicesOffered or classRec.services or services
                        end
                    end
                end

                for looseType, serviceName in pairs(typeToService) do
                    -- Filter loose shelf items to ONLY what this merchant buys/sells
                    local sellsThis = true
                    local hasServices = (type(services) == "userdata") or (type(services) == "table" and next(services) ~= nil)
                    
                    if hasServices then
                        local success, val = pcall(function() return services[serviceName] end)
                        if success then
                            sellsThis = val
                        else
                            sellsThis = false
                        end
                        
                        if not sellsThis and serviceName == "RepairItems" then
                            local s2, v2 = pcall(function() return services["Repair"] or services["RepairItem"] end)
                            if s2 and v2 then
                                sellsThis = v2
                            end
                        end
                    end
                    
                    if sellsThis then
                        local itemsOnShelves = npc.cell:getAll(looseType)
                        for _, looseItem in pairs(itemsOnShelves) do
                            if looseItem.owner and looseItem.owner.recordId and string.lower(looseItem.owner.recordId) == string.lower(npc.recordId) then
                                if looseItem.count > 0 then
                                    local clone = world.createObject(looseItem.recordId, looseItem.count)
                                    clone:moveInto(npc)
                                    
                                    if not simulatedItems[looseItem.recordId] then 
                                        simulatedItems[looseItem.recordId] = { originalClonedAmount = 0, realItems = {} }
                                    end
                                    simulatedItems[looseItem.recordId].originalClonedAmount = simulatedItems[looseItem.recordId].originalClonedAmount + looseItem.count
                                    table.insert(simulatedItems[looseItem.recordId].realItems, looseItem)
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        if not success then
            actor:sendEvent('ShowMessage', "LUA ERROR: " .. tostring(err))
        end
        
        actor:sendEvent('StartMonitoringPickpocket')
    end
end)

local function PickpocketWindowClosed()
    restoreEquipment()
end

local function UpdatePickpocketSettings(data)
    modConfig.EnableVendorPickpocketing = data.EnableVendorPickpocketing
end

local function PlayerSneakStateChanged(data)
    isPlayerSneaking = data.sneaking
end

return {
    eventHandlers = {
        PickpocketWindowClosed = PickpocketWindowClosed,
        UpdatePickpocketSettings = UpdatePickpocketSettings,
        PlayerSneakStateChanged = PlayerSneakStateChanged
    }
}
