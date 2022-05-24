local config = mwse.loadConfig("Auto Harvest", {
    harvestEnabled = true,
    harvestDistance = 2,
    harvestTime = 10,
    AHBlacklist = {
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

local function getBlacklist()

    local list = {}
    for cont in tes3.iterateObjects(tes3.objectType.container) do
        if cont.organic and cont.script == nil then
            table.insert(list, cont.id:lower())
        end
    end
    table.sort(list)
    return list
end

local getCont
local gh = include("graphicHerbalism.config")

local function repeatCont()
    return getCont()
end

local function getContainers()

    if config.harvestEnabled then

        for container in tes3.player.cell:iterateReferences(tes3.objectType.container) do

            local cont = container.object
            local contDistance = tes3.player.position:distance(container.position)

            if (contDistance <= config.harvestDistance * 256 and cont.organic and cont.script == nil and #cont.inventory > 0 and not config.AHBlacklist[cont.id:lower()]) then

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
    end
    timer.start({ duration = config.harvestTime, callback = repeatCont })
end

local function onLoaded()
    getContainers()
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
        label = "Enable Auto Harvest",
        description = "Turns on/off Auto Harvesting.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "harvestEnabled", table = config}
    })

    settings:createSlider{
        label = "\n\n\nDistance from player to harvest",
        description = "Changes the distance which Auto Harvest will gather ingredients.\n\nDistance is game units(256) multiplied by slider value.\n\nWill only harvest from containers in the current cell.\n\nDefault: 2\n\n",
        min = 1,
        max = 20,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "harvestDistance", table = config}
    }

    settings:createSlider{
        label = "\n\n\nScan interval between harvests",
        description = "Changes the time between each Auto Harvest scan.\n\nTime is measured in seconds.\n\nDefault: 10\n\n",
        min = 1,
        max = 30,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "harvestTime", table = config}
    }

    template:createExclusionsPage{
        label = "Blacklist",
        description = "All organic non-plant containers and minerals(adamantium, diamonds, ebony, and glass) are blacklisted by default.\n\n Any container blacklisted here will NOT be harvested.",
        leftListLabel = "Blacklisted Containers",
        rightListLabel = "Harvestable Containers",
        variable = mwse.mcm.createTableVariable{
            id = "AHBlacklist",
            table = config,
        },
        filters = {
            {callback = getBlacklist}
        },
    }
end

event.register("modConfigReady", registerConfig)

local function initialized()

    event.register("loaded", onLoaded)
    mwse.log("[Krimson] Auto Harvest Initialized")
end

event.register("initialized", initialized)