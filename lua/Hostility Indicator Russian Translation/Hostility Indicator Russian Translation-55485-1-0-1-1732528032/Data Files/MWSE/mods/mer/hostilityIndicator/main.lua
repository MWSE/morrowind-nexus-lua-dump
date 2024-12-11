local config = require('mer.hostilityIndicator.config')
local modName = config.modName
local rusName = config.rusName
local mcmConfig = mwse.loadConfig(modName, config.mcmDefaultValues)
local data--saved on tes3.player.data

local function debug(message, ...)
    if mcmConfig.debug then
        local output = string.format("[%s] %s", modName, tostring(message):format(...) )
        mwse.log(output)
    end
end

--Methods
local function isHostileToPlayer(mobile) 
    for actor in tes3.iterate(mobile.hostileActors) do
        if actor.reference == tes3.player then
            return true
        end
    end
    return false
end

local function getFight(mobile)
    local thisFight = mobile and mobile.fight
    if not thisFight then
        debug("isn't a mobile or it has no fight value")
        return
    end
    --if attacking player, treat fight as 100
    if isHostileToPlayer(mobile) then
        thisFight = 100
    end
 
    return thisFight
end

local function getNameColor(mobile)
    local thisFight = getFight(mobile)
    if not thisFight then
        debug("no fight value")
        return
    end
    local nameColor
    if mobile.isDead then
        nameColor = tes3ui.getPalette("disabledColor")
    else
        local normalColor = tes3ui.getPalette("header_color")
        local angryColor = tes3ui.getPalette("negative_color")
        local lowerLimit = 70
        local upperLimit = 100
        local normalisedFight = math.remap(
            math.clamp(thisFight, lowerLimit, upperLimit), 
            lowerLimit, 
            upperLimit, 
            0.0, 
            1.0  
        )
        local fAngry = normalisedFight
        local fNorm = 1-fAngry
        nameColor = {
            (normalColor[1] * fNorm + angryColor[1] * fAngry),
            (normalColor[2] * fNorm + angryColor[2] * fAngry),
            (normalColor[3] * fNorm + angryColor[3] * fAngry),
        }
    end
    debug("New color: %s, %s, %s", nameColor[1], nameColor[2],nameColor[3])
    return nameColor
end

local function getName(reference)
    debug("getting name for %s", reference.object.id)
    local obj = reference.baseObject and reference.baseObject or reference.object
    if obj.objectType == tes3.objectType.creature then
        debug("Name is %s", obj.name)
        return obj.name
    elseif obj.objectType == tes3.objectType.npc then
        debug("Name is %s", obj.race.name)
        return obj.race.name
    else
        debug("No name to return, wasn't a creature or npc")
        return nil
    end
end

local id_indicator = tes3ui.registerID("TargetIdentifier_Tooltip")
local function createTooltip(name, color)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        debug("Creating tooltip for %s", name)
        local mainBlock = menu:createBlock({id = id_indicator })
        mainBlock.absolutePosAlignX = 0.5
        mainBlock.absolutePosAlignY = 0.03
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
        labelBorder.flowDirection = "top_to_bottom"

        local label = labelBorder:createLabel({text = name})
        label.color = color
    end
end

local function clearTooltip()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        debug("Clearing tooltip for %s", name)
        local mainBlock = menu:findChild(id_indicator)
        if mainBlock then
            mainBlock:destroy()
        end
    end
end

local function isHotkeyDown()
    local inputController = tes3.worldController.inputController
    return inputController:isKeyDown(mcmConfig.hotkey.keyCode)
end

--Events
local nameId = tes3ui.registerID("HelpMenu_name")
local function onObjectTooltip(e)
    if not mcmConfig.enabled then return end
    local mobile = e.reference and e.reference.mobile
    if not mobile then 
        debug("onObjectTooltip: not a mobile")
        return 
    end

    local nameLabel = e.tooltip:findChild(nameId)
    nameLabel.color = getNameColor(mobile)
end
event.register("uiObjectTooltip", onObjectTooltip)

local function onSimulate(e)
    clearTooltip()
    if not mcmConfig.enabled then return end

    if not isHotkeyDown() then
        debug("hotkey isn't pressed")
        return
    end
    if tes3.getPlayerTarget() then 
        debug("player has target")
        return
    end
    if not mcmConfig.enabled then
        debug("mod disabled")
        return
    end

    local eyePos = tes3.getPlayerEyePosition()
    local eyeDir = tes3.getPlayerEyeVector()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeDir,
        ignore = { tes3.player }
    }
    if not result then 
        debug("no result")
        return
    end

    if not result.intersection then
        debug("no intersection")
        return
    end

    local distance = eyePos:distance(result.intersection)
    if distance > mcmConfig.maxTargetDistance then
        debug("too far away. Distance: %d, max: %d", distance, mcmConfig.maxTargetDistance)
        return
    end

    local target = result.reference
    if not target then 
        debug("no target")
        return
    end

    local nameColor = getNameColor(target.mobile)
    local name = getName(target)
    if not name then
        debug("no name")
        return
    end
    if not nameColor then
        debug("no nameColor")
    end
    createTooltip(name, nameColor)
    debug("done")
end
event.register("simulate", onSimulate)

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = rusName }
    template:saveOnClose(modName, mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Настройки")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Включить %s", rusName),
        description = "Включить или выключить мод.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = mcmConfig}
    }
    settings:createKeyBinder{
        label = "Горячая клавиша",
        description = "Посмотрите на существо или NPC, удерживая эту клавишу, чтобы активировать индикатор враждебности.",
        variable = mwse.mcm.createTableVariable{ id = "hotkey", table = mcmConfig},
        allowCombinations = false,
    }
    settings:createSlider{
        label = "Максимальное расстояние для индикатора",
        description = "Максимальное расстояние между игроком и NPC/существом, на котором может быть активирован индикатор враждебности.",
        min = 1000,
        max = 10000,
        step = 100,
        jump = 1000,
        variable = mwse.mcm.createTableVariable{ id = "maxTargetDistance", table = mcmConfig }
    }
    settings:createOnOffButton{
        label = "Режим отладки",
        description = "Запись отладочных сообщений в mwse.log.",
        variable = mwse.mcm.createTableVariable{id = "debug", table = mcmConfig}
    }
end
event.register("modConfigReady", registerModConfig)
