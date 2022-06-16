local config = mwse.loadConfig("Auto Harvest", {
    harvestEnabled = true,
    harvestKey = {keyCode = tes3.scanCode.h, isShiftDown = false, isAltDown = false, isControlDown = false},
    toggleMod = {keyCode = tes3.scanCode.p, isShiftDown = false, isAltDown = false, isControlDown = false},
    blacklistKey = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false},
    harvestDistance = 2,
    harvestTime = 10,
    ingredient = true,
    waitHarvest = false,
    AHContainerBL = {
        ["barrel_01_ahnassi_drink"] = true,
        ["barrel_01_ahnassi_food"] = true,
        ["com_chest_02_mg_supply"] = true,
        ["com_chest_02_fg_supply"] = true,
        ["t_mwcom_furn_ch2fguild"] = true,
        ["t_mwcom_furn_ch2mguild"] = true,
        ["tr_com_sack_02_i501_mry"] = true,
        ["tr_i3-295-de_p_drinks"] = true,
        ["tr_i3-672_de_rm_deskalc"] = true,
        ["tr_m2_com_sack_i501_bg"] = true,
        ["tr_m2_com_sack_i501_sl"] = true,
        ["tr_m2_com_sack_i501_ww"] = true,
        ["tr_m2_q_27_fgchest"] = true,
        ["tr_m2_q_29_fgchest"] = true,
        ["tr_m3_i395_sack_local1"] = true,
        ["tr_m3_ingchest_i3-390-i"] = true,
        ["tr_m3_oe_anjzhirra_sack"] = true,
        ["tr_m3_soil_i3-390-ind"] = true,
        ["rock_adam_py09"] = true,
        ["rock_diamond_01"] = true,
        ["rock_diamond_02"] = true,
        ["rock_diamond_03"] = true,
        ["rock_diamond_04"] = true,
        ["rock_diamond_05"] = true,
        ["rock_diamond_06"] = true,
        ["rock_diamond_07"] = true,
        ["rock_ebony_01"] = true,
        ["rock_ebony_02"] = true,
        ["rock_ebony_03"] = true,
        ["rock_ebony_04"] = true,
        ["rock_ebony_05"] = true,
        ["rock_ebony_06"] = true,
        ["rock_ebony_07"] = true,
        ["rock_glass_01"] = true,
        ["rock_glass_02"] = true,
        ["rock_glass_03"] = true,
        ["rock_glass_04"] = true,
        ["rock_glass_05"] = true,
        ["rock_glass_06"] = true,
        ["rock_glass_07"] = true,
    },
})

local getCont
local gh = include("graphicHerbalism.config")

local function repeatCont()

    return getCont()
end

