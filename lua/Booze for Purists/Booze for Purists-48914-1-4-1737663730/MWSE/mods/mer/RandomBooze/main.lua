local config = require("mer.RandomBooze.config")
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


local function rollForBooze()
    local rand = math.random(100)
    return rand < mcmConfig.bottleChance
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

local function replaceBottle(ref, newBottle)
    if not tes3.getObject(newBottle) then
        debug("%s does not exist. ESP not loaded?", newBottle)
        return
    end
    debug("replacing %s with %s", ref.object.id, newBottle)
    local newRef = tes3.createReference {
        object = newBottle,
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

    newRef.scale = ref.scale
    debug(newRef.scale)
    timer.delayOneFrame(function()
        ref:disable()
        mwscript.setDelete{ reference = ref}
    end)
end

local function getBottleReplacement(ref)
    return config.bottleReplacements[ref.object.id:lower()]
end

local function replaceBottlesWithBooze(e)
    if not mcmConfig.enabled then return end
    if not data then return end
    local cellId = getUniqueCellId(e.cell)
    --have we added booze to this cell already?
    if not data.boozedCells[cellId] then
        debug("Adding booze to %s", cellId)
        data.boozedCells[cellId] = true

        ---Look for bottles to replace
        for ref in e.cell:iterateReferences(tes3.objectType.miscItem) do
            local newBottle = getBottleReplacement(ref)
            if newBottle and rollForBooze() then
                replaceBottle(ref, newBottle)
            end
        end
    end
end
event.register("cellChanged", replaceBottlesWithBooze)

--Initialisation
local function initData()
    debug("Init data")
    tes3.player.data.randomBooze = tes3.player.data.randomBooze or {}
    data = tes3.player.data.randomBooze
    data.boozedCells = data.boozedCells or {}
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
        label = "Enable Random Booze",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createSlider{
        label = "Replacement Chance",
        description = "The % chance that a bottle will be replaced with a bottle of booze.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{id = "bottleChance", table = mcmConfig}
    }
    settings:createOnOffButton{
        label = "Debug Mode",
        description = "Prints debug messages to mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
