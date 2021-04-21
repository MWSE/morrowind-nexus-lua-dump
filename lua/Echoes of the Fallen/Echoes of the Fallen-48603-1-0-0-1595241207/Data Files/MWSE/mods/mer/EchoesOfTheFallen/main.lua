local modName = "Echoes of the Fallen"
local tombstoneId = "mer_tombstone"
local confPath = "echoesoftheFallen"
local common = require("mer.EchoesOfTheFallen.common")
local config = mwse.loadConfig(confPath, {
    enabled = true,
    maxTombstones = 1,
    epitaphTooltip = true,
    tombstones = {}
})

local function enterMainMenu()
    timer.delayOneFrame(function()
        tes3.tapKey(tes3.scanCode.escape)
        tes3.tapKey(tes3.scanCode.escape)
    end)
end


local thisTombData
--Adds new tombstone table to config, removes old ones
local function initialiseTombData()

    local newTombstone = {
        id = tes3.player.object.name .. tes3.getSimulationTimestamp(),
        name = tes3.player.object.name,
        cell = tes3.player.cell.id,
        position = { 
            x = tes3.player.position.x,   
            y = tes3.player.position.y,
            z = tes3.player.position.z
        },
        orientation = { 
            x = tes3.player.orientation.x,   
            y = tes3.player.orientation.y,
            z = tes3.player.orientation.z
        },
    }
    

    


    
    thisTombData = newTombstone
end

local function placeTombStone(data)
    local ref = tes3.createReference{
        object = tombstoneId, 
        cell = data.cell, 
        position = {data.position.x, data.position.y, data.position.z},
        orientation = {data.orientation.x, data.orientation.y, data.orientation.z}
    }

    ref.data.tombstoneId = data.id
end

