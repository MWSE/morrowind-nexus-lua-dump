local config = require("mer.Shinies.config")
local modName = config.modName
local mcmConfig = mwse.loadConfig(modName, config.mcmDefaultValues)
local data

local function debug(message, ...)
    if mcmConfig.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end

--Container replacement-----------------------

local function rollForShiny()
    local rand = math.random(100)
    return rand < mcmConfig.shinyChance
end

local function replaceWithShiny(ref)
    local shinyId = table.choice(config.replacers)
    if not tes3.getObject(shinyId) then
        debug("%s does not exist. ESP not loaded?", shinyId)
        return
    end
    debug("replacing %s with %s", ref.object.id, shinyId)
    local newRef = tes3.createReference {
        object = shinyId,
        position = ref.position:copy(),
        orientation = ref.orientation:copy(),
        cell = ref.cell
    }
    newRef.scale = ref.scale
    timer.delayOneFrame(function()
        ref:disable()
        mwscript.setDelete{ reference = ref}
    end)
end

local function getUniqueCellId(cell)
    if cell.isInterior then
        return cell.id:lower()
    else
        return string.format("%s (%s,%s)",
        cell.id:lower(), 
        cell.gridX, 
        cell.gridY)
    end
end

local function canBeReplaced(ref)
    return config.replacees[ref.object.id:lower()]
end

local function addShinies(e)
    if not mcmConfig.enabled then return end
    if not data then return end
    local cellId = getUniqueCellId(e.cell)
    --have we added shinies to this cell already?
    if not data.shiniedCells[cellId] then
        debug("Adding shinies to %s", cellId)
        data.shiniedCells[cellId] = true

        ---Look for containers to replace
        for ref in e.cell:iterateReferences(tes3.objectType.container) do
            if canBeReplaced(ref) then
               debug("%s can be replaced", ref.object.id)
                if rollForShiny() then
                    replaceWithShiny(ref)
                end
            end
        end
    end
end
event.register("cellChanged", addShinies)


--Inventory Shinies 
local function addShiniesToActors(e)
    if not data then return end
    if not mcmConfig.enabled then return end

    local obj = e.reference.object
    local baseObj = obj.baseObject or obj
    for _, shinyData in ipairs(config.actorShinies) do
        if e.reference.data.hasShinyAdded then
            debug("%s has already had a shiny added.", obj.name)
        else
            local doAddShiny = false
            --creatures
            if shinyData.creatureType then
                local isShinyCreature = (
                    baseObj.objectType == tes3.objectType.creature and
                    baseObj.type == tes3.creatureType[shinyData.creatureType]
                )
                if isShinyCreature then
                    debug("Found Shiny %s", shinyData.creatureType)
                    doAddShiny = true
                end
            end
            --npcs
            if shinyData.class then
                local isShinyNPC = (
                    baseObj.objectType == tes3.objectType.npc and
                    baseObj.class.id == shinyData.class
                )
                if isShinyNPC then
                    doAddShiny = true
                end
            end

            if doAddShiny then
                e.reference.data.hasShinyAdded = true
                debug("Adding %s to %s", shinyData.shinyId, obj.name)
                local leveledItem = tes3.getObject(shinyData.shinyId)
                if not leveledItem then
                    debug("Could not find %s, ESP not loaded?", shinyData.shinyId)
                    return
                end
                if leveledItem.objectType ~= tes3.objectType.leveledItem then
                    debug("%s is not a leveled Item!", shinyData.shinyId)
                    return
                end
                local pickedItem = leveledItem:pickFrom()
                tes3.addItem{
                    reference = e.reference,
                    item = pickedItem,
                    updateGUI = true
                }
            end
        end
    end

end
event.register("mobileActivated", addShiniesToActors )


--Initialisation
local function initData()
    debug("Init data")
    tes3.player.data.shinies = tes3.player.data.shinies or {}
    data = tes3.player.data.shinies
    data.shiniedCells = data.shiniedCells or {}

    --because mobileActivated may have happened before data initialisation, 
    --  also add shinies here
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
        addShiniesToActors({reference = ref})
    end
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.creature) do
        addShiniesToActors({reference = ref})
    end
end
event.register("loaded", initData)

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Settings")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = "Enable Shinies",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createSlider{
        label = "Replacement Chance",
        description = "The % chance that a chest will be replaced with a shiny.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "shinyChance", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
