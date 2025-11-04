local config = require("StormAtronach.SO.config")
local log = mwse.Logger.new()
local util = {}
local factionList = {}

-- Let us check if Crafting Framework is active
local CF = tes3.isLuaModActive("CraftingFramework")
local CraftingFramework = nil
if CF then
CraftingFramework = require("CraftingFramework")
end

-- This function updates the faction list, which is used to determine if an item belongs to a faction or an NPC.
function util.updateFactionList()
local factions = tes3.dataHandler.nonDynamicData.factions
factionList = {}
for _, faction in pairs(factions) do
    factionList[faction.id] = true
end
return factionList
end

-- We reset the player data to blank
function util.resetData()
    tes3.player.data.SA_GTV = {}
    local data = tes3.player.data.SA_GTV
    --- Grudge mechanic. Not yet implemented
    data.npcs                   = {}
        data.npcs.items             = {}
        data.npcs.value             = 0
        data.npcs.lastTime          = 0
    data.factions               = {}
        data.factions.items         = {}
        data.factions.value         = 0
        data.factions.lastTime      = 0
    --- Current crime mechanic. Currently implemented
    data.currentCrime           = {}
        data.currentCrime.value     = 0
        data.currentCrime.size      = 0
        data.currentCrime.npcs      = {}
        data.currentCrime.factions  = {}
        data.currentCrime.cells     = {}

    return data
end

-- Return the data container for the mod or initialize it
function util.getData()
    if tes3.player.data.SA_GTV then
        return tes3.player.data.SA_GTV
    else
        local data = util.resetData()
        return data
    end
end

-- Reset the current crime
function util.resetCurrentCrime()
    local data = util.getData()
    data.currentCrime           = {}
        data.currentCrime.value     = 0
        data.currentCrime.size      = 0
        data.currentCrime.npcs      = {}
        data.currentCrime.factions  = {}
        data.currentCrime.cells     = {}
end


-- Get the max size of an object, defined as the longest dimension
function util.getMaxSize(item)
    if not item.boundingBox then log:debug("Get Max Size: Item does not have a bounding box") return 0 end
    local bBox = item.boundingBox
    local maxSize = math.round(math.max(bBox.max.x - bBox.min.x, bBox.max.y - bBox.min.y, bBox.max.z - bBox.min.z),2)
    return maxSize or 0
end

---@class updateDataParams
---@field ownerID string
---@field itemID string
---@field size number|nil
---@field count number|nil
---@field value number|nil

-- Update thieving victims long term memory -- Currently not integrated into the gameplay loop
---@param p updateDataParams
function util.updateData(p)
    local ownerID = p.ownerID -- The ownner id
    if not ownerID then log:debug("No owner id given") return false end
    local itemID = p.itemID
    if not itemID then log:debug("No owner id given") return false end
    local size = p.size or 0
    local count = p.count or 0
    local value = p.value or 0
    local data = util.getData()
    local TS = tes3.getSimulationTimestamp()

    -- Data handling nightmare ahead
	if factionList[ownerID] then --Here is to hoping that factionList has not changed since the game was loaded.
		-- If there is already a table created, great. If not, add an empty one
                data.factions[ownerID] = data.factions[ownerID] or {}
		-- Now, for the items themselves. If an item not already listed, then create a new subtable
		if not  data.factions[ownerID].items[itemID] then
				data.factions[ownerID].items[itemID] = {value = value, size = size, count = count, timestamp = TS}
		else -- and if it already exists, increase the count
				data.factions[ownerID].items[itemID].count = (data.factions[ownerID].items[itemID].count or 0) + count
                data.factions[ownerID].items[itemID].timestamp = TS
		end
		-- Now we increase the value registry
				data.factions[ownerID].value = (data.factions[ownerID].value or 0) + value*count
	else -- Same thing for the NPCs
				data.npcs[ownerID] = data.npcs[ownerID] or { items = {}, value = 0 }
		if not  data.npcs[ownerID].items[itemID] then
				data.npcs[ownerID].items[itemID] = {value = value, size = size, count = count, timestamp = TS}
		else
				data.npcs[ownerID].items[itemID].count = (data.npcs[ownerID].items[itemID].count or 0) + count
                data.npcs[ownerID].items[itemID].timestamp = TS
		end
				data.npcs[ownerID].value = (data.npcs[ownerID].value or 0) + value*count
	end
