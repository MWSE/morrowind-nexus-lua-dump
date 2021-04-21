--initialise config
local configPath = "realistic_repair"
local config = mwse.loadConfig(configPath) or {}
local defaults = {
    enableRealisticRepair = true,
    enableLootDamage = true,
    minCondition = 0,
    maxCondition = 50
}
for key, val in pairs(defaults) do
    if config[key] == nil then
        mwse.log("[Realistic Repair] setting defualt MCM value %s to %s", key, val)
        config[key] = val
    end
end
mwse.saveConfig(configPath, config)

local interop = require("mer.RealisticRepair.interop")

do --register vanilla tools/stations
    
    local stations = {
        { id = "furn_anvil00", name = "Anvil", toolIdPattern = "hammer"  },
        { id = "furn_t_fireplace_01", name = "Forge", toolIdPattern = "prong"   },
        { id = "furn_de_forge_01", name = "Forge", toolIdPattern = "prong" },
        { id = "furn_de_bellows_01", name = "Forge", toolIdPattern = "prong" },
        { id = "Furn_S_forge", name = "Forge", toolIdPattern = "prong" },
    }
    for _, newStation in ipairs(stations) do
        interop.addStation(newStation)
    end
end



--Strings
local sNoEquip = "Use an anvil or forge to repair items."
local sNoTools = "You do not have any tools."



--Control vars
local currentStation
local allowEquip

--Functions

local function findStation(id)
    return interop.stations[string.lower(id)]
end

local function openRepairMenu(e)
    if e.item then
        allowEquip = true
        tes3.mobilePlayer:equip{ item = e.item }
        tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
    end
end

local function repairItemFilter(e)
    for _, pattern in ipairs(currentStation.toolPatterns) do
        local isViableTool = (
            e.item.objectType == tes3.objectType.repairItem and
            string.find( 
                string.lower(e.item.name), 
                string.lower(pattern) 
            ) 
        )
        if isViableTool then return true end
    end
    return false
end


local function openRepairToolSelect()

    tes3ui.showInventorySelectMenu({
        title = currentStation.name,
        noResultsText = sNoTools,
        filter = repairItemFilter,
        callback = openRepairMenu
    })
end

local isBlocked
local function activateStation(e)
    
    if not config.enableRealisticRepair then return end
    
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if (keyTest and not tes3.menuMode() and currentStation) then
        if not isBlocked then
            openRepairToolSelect()
        end
    end
end
event.register("keyDown", activateStation)

local function blockScriptedActivate(e)
    isBlocked = e.doBlock
end
event.register("BlockScriptedActivate", blockScriptedActivate)


local function equipRepairItem(e) 

    if not config.enableRealisticRepair then return end
    if not ( e.item.objectType == tes3.objectType.repairItem ) then return end
    local isStationTool
    for _, station in pairs(interop.stations) do
        for _, pattern in ipairs(station.toolPatterns) do
            if string.find(string.lower(e.item.name), pattern ) then
                isStationTool = true
                break
            end
        end
    end

    if isStationTool  then
        if allowEquip then
            timer.delayOneFrame(function()
                allowEquip = false
            end)
        else
            tes3.messageBox(sNoEquip)
            return false
        end
    end
end

event.register("equip", equipRepairItem)



local id_indicator = tes3ui.registerID("AnvilRepair_Tooltip")
local function createActivatorIndicator()
    
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(id_indicator)
        if (
            currentStation and
            not tes3.menuMode()
        )then
            if not mainBlock then

                mainBlock = menu:createBlock({id = id_indicator })
                
                mainBlock.absolutePosAlignX = 0.5
                mainBlock.absolutePosAlignY = 0.01
                mainBlock.autoHeight = true
                mainBlock.autoWidth = true

               
                local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
                --labelBackground.borderTop = 4
                labelBackground.autoHeight = true
                labelBackground.autoWidth = true

                local labelBorder = labelBackground:createThinBorder({})
                labelBorder.autoHeight = true
                labelBorder.autoWidth = true
                labelBorder.paddingAllSides = 10

                local label = labelBorder:createLabel{ text = currentStation.name}
                label.autoHeight = true
                label.autoWidth = true
                label.wrapText = true
                label.justifyText = "center"
            end
        else
            if mainBlock then
                mainBlock:destroy()
            end
        end
    end
    
end


local function checkForStation()
    if not config.enableRealisticRepair then 
        return 
    end
    
    currentStation = nil
    local eyePos = tes3.getPlayerEyePosition()
    local eyeDir = tes3.getPlayerEyeVector()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDir
    }
    local validResult = (
        result and 
        result.reference and 
        result.reference.object.objectType == tes3.objectType.static
    )
    if validResult then
        local distance = eyePos:distance(result.intersection)
        if distance < 200 then
            local ref = result.reference
            currentStation = findStation(ref.object.id)
        end
    end
    createActivatorIndicator()
end

local function onLoad()
    timer.start{
        type = timer.real, 
        duration = 0.1,
        iterations = -1,
        callback = checkForStation
    }
end
event.register("loaded", onLoad)

------------------------------------------
--Damage equipment on death
-----------------------------------------

local function onDeath(e)
    --Damage Armor
    for id, slot in pairs(tes3.armorSlot) do
        local armor = tes3.getEquippedItem{
            actor = e.reference,
            objectType = tes3.objectType.armor,
            slot = slot
        }
        if armor then
            local conditionMulti = ( math.random(config.minCondition, config.maxCondition) / 100 ) 
            armor.variables.condition = armor.variables.condition * conditionMulti
        end
    end

    --Damage Weapon
    local weapon = tes3.getEquippedItem{
        actor = e.reference,
        objectType = tes3.objectType.weapon,
    }
    if weapon and weapon.variables then
        local conditionMulti = ( math.random(config.minCondition, config.maxCondition) / 100 ) 
        weapon.variables.condition = weapon.variables.condition * conditionMulti
    end

end

local function onDamage(e)
    if not config.enableLootDamage then return end

    if e.mobile.health.current <= 0 then
        onDeath(e)
    end
end

event.register("damaged", onDamage)



--------------------------------------------
--MCM
--------------------------------------------

local function registerMCM()
    local  sideBarDefault = (
        "Realistic Repair is amod designed to balance the Repair mechanic."
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Made by Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }

    end

    local realisticRepairDescription = (
        "When enabled, this mod will prevent you from repairing items using " ..
        "repair tools directly. Instead, you must activate Anvils in order to use " ..
        "repair hammers and activate forges to use repair prongs. Any anvil or forge " ..
        "in the game will work."
    )

    local damagedLootDescription = (
        "When enabled, NPC equipment will be heavily damaged upon death. " ..
        "This is to balance the economy by making it more difficult to make " ..
        "money looting enemies for gear."
    )

    local template = mwse.mcm.createTemplate("Realistic Repair")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Realistic Repair",
        variable = mwse.mcm.createTableVariable{
            id = "enableRealisticRepair", 
            table = config
        },
        description = realisticRepairDescription
    }
    page:createOnOffButton{
        label = "Enable damaged loot",
        variable = mwse.mcm.createTableVariable{
            id = "enableLootDamage", 
            table = config
        },
        description = damagedLootDescription
    }
    page:createTextField{
        label = "Minimum loot condition",
        variable = mwse.mcm.createTableVariable{
            id = "minCondition",
            table = config,
            numbersOnly = true,
        }
    }
    page:createTextField{
        label = "Maximum loot condition",
        variable = mwse.mcm.createTableVariable{
            id = "maxCondition",
            table = config,
            numbersOnly = true
        }
    }
    template:register()
end

event.register("modConfigReady", registerMCM)