local function getContainers()

    for container in tes3.player.cell:iterateReferences(tes3.objectType.container) do

        local cont = container.object
        local contDistance = tes3.player.position:distance(container.position)

        if (contDistance <= config.harvestDistance * 256 and cont.organic and cont.script == nil and #cont.inventory > 0 and not config.AHContainerBL[cont.id:lower()]) then

            if tes3.getOwner(container) == nil then

                if gh and not gh.blacklist[cont.id:lower()] then

                    tes3.player:activate(container)
                else
                    for _, stack in pairs(cont.inventory) do

                        tes3.transferItem({ from = container, to = tes3.mobilePlayer, item = stack.object.id, count = stack.count, playSound = true, limitCapacity = false, updateGUI = true })
                    end
                end
            end
        end
    end

    if config.ingredient then

        for ingredient in tes3.player.cell:iterateReferences(tes3.objectType.ingredient) do

            local ingredDistance = tes3.player.position:distance(ingredient.position)

            if (ingredDistance <= config.harvestDistance * 256 and ingredient.object.script == nil and not config.AHContainerBL[ingredient.id:lower()]) then

                if tes3.getOwner(ingredient) == nil then

                    if not ingredient.disabled then

                        tes3.player:activate(ingredient)
                        ingredient:disable()
                    end

                    timer.start({ duration = 0.5, callback = function()

                        if ingredient.disabled then

                            ingredient:delete()
                        end
                    end})
                end
            end
        end
    end

    if config.harvestEnabled then

        timer.start({ duration = config.harvestTime, callback = repeatCont })
    end
end

local function harvestOnKey()

    if tes3ui.menuMode() then

        return
    end

    if not config.harvestEnabled then

        getContainers()
    end
end

local function modToggle()

    if tes3ui.menuMode() then

        return
    end

    if config.harvestEnabled then

        tes3.messageBox("Auto Harvest Paused")
        config.harvestEnabled = false

    elseif not config.harvestEnabled then

        tes3.messageBox("Auto Harvest Active")
        config.harvestEnabled = true
        getContainers()
    end
end

local function blacklistCell()

    if tes3ui.menuMode() then

        return
    end

    local cell = tes3.getPlayerCell()

    if not config.AHContainerBL[cell.id:lower()] then

        config.AHContainerBL[cell.id:lower()] = true
        tes3.messageBox(string.format("%s added to blacklist", cell.name))
    else
        config.AHContainerBL[cell.id:lower()] = false
        tes3.messageBox(string.format("%s removed from blacklist", cell.name))
    end
end

local function onLoaded()

    if config.harvestEnabled then

        getContainers()
    end
end

local function harvestOnWait(e)

    if ( e.waiting and config.waitHarvest and not config.harvestEnabled ) then

        getContainers()
    end
end

getCont = function ()

    getContainers()
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("Auto Harvest")
        template:saveOnClose("Auto Harvest", config)
        template:register()

    local page = template:createSideBarPage({
        label = "Auto Harvest",
        description = "Automatically harvests ingredients from any organic containers within range.\n\nWill not harvest any container that is blacklisted or has a script attached to it",
    })

    local settings = page:createCategory("Auto Harvest Settings\n\n\n")

    settings:createOnOffButton({
        label = "Auto Mode\n\n\n",
        description = "Turns on/off Auto Mode. Same as using the hotkey listed below.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "waitHarvest", table = config}
    })

    settings:createKeyBinder{
        label = "Auto Mode Hotkey. Restart the game to apply.\n\n\n",
        description = "Changes the keys to turn on/off Auto Mode.\n\nDefault: P\n\n",
        allowCombinations = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{id = "toggleMod", table = config, defaultSetting = {keyCode = tes3.scanCode.p, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }

    settings:createKeyBinder{
        label = "Harvest Hotkey. Restart the game to apply.\n\n\n",
        description = "Changes the keys to harvest on key press.\n\nOnly active if Auto Mode is off.\n\nDefault: H\n\n",
        allowCombinations = true,
        restartRequired = false,
        variable = mwse.mcm.createTableVariable{id = "harvestKey", table = config, defaultSetting = {keyCode = tes3.scanCode.h, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }

    settings:createKeyBinder{
        label = "Cell Blacklist Hotkey. Restart the game to apply.\n\n\n",
        description = "Changes the keys to add/remove current cell from blacklist.\n\nDefault: B\n\n",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{id = "blacklistKey", table = config, defaultSetting = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }

    settings:createOnOffButton({
        label = "Enable Auto Harvest on Waiting\n\n",
        description = "Turns on/off Auto Harvesting while \"waiting\" in the rest menu.\n\nOnly active if Auto Mode is off.\n\nDefault: Off\n\n",
        variable = mwse.mcm.createTableVariable {id = "waitHarvest", table = config}
    })

    settings:createSlider{
        label = "\n\nDistance from player to harvest",
        description = "Changes the distance which Auto Harvest will gather ingredients.\n\nDistance is game units(256) multiplied by slider value.\n\nWill only harvest from containers in the current cell.\n\nDefault: 2\n\n",
        min = 1,
        max = 20,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "harvestDistance", table = config}
    }

    settings:createSlider{
        label = "\n\n\nScan interval between harvests",
        description = "Changes the time between each Auto Harvest scan.\n\nTime is measured in seconds.\n\nOnly active if Auto Mode is on.\n\nDefault: 10\n\n",
        min = 1,
        max = 30,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "harvestTime", table = config}
    }

    settings:createOnOffButton({
        label = "Ingredients",
        description = "Turns on/off harvesting loose ingredients.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "ingredient", table = config}
    })

    template:createExclusionsPage{
        label = "Container Blacklist",
        description = "All organic non-plant containers and minerals(adamantium, diamonds, ebony, and glass) are blacklisted by default.\n\n Any container blacklisted here will NOT be harvested.",
        leftListLabel = "Blacklisted Containers",
        rightListLabel = "Harvestable Containers",
        variable = mwse.mcm.createTableVariable{
            id = "AHContainerBL",
            table = config,
        },
        filters = {
            {
                label = "Cells",
                callback = function()

                    local cellList = {}

                    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do

                        table.insert(cellList, cell.id:lower())
                    end
                    table.sort(cellList)
                    return cellList
                end

            },

            {
                label = "Containers",
                callback = function ()

                    local itemList = {}

                    for item in tes3.iterateObjects(tes3.objectType.container) do

                        if item.script == nil then

                            table.insert(itemList, item.id:lower())
                        end
                    end
                    table.sort(itemList)
                    return itemList
                end
            },

			{
                label = "Ingredients",
                callback = function ()

                    local itemList = {}

                    for item in tes3.iterateObjects(tes3.objectType.ingredient) do

                        if item.script == nil then

                            table.insert(itemList, item.id:lower())
                        end
                    end
                    table.sort(itemList)
                    return itemList
                end
            },
        },
    }
end

event.register("modConfigReady", registerConfig)

local function initialized()

    event.register("keyDown", blacklistCell, {filter = config.blacklistKey.keyCode})
    event.register("keyDown", harvestOnKey, {filter = config.harvestKey.keyCode})
    event.register("keyDown", modToggle, {filter = config.toggleMod.keyCode})
    event.register("calcRestInterrupt", harvestOnWait)
    event.register("loaded", onLoaded)
    mwse.log("[Krimson] Auto Harvest Initialized")
end

event.register("initialized", initialized)