local common = require('ss20.common')
local config = common.config
local modName = config.modName
local mushroomId = 'ss20_mushroom_grow'
local orbId = 'ss20_reductionorb'
local target

local initCameraDrop = -70
local minScale = 0.5
local mushChange = 0.1
local maxScale = 2.0
local scaleNeeded = 1.8

local id_indicator = tes3ui.registerID("SS20:activatorTooltip")
local id_label = tes3ui.registerID("SS20:activatorTooltipLabel")


local function centerText(element)
    element.autoHeight = true
    element.autoWidth = true
    element.wrapText = true
    element.justifyText = "center" 
end

local function createTooltip(name)
    
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(id_indicator)
        if mainBlock then
            mainBlock:destroy()
        end

        mainBlock = menu:createBlock({id = id_indicator })
        
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

        local text = name
        local label = labelBorder:createLabel{ id=id_label, text = text}
        label.color = tes3ui.getPalette("header_color")
        centerText(label)
    end
end

local function destroyTooltip()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(id_indicator)
        if mainBlock then
            mainBlock:destroy()
        end
    end
end

local function onSimulate()
    local camera = tes3.worldController.worldCamera.camera
    if  tes3.player.cell.id == "Horavatha's Gauntlet, Reduction" then
        local camPos = tes3.getPlayerEyePosition() + camera.translation
        local camOri = tes3.getPlayerEyeVector()
        local result = tes3.rayTest{
            position = camPos,
            direction = camOri,
            ignore = { tes3.player },
            maxDistance = 200 * tes3.player.scale
        }
        if result and  result.reference then
            if  result.reference.baseObject.id:lower() == mushroomId then
                common.log:trace("Looking at mushroom")
                target = result.reference
                createTooltip("Strange Mushroom")
            elseif result.reference.baseObject.id:lower() == orbId then
                target = result.reference
                createTooltip(target.object.name)
            end
        else
            target = nil
            destroyTooltip()
        end
    else
        target = nil
        destroyTooltip()
    end
end
event.register("simulate", onSimulate)


local function growEffect()
    local effect = tes3.createReference{
        object = 'AB_Fx_MagicMystCast',
        position = tes3.player.position:copy(),
        cell = tes3.player.cell
    }
    effect.scale = tes3.player.scale
    tes3.playSound{ reference = tes3.player, sound = "mysticism cast"}
end

local function grow()
    local camera = tes3.worldController.worldCamera.camera
    tes3.player.scale = tes3.player.scale + mushChange
    local newCamHeight = math.remap(tes3.player.scale, minScale, 1.0, initCameraDrop, 0)
    common.log:trace("newCamHeight: %s", newCamHeight)
    camera.translation = tes3vector3.new(0, 0,newCamHeight)

    tes3.playSound{ reference = tes3.player, sound = "Swallow"}
    growEffect()
    tes3.messageBox("You feel taller!")
end

local function resetPlayerSize()
    tes3.player.scale = 1
    local camera = tes3.worldController.worldCamera.camera
    camera.translation = tes3vector3.new(0, 0, 0)
end

local allowActivate
local function onKeyDown(e)
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if keyTest and target then
        local id = target.baseObject.id:lower()
        if id == mushroomId then
            if tes3.player.scale < maxScale then
                target:disable()
                grow()
            else
                tes3.messageBox("You've grown enough already!")
            end
        elseif id == orbId then
            if tes3.player.scale >= scaleNeeded then
                allowActivate = true
                tes3.player:activate(target)
                tes3.messageBox("You recieve the %s", target.object.name)
                resetPlayerSize()
                growEffect()
            else
                tes3.messageBox("The orb is too heavy, you need to get bigger!")
            end
        end
    end
end
event.register("keyDown", onKeyDown)

local function resetMushrooms(cell)
    for ref in cell:iterateReferences(tes3.objectType.activator) do
        if ref.baseObject.id:lower() == mushroomId then
            common.log:trace("mushy")
            if ref.disabled then
                ref:enable()
            end
        end
    end
end

local function enterCell(e)
    common.log:trace("previous: %s", e.previousCell)
    local camera = tes3.worldController.worldCamera.camera
    tes3.player.data[modName] = tes3.player.data[modName] or {}
    local data = tes3.player.data[modName]
    if e.cell.id == "Horavatha's Gauntlet, Reduction" then
        resetMushrooms(e.cell)
        --store previous values
        if not data.lastScale then
            data.lastScale = tes3.player.scale
        end
        --set scale
        tes3.player.scale = minScale
        --lower camera
        camera.translation = tes3vector3.new(0, 0, initCameraDrop)
        common.log:debug("updated camera and shrunk player")
    elseif e.previousCell and e.previousCell.id == "Horavatha's Gauntlet, Reduction" then
        --restore size
        tes3.player.scale = data.lastScale or 1
        camera.translation = tes3vector3.new(0,0,0)
        --clear data
        data.lastScale = nil
        common.log:debug("Restored previous size")
    end
end
event.register("cellChanged", enterCell)

local function onActivate(e)
    if tes3.player.cell.id == "Horavatha's Gauntlet, Reduction" then
        common.log:trace("in cell")
        if e.activator == tes3.player then
            common.log:trace("is player")
            if e.target.baseObject.id == orbId or e.target.baseObject.id == mushroomId then
                if allowActivate then
                    allowActivate = false
                else
                    common.log:debug("blocking activation")
                    return false
                end
            end
        end
    end
end
event.register("activate", onActivate)