end

-- Let's check the inventory for stolen items
function util.checkInventoryForStolenItems()
    -- Set up the auxiliary data structure
    local   auxData = {}
            auxData.npcs        = {}
            auxData.factions    = {}
            auxData.size        = 0
            auxData.value       = 0
            auxData.items       = {}

    -- Scan the player's inventory for stolen items. Let's check if we have ashfall backpacks in there as well
    local inventory = {}
    CF = tes3.isLuaModActive("CraftingFramework")
    if CF and CraftingFramework then
        inventory = CraftingFramework.CarryableContainer.getFullInventory(tes3.player)
    else
        inventory = tes3.player.object.inventory
    end
    
    for _,  stack in pairs(inventory) do

        local item  = stack.object ---@cast item tes3item
        if  tes3.getItemIsStolen({item = item}) then
            local size      = util.getMaxSize(item) or 0
            local value     = tes3.getValue({item = item}) or 0
            local count     = stack.count or 1
            auxData.size    = auxData.size  + size*count
            auxData.value   = auxData.value + value*count
            -- Adding items to the global list
            if not auxData.items[item.id] then
                auxData.items[item.id] = {value = value, size = size, count = count}
            else
                auxData.items[item.id].count = auxData.items[item.id].count + count
            end
            -- Adding items to the owners lists
            for _, owner in pairs(item.stolenList) do
                local id = owner.id:lower()
                if factionList[id] then
                    auxData.factions[id] = auxData.factions[id] or { items = {}, value = 0, size = 0 }
                    if not  auxData.factions[id].items[item.id] then
                            auxData.factions[id].items[item.id] = {value = value, size = size, count = count}
                    else
                            auxData.factions[id].items[item.id].count = (auxData.factions[id].items[item.id].count or 0) + count
                    end
                    auxData.factions[id].value  = (auxData.factions[id].value or 0) + value*count
                    auxData.factions[id].size   = (auxData.factions[id].size  or 0) +  size*count
                else
                    auxData.npcs[id] = auxData.npcs[id] or { items = {}, value = 0, size = 0}
                    if not  auxData.npcs[id].items[item.id] then
                            auxData.npcs[id].items[item.id] = {value = value, size = size, count = count}
                    else
                            auxData.npcs[id].items[item.id].count = (auxData.npcs[id].items[item.id].count or 0) + count
                    end
                    auxData.npcs[id].value      = (auxData.npcs[id].value     or 0) + value*count
                    auxData.npcs[id].size       = (auxData.npcs[id].size      or 0) +  size*count
                end
            end
        end
    end
    return auxData
end
--- Updates the current crime data in the player data
function util.updateCurrentCrime()
    local auxData = util.checkInventoryForStolenItems()
    local data = util.getData()
    data.currentCrime.value     = auxData.value
    data.currentCrime.size      = auxData.size
    data.currentCrime.items     = {}
    data.currentCrime.items     = table.deepcopy(auxData.items)
    data.currentCrime.npcs      = {}
    data.currentCrime.npcs      = table.deepcopy(auxData.npcs)
    data.currentCrime.factions  = {}
    data.currentCrime.factions  = table.deepcopy(auxData.factions)
end

--- Remove items
---@param items any
function util.removeItems(items)
    CF = tes3.isLuaModActive("CraftingFramework")
    for itemID, v in pairs(items) do
        if CF and CraftingFramework then
        CraftingFramework.CarryableContainer.removeItem({
            reference = tes3.player,
            item = itemID,
            count = v.count or 1,
        })
        else
        tes3.removeItem({
            reference = tes3.player,
            item = itemID,
            count = v.count or 1,
        })
        end

    end
end

---Give items back to the owner
---@param npcRef tes3reference
---@param items any
function util.giveItemsBack(npcRef,items)
  -- We remove the items from the player
  util.removeItems(items)
  -- We add them to the NPC
    for itemID, v in pairs(items) do
        tes3.addItem({
            reference = npcRef,
            item = itemID,
            count = v.count or 1,
        })
    end
end

---Removes ownership from the items
---@param items any
function util.removeOwnership(items)
    for itemID, v in pairs(items) do
        tes3.setItemIsStolen({item = itemID, stolen = false})
    end
