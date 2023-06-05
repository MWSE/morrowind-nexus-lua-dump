-- AotS_Ships, written by Vidi_Aquam
-- Can be used and modified with due credit given
-- To see my scripts in action, check out my TES3MP server Ashes of the Sharmat for which this script was written: https://discord.gg/dQbsVGJqzx

-- Requires clientside assets from "Sails and Sales" (https://www.nexusmods.com/morrowind/mods/51937) though the mod itself remains incompatible with OpenMW/TES3MP and should not have its ESP activated
-- The sailboat requires that the assets from Tamriel_Data are also present in the client's data files, though it does not require the Tamriel_Data ESM to be used
-- If you are using a cell reset script, ensure that placed objects from this script will be retained in cell data across resets, otherwise this script will likely break (or players' boats will be erased at the very least).

-- /boats or /boat is the chat command to buy a boat
-- /dismount or /d will allow you to stop sailing

AotS_Ships = {}
AotS_Ships.data = {}

local itemPrefix = "aots_boats_"
local config = {
    -- these keys will break if they have capital letters in them (due to being used in item ids), so use snake_case
    rowboat = {
        stores = {
            bodypart = {
                model = "ds22/bp/rowboat_bp.nif",
            },
            clothing = {
                icon = "ds22/rowboat.dds",
                model = "x/ex_de_rowboat.nif",

            },
            activator = {
                name = "Rowboat",
                model = "x/ex_de_rowboat.nif"
            },
            miscellaneous = {
                weight = 100,
                value = 1250
            },
        },
        price = 2500,
        animation = "ds22/anim/rowboat.nif",
        modelOffset = {rotZ = math.pi}, -- A location table detailing the offset to the player's local location the static version should be placed at when dismounting; +y is forward
        playerOffset = {} -- Location table with the local offsets to where the player should be teleported to when dismounting
    },
    large_rowboat = {
        stores = {
            bodypart = {
                model = "ds22/bp/large_rowboat_bp.nif",
            },
            clothing = {
                icon = "ds22/large_rowboat.dds",
                model = "ds22/stat/large_rowboat_s.nif",

            },
            activator = {
                name = "Large Rowboat",
                model = "ds22/stat/large_rowboat_s.nif"
            },
            miscellaneous = {
                weight = 120,
                value = 1500
            }
        },
        price = 3000,
        animation = "ds22/anim/rowboat.nif",
        modelOffset = {}, -- A location table detailing the offset to the player's local location the static version should be placed at when dismounting; +y is forward
        playerOffset = {} -- Location table with the local offsets to where the player should be teleported to when dismounting
    },
    gondola = {
        stores = {
            bodypart = {
                model = "ds22/bp/gondola_bp.nif",
            },
            clothing = {
                icon = "ds22/large_rowboat.dds",
                model = "ds22/stat/stat_Gondola_01.nif",

            },
            activator = {
                name = "Gondola",
                model = "ds22/stat/stat_Gondola_01.nif"
            },
            miscellaneous = {
                weight = 80,
                value = 2000
            }
        },
        price = 4000,
        animation = "ds22/anim/gondola.nif",
        modelOffset = {rotZ = math.pi}, -- A location table detailing the offset to the player's local location the static version should be placed at when dismounting; +y is forward
        playerOffset = {} -- Location table with the local offsets to where the player should be teleported to when dismounting
    },
    skiff = {
        stores = {
            bodypart = {
                model = "ds22/bp/skiff_bp.nif",
            },
            clothing = {
                icon = "ds22/large_rowboat.dds",
                model = "x/ex_skiff.nif",

            },
            activator = {
                name = "Skiff",
                model = "x/ex_skiff.nif"
            },
            miscellaneous = {
                weight = 110,
                value = 1500
            }
        },
        price = 3000,
        animation = "ds22/anim/skiff.nif",
        modelOffset = {posZ = 2}, -- A location table detailing the offset to the player's local location the static version should be placed at when dismounting; +y is forward
        playerOffset = {} -- Location table with the local offsets to where the player should be teleported to when dismounting
    },
    sailboat = {
        stores = {
            bodypart = {
                model = "ds22/bp/sailboat_bp.nif",
            },
            clothing = {
                icon = "ds22/large_rowboat.dds",
                model = "sky/x/sky_ex_fisherboat_02.nif",

            },
            activator = {
                name = "Sailboat",
                model = "sky/x/sky_ex_fisherboat_02.nif"
            }
        },
        price = 6000,
        animation = "ds22/anim/sailboat.nif",
        modelOffset = {rotZ = (math.pi/2), posZ = 15}, -- A location table detailing the offset to the player's local location the static version should be placed at when dismounting; +y is forward
        playerOffset = {} -- Location table with the local offsets to where the player should be teleported to when dismounting
    }
}
local selectedShips = {}

AotS_Ships.loadData = function()
    AotS_Ships.data = jsonInterface.load("custom/AotS_Ships_Data.json")
    if AotS_Ships.data == nil then 
        AotS_Ships.data = {}
    end
end

AotS_Ships.saveData = function()
    jsonInterface.quicksave("custom/AotS_Ships_Data.json", AotS_Ships.data, {})
end

local AddItemToPid = function(pid, itemData) -- From Nkfree

    local player = Players[pid]

    if player == nil or not player:IsLoggedIn() then
        tes3mp.LogMessage(enumerations.log.ERROR, "Attempt at adding an item for non-existent pid " .. pid)
        return
    end

    local inventory = player.data.inventory
    local refId = itemData.refId
    local count = itemData.count
    local charge = itemData.charge
    local enchantmentCharge = itemData.enchantmentCharge
    local soul = itemData.soul

    -- Add the item server-side
    inventoryHelper.addItem(inventory, refId, count, charge, enchantmentCharge, soul)

    -- Send server packet to related player
    player:LoadItemChanges({itemData}, enumerations.inventory.ADD)
end

local RemoveItemFromPid = function(pid, itemData) -- From Nkfree

    local player = Players[pid]

    if player == nil or not player:IsLoggedIn() then
        tes3mp.LogMessage(enumerations.log.ERROR, "Attempt at removing an item for non-existent pid " .. pid)
        return
    end

    local inventory = player.data.inventory
    local refId = itemData.refId
    local count = itemData.count
    local charge = itemData.charge
    local enchantmentCharge = itemData.enchantmentCharge
    local soul = itemData.soul

    -- Remove the item server-side
    inventoryHelper.removeClosestItem(inventory, refId, count, charge, enchantmentCharge, soul)

    -- Send server packet to related player
    player:LoadItemChanges({itemData}, enumerations.inventory.REMOVE)
end

local generateListBoxStringFromList = function(list, funct) -- funct should take in an item from the list and return a string to be appended to the list
    local listString = "* BACK *\n"
    for i=1, #list do
        listString = listString  .. funct(list[i])
        if not (i == #list) then
            listString = listString .. "\n"
        end
    end
    return listString
end

local function getPlayerGold(pid)
	local goldLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, "gold_001", -1)
	if goldLoc then
		return Players[pid].data.inventory[goldLoc].count
	else
		return 0
	end
end

local function isPlayerSailing(pid)
    return Players[pid].data.customVariables.isSailing or false
end

AotS_Ships.isPlayerSailing = function(pid) -- global wrapper for check
    return isPlayerSailing(pid)
end 

local function calculateOffset(startLoc, offsetLoc) -- Takes two tes3mp location tables
    local endLoc = tableHelper.deepCopy(startLoc)
    local angle = startLoc.rotZ or 0 -- negative radian angle in the weird way tes3mp does them

    endLoc.posX = startLoc.posX + ( math.cos(-angle) * ( offsetLoc.posX or 0 ) )
    endLoc.posY = startLoc.posY + ( math.sin(-angle) * ( offsetLoc.posY or 0 ) )
    endLoc.posZ = startLoc.posZ + ( offsetLoc.posZ or 0 )
    endLoc.rotX = startLoc.rotX or 0
    endLoc.rotY = startLoc.rotY or 0
    endLoc.rotZ = angle + ( offsetLoc.rotZ or 0 )
    return endLoc
end

local function createBoat(pid, kind) --add boat in the world
    if config[kind] == nil then return end
    if not tes3mp.IsInExterior(pid) then return end
    local objectId = itemPrefix .. kind .. "_activator"

    local loc = packetReader.GetPlayerPacketTables(pid, "PlayerCellChange").location
    local cell = loc.cell
    local playerLoc = tableHelper.deepCopy(loc)
    loc.posZ = math.max(0, loc.posZ)
    loc.rotX = 0
    loc = calculateOffset(loc, config[kind].modelOffset)

    playerLoc = calculateOffset(playerLoc, config[kind].playerOffset)

    local refNum = logicHandler.CreateObjectAtLocation(cell, loc, dataTableBuilder.BuildObjectData(objectId), "place")
    Players[pid].data.location = playerLoc
    Players[pid]:LoadCell()

    if AotS_Ships.data[cell] == nil then AotS_Ships.data[cell] = {} end
    AotS_Ships.data[cell][refNum] = {
        owner = Players[pid].accountName,
        type = kind
    }
    AotS_Ships.saveData()
end

local function buyBoat(pid, kind)
    local playerGold = getPlayerGold(pid)
    if playerGold >= config[kind].price then
        createBoat(pid, kind)
        RemoveItemFromPid(pid, dataTableBuilder.BuildObjectData("gold_001", config[kind].price))
        -- Add creation of a boat house interior here for large ships
    else
        tes3mp.MessageBox(pid, 999999, "You do not have enough money to purchase this boat.")
    end
end

local function mountBoat(pid, boatId, loc)
    local itemId = itemPrefix .. boatId .. "_clothing"
    
    inventoryHelper.addItem(Players[pid].data.inventory, itemId, 1)
    Players[pid]:LoadItemChanges({{refId = itemId, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
    
    logicHandler.RunConsoleCommandOnPlayer(pid, "equip ".. itemId, false)
    
    Players[pid].data.character.modelOverride = config[boatId].animation
    
    tes3mp.SetModel(pid, config[boatId].animation)
    tes3mp.SendBaseInfo(pid)

    logicHandler.RunConsoleCommandOnPlayer(pid, "startscript " .. itemPrefix .. "beginfloatscript", false) -- begin MWscript 

    if loc then
        local playerLoc = calculateOffset(loc, config[boatId].playerOffset)
        Players[pid].data.location = playerLoc
        Players[pid]:LoadCell()
    end
end

local function clearBoat(pid, cellDescription, refNum, mounting) --remove boat from the world
    if LoadedCells[cellDescription] == nil then return end

    if AotS_Ships.data[cellDescription] and AotS_Ships.data[cellDescription][refNum] then
        if mounting then
            Players[pid].data.customVariables.isSailing = true
            Players[pid].data.customVariables.currentBoatData = AotS_Ships.data[cellDescription][refNum]
            local loc = LoadedCells[cellDescription].data.objectData[refNum].location
            mountBoat(pid, Players[pid].data.customVariables.currentBoatData.type, loc)

            Players[pid]:QuicksaveToDrive()

            tes3mp.MessageBox(pid, 999999, "Use /dismount (/d) to leave boat.")
        end

        logicHandler.DeleteObjectForEveryone(cellDescription, refNum)

        AotS_Ships.data[cellDescription][refNum] = nil
        if AotS_Ships.data[cellDescription] == {} then AotS_Ships.data[cellDescription] = nil end

        AotS_Ships.saveData()
    end
end

local function dismountBoat(pid, boatId)
    local itemId = itemPrefix .. boatId .. "_clothing"

    if inventoryHelper.containsItem(Players[pid].data.inventory, itemId) then
        inventoryHelper.removeClosestItem(Players[pid].data.inventory, itemId, 1)
        Players[pid]:LoadItemChanges({{refId = itemId, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.REMOVE)
    end

    logicHandler.RunConsoleCommandOnPlayer(pid, "startscript " .. itemPrefix .. "endfloatscript")

    Players[pid].data.character.modelOverride = nil
    tes3mp.SetModel(pid, "")
    tes3mp.SendBaseInfo(pid)
end

local function onPlayerSneak(pid) -- Triggered using MWscript and global variable trickery
    if isPlayerSailing(pid) then
        -- dismount code
        local boatId = Players[pid].data.customVariables.currentBoatData.type
        
        Players[pid].data.customVariables.isSailing = false
        Players[pid].data.customVariables.currentBoatData = nil
        createBoat(pid, boatId)
        dismountBoat(pid, boatId)
        Players[pid]:QuicksaveToDrive()
    end
end



local onObjectActivateValidator = function(eventStatus, pid, cellDescription, objects, players)
    if isPlayerSailing(pid) then
        return customEventHooks.makeEventStatus(false, false)
    end
    return customEventHooks.makeEventStatus(nil, nil)
end

local onServerPostInit = function() -- Set up all custom records

    -- MWscript to start boat stuff and prevent players from going onto the shore
	RecordStores["script"].data.permanentRecords[itemPrefix .. "floatscript"] = {
        scriptText = [[
            begin ]]..itemPrefix..[[floatscript

            short onLand

            if ( PCGet3rdPerson == 0 )
                PCForce3rdPerson
            endif

            if ( onLand == 0 )
                if ( getpos z > 5 )
                    addspell ]]..itemPrefix..[[beached
                    set onLand to 1
                endif
            else
                if ( getpos z < 5 )
                    removespell ]]..itemPrefix..[[beached
                    set onLand to 0
                endif
            endif

            end
        ]]
    }

    RecordStores["script"].data.permanentRecords[itemPrefix .. "beginfloatscript"] = {
        scriptText = [[
            begin ]]..itemPrefix..[[beginfloatscript
                DisablePlayerJumping
                DisablePlayerFighting
                DisablePlayerMagic
                PCForce3rdPerson
                addspell ]]..itemPrefix..[[ww
                player->startscript ]] .. itemPrefix .. [[floatscript
                player->stopscript ]]..itemPrefix..[[beginfloatscript
            end 
        ]]
    }

    -- MWscript to stop boat stuff
    RecordStores["script"].data.permanentRecords[itemPrefix .. "endfloatscript"] = {
        scriptText = [[
            begin ]]..itemPrefix..[[endfloatscript

                player->stopscript ]]..itemPrefix..[[floatscript
                EnablePlayerJumping
                EnablePlayerFighting
                EnablePlayerMagic
                removespell ]]..itemPrefix..[[ww
                removespell ]]..itemPrefix..[[beached
                player->stopscript ]]..itemPrefix..[[endfloatscript
            end 
        ]]
    }

    RecordStores["spell"].data.permanentRecords[itemPrefix .. "ww"] = { -- Waterwalking ability while in boat form
        name = "Sailing",
        subtype = 1,
        cost = 0,
        effects = {
            {
            id = 2, -- water walking
            attribute = -1, 
            skill = -1,
            rangeType = 0,
            area = 0,
            duration = 0,
            magnitudeMax = 1,
            magnitudeMin = 1
            },
            {
            id = 77, -- restore fatigue
            attribute = -1,
            skill = -1,
            rangeType = 0,
            area = 0,
            duration = 0,
            magnitudeMax = 100,
            magnitudeMin = 100
            }
        }
    }
    RecordStores["spell"].data.permanentRecords[itemPrefix .. "beached"] = { -- Speed drain when on land
        name = "Beached Ship",
        subtype = 1,
        cost = 0,
        effects = {
            {
            id = 17, -- drain attribute
            attribute = 4, -- speed
            skill = -1,
            rangeType = 0,
            area = 0,
            duration = 0,
            magnitudeMax = 1000,
            magnitudeMin = 1000
            },
            {
            id = 21, -- drain skill
            attribute = -1,
            skill = 8, -- athletics
            rangeType = 0,
            area = 0,
            duration = 0,
            magnitudeMax = 1000,
            magnitudeMin = 1000
            }
        }
    }

    for boatType, boatData in pairs(config) do -- body parts, clothing, and activators for all boats
        for storeType, data in pairs(boatData.stores) do
            RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType] = data
            if storeType == "clothing" then
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].parts = {{partType = 26, malePart = itemPrefix .. boatType .. "_bodypart"}}
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].subtype = 6 -- R gauntlet
            elseif storeType == "bodypart" then
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].part = 26 -- 26 = Tail
            elseif storeType == "miscellaneous" then
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].name = boatData.stores.activator.name
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].icon = boatData.stores.clothing.icon
                RecordStores[storeType].data.permanentRecords[itemPrefix .. boatType .. "_" .. storeType].model = boatData.stores.clothing.model
            end
        end
    end

    AotS_Ships.loadData()
end

local showBoatBuyGui = function(pid)
    if not isPlayerSailing(pid) then
        if tes3mp.IsInExterior(pid) == true then
            local posZ = tes3mp.GetPosZ(pid)
            if posZ < 256 then
                local boatList = {}
                for key, _ in pairs(config) do
                    table.insert(boatList, key)
                end

                local listBoxString = generateListBoxStringFromList(boatList, function(i) return config[i].stores.activator.name .. " (" .. config[i].price .. " gold)" end)

                tes3mp.ListBox(pid, 353535, "Select a boat to buy.", listBoxString)
            else
                tes3mp.MessageBox(pid, 999999, "Move closer to water level to buy a boat.")
            end
        else
            tes3mp.MessageBox(pid, 999999, "You must be in an exterior to buy a boat.")
        end
    else
        tes3mp.MessageBox(pid, 999999, "Dismount your current ship to buy a new one.")
    end
end

local getShipActivateButtonList = function(pid)
    local buttons = {}
    if selectedShips[pid].myShip then
        table.insert(buttons, "Sail")
    end

    if config[selectedShips[pid].boatId].interior ~= nil then
        table.insert(buttons, "Enter")
    end
    
    if selectedShips[pid].myShip and config[selectedShips[pid].boatId].stores.miscellaneous ~= nil then
        table.insert(buttons, "Pick Up")
    end

    if selectedShips[pid].myShip then
        table.insert(buttons, "Sell")
    end

    table.insert(buttons, "Cancel")
    return buttons
end

local showBoatActivateGui = function(pid)
    local activateOptionsList = getShipActivateButtonList(pid)
    if #activateOptionsList > 1 then
        local buttons = ""
        for i=1, #activateOptionsList do
            buttons = buttons .. activateOptionsList[i]
            if (i <= #activateOptionsList - 1) then
                buttons = buttons .. ";"
            end
        end
        local owner = AotS_Ships.data[selectedShips[pid].cell][selectedShips[pid].refNum].owner
        if owner == Players[pid].accountName then
            owner = "Your "
        else
            owner = owner .. "'s "
        end
        tes3mp.CustomMessageBox(pid, 353536, owner .. config[selectedShips[pid].boatId].stores.activator.name, buttons)
    else
        local boatType = AotS_Ships.data[selectedShips[pid].cell][selectedShips[pid].refNum].type
        local printableName = string.lower(config[boatType].stores.activator.name)
        tes3mp.MessageBox(pid, 99999, "This ".. printableName .." belongs to " .. AotS_Ships.data[selectedShips[pid].cell][selectedShips[pid].refNum].owner .. ".") -- Say whom this boat this belongs to
    end
end

local onGuiAction = function(eventStatus, pid, guiId, data)
    if guiId == 353535 then -- buy boat
        local boatList = {}
        for key, _ in pairs(config) do
            table.insert(boatList, key)
        end
        if tonumber(data) ~= 0 and tonumber(data) <= #boatList then
            buyBoat(pid, boatList[tonumber(data)])
        end
    elseif guiId == 353536 then -- boat activate
        local optionsList = getShipActivateButtonList(pid)
        local option = tonumber(data) + 1
        if optionsList[option] == "Sail" then -- mount ship
            clearBoat(pid, selectedShips[pid].cell, selectedShips[pid].refNum, true)
        elseif optionsList[option] == "Enter" then -- board ship
            --todo
        elseif optionsList[option] == "Pick Up" then
            clearBoat(pid, selectedShips[pid].cell, selectedShips[pid].refNum, false)
            AddItemToPid(pid, dataTableBuilder.BuildObjectData(itemPrefix .. selectedShips[pid].boatId .. "_miscellaneous", 1))
            tes3mp.MessageBox(pid, 999999, config[selectedShips[pid].boatId].stores.activator.name .. " has been added to your inventory.")
        elseif optionsList[option] == "Sell" then
            clearBoat(pid, selectedShips[pid].cell, selectedShips[pid].refNum, false)
            local gold = 0.5 * config[selectedShips[pid].boatId].price
            AddItemToPid(pid, dataTableBuilder.BuildObjectData("gold_001", gold))
            tes3mp.MessageBox(pid, 999999, tostring(gold) .. " gold has been added to your inventory.")
        end
        selectedShips[pid] = nil
    end
    
end

local onObjectActivateHandler = function(eventStatus, pid, cellDescription, objects, players)
    if eventStatus.validCustomHandlers then
        for refNum, object in pairs(objects) do
            if AotS_Ships.data[cellDescription] and AotS_Ships.data[cellDescription][refNum] then

                local myShip = false
                if AotS_Ships.data[cellDescription][refNum].owner == Players[pid].accountName then
                    myShip = true
                end

                local boatId = AotS_Ships.data[cellDescription][refNum].type
                    
                selectedShips[pid] = {
                    boatId = boatId,
                    cell = cellDescription,
                    refNum = refNum,
                    myShip = myShip
                }

                showBoatActivateGui(pid)

            end
        end
    end
end

local onPlayerDisconnectValidator = function(eventStatus, pid) 
    if eventStatus.validCustomHandlers then
        if isPlayerSailing(pid) then
            local boatId = Players[pid].data.customVariables.currentBoatData.type
            createBoat(pid, boatId)
            dismountBoat(pid, boatId)
            Players[pid].data.customVariables.isSailing = false
            Players[pid].data.customVariables.currentBoatData = nil
        end
    end
    return customEventHooks.makeEventStatus(nil, nil)
end

local stringStartMatch = function(str, prefix) -- returns true if the string str begins with the string prefix (not case sensitive)
    local sub = string.sub(str, 1, string.len(prefix))
    if string.lower(sub) == string.lower(prefix) then
        return true
    end
end

local onObjectPlaceValidator = function(eventStatus, pid, cellDescription, objects) 
    if eventStatus.validCustomHandlers then
        for uniqueIndex, object in pairs(objects) do
            if stringStartMatch(object.refId, itemPrefix) then
                local match = string.find(object.refId, "miscellaneous")
                if match then
                    -- misc item drop
                    local count = object.count or 1
                    if tes3mp.IsInExterior(pid) then
                        if count ~= 1 then
                            AddItemToPid(pid, dataTableBuilder.BuildObjectData(object.refId, (count - 1))) 
                        end
                        local boatType
                        for boatId, _ in pairs(config) do
                            if object.refId == itemPrefix .. boatId .. "_miscellaneous" then
                                boatType = boatId      
                                break
                            end
                        end
                        if boatType ~= nil then
                            createBoat(pid, boatType)
                        else
                            tes3mp.LogMessage(3, "[AotS_Ships] Could not find corresponding boat type for misc item \"".. object.refId .."\"")
                        end
                    else
                        tes3mp.MessageBox(pid, 999999, "You cannot place a boat in an interior.")
                        AddItemToPid(pid, dataTableBuilder.BuildObjectData(object.refId, count)) 
                    end
                else
                    -- clothing item drop
                    AddItemToPid(pid, dataTableBuilder.BuildObjectData(object.refId, 1))
                    logicHandler.RunConsoleCommandOnPlayer(pid, "equip " .. object.refId, false)
                end
                logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
            end
        end
    end
end

customEventHooks.registerHandler("OnServerPostInit", onServerPostInit)
customEventHooks.registerValidator("OnObjectActivate", onObjectActivateValidator)
customEventHooks.registerHandler("OnObjectActivate", onObjectActivateHandler)
customEventHooks.registerHandler("OnGUIAction", onGuiAction)
customEventHooks.registerValidator("OnPlayerDisconnect", onPlayerDisconnectValidator)
customEventHooks.registerHandler("OnObjectPlace", onObjectPlaceValidator)

customCommandHooks.registerCommand("boat", function(pid, cmd) showBoatBuyGui(pid) end)
customCommandHooks.registerCommand("boats", function(pid, cmd) showBoatBuyGui(pid) end)
customCommandHooks.registerCommand("dismount", function(pid, cmd) onPlayerSneak(pid) end)
customCommandHooks.registerCommand("d", function(pid, cmd) onPlayerSneak(pid) end)