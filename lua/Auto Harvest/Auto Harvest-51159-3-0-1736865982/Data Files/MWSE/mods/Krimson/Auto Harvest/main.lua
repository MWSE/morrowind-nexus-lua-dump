local config

event.register("modConfigReady", function()

    require("Krimson.Auto Harvest.mcm")
	config  = require("Krimson.Auto Harvest.config")
end)

local gh = include("graphicHerbalism.config")
local containers = {}
local ingredients = {}

local function processContainers(index)

    if index > #containers then
        return
    end

    local container = containers[index]
    if (container and container.object) then
        local cont = container.object
        if gh and not gh.blacklist[cont.id:lower()] then
            tes3.player:activate(container)
        else
            for _, stack in pairs(cont.inventory) do
                if (stack and stack.object and stack.count > 0) then
                    tes3.transferItem({from = container, to = tes3.mobilePlayer, item = stack.object.id, count = stack.count, playSound = true, limitCapacity = false, updateGUI = true})
                end
            end
        end
    end

    timer.start({duration = 0.1, callback = function()
        processContainers(index + 1)
    end})
end

local function processIngredients(index)

    if index > #ingredients then
        processContainers(1)
        return
    end

    local ingredient = ingredients[index]

    if ingredient then
        tes3.player:activate(ingredient)
        ingredient:disable()
    end

    timer.start({duration = 0.1, callback = function()
        processIngredients(index + 1)
    end})
end

local function getContainers()

    containers = {}
    ingredients = {}

    for _, cell in pairs(tes3.getActiveCells()) do
        if not config.AHContainerBL[cell.id:lower()] then
            for container in cell:iterateReferences(tes3.objectType.container) do
                if (container and container.object) then
                    local cont = container.object
                    local contDistance = tes3.player.position:distance(container.position)
                    if (contDistance <= config.harvestDistance * 256 and cont.organic and cont.script == nil and #cont.inventory > 0 and tes3.getOwner(container) == nil and not config.AHContainerBL[cont.id:lower()]) then
                        table.insert(containers, container)
                    end
                end
            end

            if config.ingredient then
                for ingredient in cell:iterateReferences(tes3.objectType.ingredient) do
                    if (ingredient and ingredient.object) then
                        local ingredDistance = tes3.player.position:distance(ingredient.position)
                        if (ingredDistance <= config.harvestDistance * 256 and ingredient.object.script == nil and tes3.getOwner(ingredient) == nil and not ingredient.disabled and not config.AHContainerBL[ingredient.id:lower()]) then
                            table.insert(ingredients, ingredient)
                        end
                    end
                end
            end
        end
    end

    local runtime = 0.1 * (#containers + #ingredients)

    if runtime < config.harvestTime then
        runtime = config.harvestTime
    end

    processIngredients(1)

    if config.harvestEnabled then
        timer.start({duration = runtime + 0.1, callback = getContainers})
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

local function initialized()

    event.register("keyDown", blacklistCell, {filter = config.blacklistKey.keyCode})
    event.register("keyDown", harvestOnKey, {filter = config.harvestKey.keyCode})
    event.register("keyDown", modToggle, {filter = config.toggleMod.keyCode})
    event.register("calcRestInterrupt", harvestOnWait)
    event.register("loaded", onLoaded)
    mwse.log("[Krimson] Auto Harvest Initialized")
end

event.register("initialized", initialized)