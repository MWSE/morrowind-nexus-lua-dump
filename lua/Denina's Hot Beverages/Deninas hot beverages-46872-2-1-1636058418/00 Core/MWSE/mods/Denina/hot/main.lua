local config = require("Denina.hot.config")
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


local function rollForItem()
    local rand = math.random(100)
    return rand < mcmConfig.replacementChance
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

local function replaceItem(ref, newItem)
    if not tes3.getObject(newItem) then
        debug("%s does not exist. ESP not loaded?", newItem)
        return
    end
    debug("replacing %s with %s", ref.object.id, newItem)
    local newRef = tes3.createReference {
        object = newItem,
        position = ref.position:copy(),
        orientation = ref.orientation:copy(),
        cell = ref.cell
    }
    newRef.scale = ref.scale
    debug(newRef.scale)
    timer.delayOneFrame(function()
        ref:disable()
        mwscript.setDelete{ reference = ref}
    end)
    local itemData = ref.attachments.variables
    if itemData and itemData.owner then
        tes3.setOwner{ reference = newRef, owner = itemData.owner }
    end

    -- newRef.scale = ref.scale
    -- debug(newRef.scale)
    -- timer.delayOneFrame(function()
    --     ref:disable()
    --     mwscript.setDelete{ reference = ref}
    -- end)
end

local function getItemReplacement(ref)
    return config.replacements[ref.object.id:lower()]
end

local function replaceItems(e)
    if not mcmConfig.enabled then return end
    if not data then return end
    local cellId = getUniqueCellId(e.cell)
    --have we added beverages to this cell already?
    if not data.hotBeveragedCells[cellId] then
        debug("Adding hot beverages to %s", cellId)
        data.hotBeveragedCells[cellId] = true

        ---Look for items to replace
        for ref in e.cell:iterateReferences(tes3.objectType.miscItem) do
            local newItem = getItemReplacement(ref)
            if newItem and rollForItem() then
                replaceItem(ref, newItem)
            end
        end
    end
end
event.register("cellChanged", replaceItems)


--Initialisation
local function initData()
    debug("Init data")
    tes3.player.data.randomHotBeverages = tes3.player.data.randomHotBeverages or {}
    data = tes3.player.data.randomHotBeverages
    data.hotBeveragedCells = data.hotBeveragedCells or {}
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
        label = "Enable Hot Beverages",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createSlider{
        label = "Replacement Chance",
        description = "The % chance that a cup will be replaced with a hot drink.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "replacementChance", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