end

--- Owner detection stream
---@param npcSafeHandle mwseSafeObjectHandle
function util.gotCaughtOwner(npcSafeHandle)
    util.updateCurrentCrime() -- Ensure current crime is updated
    local data = util.getData()
    local npcRef = nil ---@cast npcRef tes3actor
    if npcSafeHandle:valid() then
        ---@type tes3reference
        npcRef = npcSafeHandle:getObject() 
    else
        log:debug("Reference was not valid when it got to gotCaughtOwner")
        return
    end
    --local npcRef = tes3.getReference(npcID) ---@cast npcRef tes3reference

    -- Obsesively nil checking everything to avoid crashes:
    if not npcRef or not npcRef.object or not npcRef.object.name then
        log:debug("Invalid NPC reference")
        return
    end

    local npcItems = data and data.currentCrime and data.currentCrime.npcs and data.currentCrime.npcs[npcRef.object.name:lower()] or nil
    if not npcItems then
        log:debug("No data for NPC %s", npcRef.object.name)
        return
    end
    local bribeValue = math.round(npcItems.value * (1 + 50/tes3.mobilePlayer.mercantile.current),0)

    local npcName = npcRef.object.name

    local caughtMessages = {
        "HEY! That's mine you're carrying, thief!",
        "N'wah! You reek of stolen wares!",
        "Caught red-handed, Outlander - that's not yours!",
        "Pilferer! Did you think no one would notice?",
        "Hand it over, scum. You've been found out.",
        "Fetcher's fingers are quick… but not quick enough.",
        "Do you think the Tribunal turns a blind eye, N'wah?",
        "Even a guar could see you're a thief.",
        "You shame yourself, and the laws of Morrowind.",
        "Wicked Outlander - those goods are not yours!",
        "HEY! That's not yours, N'wah!",
        }

    tes3.messageBox({
        message = caughtMessages[math.random(1,#caughtMessages)],
        buttons = {"Give items back", string.format("I can pay handsomely (%s Gold)",bribeValue),"The best witness is a dead witness!!"},
        showInDialog = false,
        callback = function (e)
            if e.button == 0 then
                -- Player chose to give items back
                util.giveItemsBack(npcRef,npcItems.items)
                tes3.updateInventoryGUI({reference = tes3.player}) -- Update the inventory GUI to reflect changes
                util.updateCurrentCrime() -- Update the current crime after giving items back
                tes3.messageBox("You returned the stolen items to %s. They seem displeased", npcName)
                npcRef.object.baseDisposition = math.max(npcRef.object.baseDisposition - config.dispositionDropOnDiscovery, 0)
            elseif e.button == 1 then
                local playerGold = tes3.getPlayerGold()
                if playerGold > bribeValue then
                    tes3.payMerchant{merchant = npcRef.mobile, cost = bribeValue}
                    tes3.playSound{reference = tes3.player, sound = "Item Gold Down"}
                    util.removeOwnership(npcItems.items)
                    util.updateCurrentCrime() -- Update the current crime
                    tes3.messageBox("Wealth beyond measure, Outlander. Next time, choose a merchant.")
                else
                -- Not enough gold, player chose to give items back
                util.giveItemsBack(npcRef,npcItems.items)
                tes3.updateInventoryGUI({reference = tes3.player}) -- Update the inventory GUI to reflect changes
                util.updateCurrentCrime() -- Update the current crime after giving items back
                tes3.messageBox("You don't have enough gold and returned the stolen items to %s. They seem very displeased", npcName)
                npcRef.object.baseDisposition = math.max(npcRef.object.baseDisposition - config.dispositionDropOnDiscovery*1.25, 0)
                end
            else
                -- Player chose to fight
                tes3.messageBox("You chose to fight %s!", npcRef.object.name)
                tes3.triggerCrime({
                    type = tes3.crimeType.theft,
                    value = npcItems.value or 0,
                    victim = npcRef,
                    forceDetection = true,
                })
                if npcRef.mobile then npcRef.mobile:startCombat(tes3.mobilePlayer) end
            end
        end,})
end

--- Guard detection stream
---@param npcSafeHandle mwseSafeObjectHandle
function util.gotCaughtGuard(npcSafeHandle)
    util.updateCurrentCrime() -- Ensure current crime is updated
    local data = util.getData()
    local npcRef = nil
    if npcSafeHandle:valid() then
        ---@type tes3reference
        npcRef = npcSafeHandle:getObject()
    else
        log:debug("Reference was not valid when it got to gotCaughtGuard")
        return
    end
    -- Obsesively nil checking everything to avoid crashes:
    if (not npcRef) or (not npcRef.object) or not (npcRef.mobile) then
        log:debug("Invalid NPC reference in gotCaughtGuard")
        return
    end

    local stolenItems = data.currentCrime.items
    local value       = data.currentCrime.value

    -- Is it an ordinator?
    local helmet = tes3.getEquippedItem({
        actor = npcRef,
        slot = tes3.armorSlot.helmet,
        objectType = tes3.objectType.armor
    })

    local isOrdinator = false
    if helmet and helmet.object and helmet.object.id then
        isOrdinator = helmet.object.id == "indoril helmet"
    end


    local caughtMessagesGuard = {
        "Sticky fingers, eh? Not on my watch.",
        "Caught you red-handed, rat.",
        "You're bold, but you're not clever.",
        "Thought you could slip that past us? Ha!",
        "A thief in Imperial lands? Not for long.",
        "Looks like someone's pockets are heavier than they should be.",
        "You think the Legion doesn't notice? Fool.",
        "Best hope the magistrate is in a forgiving mood, cutpurse.",
        "We've got a lawbreaker here! Steel yourselves, men.",
        "Hold it right there, thief! Those goods aren't yours.",
        "Caught with stolen property? You'll regret this.",
        "You stand accused of theft against the Empire.",
        "Thieving scum! You disgrace Imperial law.",
        "Think you can outwit the Empire? Fool.",
        "The law is clear, criminal. Those goods are forfeit.",
        "Justice will be swift - the Emperor's will is not mocked."
        }

    local caughtMessagesOrdinator = {
        "You profane this holy city with stolen goods. Surrender them, heretic.",
        "By the grace of the Tribunal, your crime is laid bare.",
        "Blasphemer. Even your breath reeks of thievery.",
        "Do you think the eyes of the Ordinators are blind, Outlander?",
        "The Tribunal sees all. And we are Their hands.",
        "You carry what is not yours. This is sacrilege.",
        "Your shame is written upon you. Confess, and face judgment.",
        "You dare sully the laws of Morrowind with such theft?",
        "There is no hiding sin from Almalexia's gaze, thief.",
        "Repent, N'wah. The Ordinators pass judgment now.",
        "The Tribunal's justice is swift, and it is absolute.",
        "You think to mock the Tribunal with petty theft? Blasphemer.",
        "Your crime blackens this holy land. We shall cleanse it.",
        "Sin clings to you like filth, outlander.",
        "The Tribunal's wrath descends on thieves and heretics alike.",
        "On your knees, criminal. Repent before the Three.",
        "Your fate is sealed. The Ordinators do not forgive.",
        "Every stolen trinket is another nail in your coffin, n'wah.",
        "You are unworthy even to speak the names of the Three.",
        "Your soul will find no mercy in Almalexia's gaze.",
    }
    local caughtMessages = {}
    if isOrdinator then
        caughtMessages = caughtMessagesOrdinator
    else
        caughtMessages = caughtMessagesGuard
    end

    tes3.messageBox({
        message = caughtMessages[math.random(1,#caughtMessages)],
        buttons = {"Surrender", "Do you know who I am?","Go ahead and search me","Surely we can overlook this"},
        showInDialog = false,
        callback = function (e)
            if e.button == 0 then
                -- Player chose to surrender. Start vanilla dialogue
                tes3.triggerCrime({
                    type = tes3.crimeType.theft,
                    value = value or 0,
                    forceDetection = true,
                })
            elseif e.button == 1 then
                local reputationTerm  = tes3.player.object.reputation
                local speechcraftTerm = tes3.mobilePlayer.speechcraft.current
                local check = (reputationTerm + 0.5*speechcraftTerm) > math.random(5,150)
                if check then
                    tes3.messageBox("A thousand pardons, Outlander")
                    util.removeOwnership(stolenItems)
                    util.updateCurrentCrime() -- Update the current crime
                else
                    tes3.messageBox("Why should I care?")
                    tes3.triggerCrime({
                    type = tes3.crimeType.theft,
                    value = value or 0,
                    forceDetection = true,
                })
                end
                local guardSH = tes3.makeSafeObjectHandle(npcRef)
                timer.start({
                    type = timer.simulate(),
                    duration = 0.1,
                    callback = function() 
                        if guardSH:valid() then
                            local guard = guardSH:getObject()
                            if guard.mobile then
                            guard.mobile:startDialogue()
                            else
                            log:debug("When attempting to initiate dialogue with guard when caught, the actor mobile was not found")
                            end
                        else
                            log:debug("The guard safe handle was not valid anymore")
                        end
                    end
                })
            elseif e.button == 2 then
                -- This one is tricky
                local sneakTerm = tes3.mobilePlayer.sneak.current
                local securityTerm = tes3.mobilePlayer.security.current
                local check = (0.5*sneakTerm + 0.5* securityTerm) > math.random(5,150)
                if check then
                    tes3.messageBox("Hmpf... Seems like I was mistaken")
                    util.removeOwnership(stolenItems)
                    util.updateCurrentCrime() -- Update the current crime
                else
                    tes3.triggerCrime({
                    type = tes3.crimeType.theft,
                    value = value or 0,
                    forceDetection = true,
                })
                tes3.messageBox("Caught red handed, thief!")
                end
            elseif e.button == 3 then
                local speechcraftTerm = tes3.mobilePlayer.speechcraft.current
                local dispostionTerm = npcRef.object.disposition
                local check = (0.5*speechcraftTerm + 0.75*dispostionTerm) > math.random(5,150)
                 if check then
                    tes3.messageBox("Very well... I think I can let this slide for now")
                    util.removeOwnership(stolenItems)
                    util.updateCurrentCrime() -- Update the current crime
                else
                    tes3.triggerCrime({
                    type = tes3.crimeType.theft,
                    value = value or 0,
                    forceDetection = true,
                })
                    tes3.messageBox("Caught red handed, thief!")
                --[[ This code did not work as expected. Letting vanilla take over
                local npcRefSH = tes3.makeSafeObjectHandle(npcRef)
                timer.delayOneFrame(function() if npcRefSH:valid() then
                    local npcRef2 = npcRefSH:getObject()
                    npcRef2.mobile:startDialogue()
                end end)
                ]]

                end
            else
                npcRef.mobile:startDialogue()
            end
        end,})
end


util.createLineRed =  function(origin, destination, widget_name)
    widget_name = widget_name or "raytest_debug_widget_red"
    local root = tes3.worldController.vfxManager.worldVFXRoot
    local line = root:getObjectByName(widget_name)

    if line == nil then
        line = tes3.loadMesh("mwse\\widgets.nif")  ---@cast line niTriShape
            :getObjectByName("axisLines")
            :getObjectByName("z")
            :clone()
        line.name = widget_name
        root:attachChild(line, true)
    end

    line.data.vertices[1] = origin
    line.data.vertices[2] = destination
    -- color of start position
    line.data.colors[1] = niPackedColor.new(255, 0, 0)
    -- color of end position
    line.data.colors[2] = niPackedColor.new(255, 0, 0)
    line.data:markAsChanged()
    line.data:updateModelBound()

    line:update()
    line:updateEffects()
    line:updateProperties()
end

util.createLineGreen = function(origin, destination, widget_name)
    widget_name = widget_name or "raytest_debug_widget_green"
    local root = tes3.worldController.vfxManager.worldVFXRoot

    local line = root:getObjectByName(widget_name) ---@cast line niTriShape

    if line == nil then

        line = tes3.loadMesh("mwse\\widgets.nif") ---@cast line niTriShape
            :getObjectByName("axisLines")
            :getObjectByName("z")
            :clone()
        line.name = widget_name
        root:attachChild(line, true)
    end

    line.data.vertices[1] = origin
    line.data.vertices[2] = destination
    -- color of start position
    line.data.colors[1] = niPackedColor.new(0, 255, 0)
    -- color of end position
    line.data.colors[2] = niPackedColor.new(0, 255, 0)
    line.data:markAsChanged()
    line.data:updateModelBound()

    line:update()
    line:updateEffects()
    line:updateProperties()
end

return util