local function finalise()
    config.tombstones[#config.tombstones + 1] = thisTombData
    --if too many tombstones, remove earliest ones
    if #config.tombstones > config.maxTombstones then
        for i = 1, #config.tombstones - config.maxTombstones do
            table.remove(config.tombstones, 1)
        end
    end

    placeTombStone(thisTombData)
    tes3.player.sceneNode.appCulled = true
    tes3.messageBox("")
    mwse.saveConfig(confPath, config)
    enterMainMenu()
end



local function relicMenu()
    local function selectRelic()
        timer.delayOneFrame(function() 
            tes3ui.showInventorySelectMenu{
                reference = tes3.player,
                title = "Select Relic",
                filter = function(e)
                    return true
                end,
                callback = function(e)
                    thisTombData.relic = e.item.id
                    finalise()
                end
            }
        end)
    end
    common.messageBox{
        message = "Now select a relic to leave behind.",
        buttons = { { text = "Okay", callback = selectRelic} }
    }
end

local function epitaphMenu()
    local label = string.format("Leave an epitaph for %s", tes3.player.object.name)

    local epitaphMenuID = tes3ui.registerID("TombStone_EpitaphMenu")
    local menu = tes3ui.createMenu{ id = epitaphMenuID, fixedFrame = true }
    menu.minWidth = 400
    menu.alignX = 0.5
    menu.alignY = 0
    menu.autoHeight = true

    local function leaveEpitaphMenu()        
        tes3ui.leaveMenuMode(epitaphMenuID)
        menu:destroy()
        relicMenu()
    end

    local paragraphField = mwse.mcm.createParagraphField(
        menu,
        {
            label = label,
            variable = mwse.mcm.createTableVariable{
                id = "epitaph", 
                table = thisTombData,
            },
            callback = leaveEpitaphMenu
        }
    )
    local okayButton = menu:createButton({ text = "Okay"})
    okayButton:register(
		"mouseClick", 
        function(e)
            paragraphField:press()
		end
    )
    timer.delayOneFrame(function()
        tes3ui.enterMenuMode(epitaphMenuID)
    end)
end


local function beginTombstone()
    initialiseTombData()
    epitaphMenu()
end

local function onDeath(e)
    if not config.enabled then return end
    if e.reference == tes3.player then
        common.messageBox{
            message = "Leave behind a tombstone?",
            buttons = {
                { text = "Yes", callback = beginTombstone }, 
                { text = "No", callback = enterMainMenu }
            }
        }
    end
end
event.register("death", onDeath)


local function placeTombstones()
    if not config.enabled then return end
    tes3.player.data.merTombstones = tes3.player.data.merTombstones or {}
    for _, data in ipairs(config.tombstones) do
        if not tes3.player.data.merTombstones[data.id] and not data.hasCollected then
            tes3.player.data.merTombstones[data.id] = true
            placeTombStone(data)
        end
    end
end
event.register("loaded", placeTombstones)


--Activating Tombstones

local function getTombstoneDataFromId(id)
    for _, data in ipairs(config.tombstones) do
        if data.id == id then
            return data
        end
    end
end

local function finaliseActivate(target, data)
    common.safeDelete(target)
    data.hasCollected = true
    mwse.saveConfig(confPath, config)
end


local function activateTombstone(e)
    local function collectRelic(data)
        local relic = tes3.getObject(data.relic)
        if relic then
            common.messageBox{
                message = string.format("%s's %s has been bequeathed to you.", data.name, relic.name),
                buttons = {{
                    text = "Take Relic",
                    callback = function()
                        tes3.addItem{
                            reference = tes3.player, 
                            item = relic, 
                            count = 1
                        }
                        local itemData = tes3.addItemData{
                            to = tes3.player,
                            item = relic,
                            updateGUI = true
                        }
                        itemData.data.tombstoneData = { name = data.name, epitaph = data.epitaph }
                        tes3.messageBox("You recieve %s's %s", data.name, relic.name)
                        finaliseActivate(e.target, data)
                    end
                }}
            }
        else
            tes3.messageBox("You pay your respects to %s.", data.name)
            --Object is missing, probably modlist changed. All, good you just don't get a relic
            finaliseActivate(e.target, data)
        end
    end
    if e.target.object.objectType == tes3.objectType.activator and e.target.data and e.target.data.tombstoneId then
        local data = getTombstoneDataFromId(e.target.data.tombstoneId)
        if data then
            local epitaph = data.epitaph
            if not epitaph or string.len(epitaph) == 0 then
                epitaph = string.format("This is the final resting place of %s.", data.name)
            end
            mwscript.explodeSpell({ reference = e.target, spell = "dispel" })
            common.messageBox{
                message = data.epitaph,
                buttons = {
                    {
                        text = "Pay Respects",
                        callback = function()
                            
                            collectRelic(data)
                        end
                    },
                    {
                        text = "Cancel"
                    }
                }
            }
        end
    end
end

event.register("activate", activateTombstone)



local function onTooltip(e)
    if e.itemData and e.itemData.data then
        local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
        if  e.itemData.data.tombstoneId then
            local data = getTombstoneDataFromId(e.itemData.data.tombstoneId)
            if data then
                label.text = string.format("Tombstone of %s", data.name)
            end
        end
        if e.itemData.data.tombstoneData then
            --label.text = string.format("%s's %s", e.itemData.data.tombstoneData.name, e.object.name)
            common.createTooltip(
                e.tooltip, 
                string.format("Relic: %s", e.itemData.data.tombstoneData.name),
                {157/255, 200/255, 207/255}
            )

            --show the epitaph as a tooltip. Remove Tooltips Complete description if it exists
            if config.epitaphTooltip then
                --remove existing description
                local tooltipComplete = e.tooltip:findChild(tes3ui.registerID("Tooltips_Complete_Keys"))
                if tooltipComplete then 
                    tooltipComplete.visible = false
                end
                local data = getTombstoneDataFromId()
                --add epitaph
                local block = e.tooltip:createBlock{}
                block.minWidth = 1
                block.maxWidth = 310
                block.autoWidth = true
                block.autoHeight = true
                block.paddingAllSides = 6

                local label= block:createLabel{text = string.format('"%s"',e.itemData.data.tombstoneData.epitaph) }
                label.wrapText = true

            end
        end
    end
end
event.register("uiObjectTooltip", onTooltip, { priority = -1 })



----MCM

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName}
    
    local page = template:createSideBarPage{ 
        description = "When a character dies, you will have the option to drop a tombstone at the place of your death. You will then write an epitaph for your fallen character and select an item from your inventory to leave as a relic. On your next playthrough, the tombstone will appear in the world where your previous character died. Activating the tombstone will bequeath to you the relic of the fallen hero."
    }

    page:createOnOffButton{
        label = "Mod Enabled",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createOnOffButton{
        label = "Show Epitaph on Relic",
        description = "Display the epitaph of your fallen character on the tooltip of their relic.",
        variable = mwse.mcm.createTableVariable{ id = "epitaphTooltip", table = config }
    }

    page:createSlider{
        label = "Max Active Tombstones",
        description = "Select how many tombstones can be active at a time. Default: 1.",
        min = 1,
        max = 20,
        variable = mwse.mcm.createTableVariable{ id = "maxTombstones", table = config }
    }

    template:register()
end

event.register("modConfigReady", registerModConfig)