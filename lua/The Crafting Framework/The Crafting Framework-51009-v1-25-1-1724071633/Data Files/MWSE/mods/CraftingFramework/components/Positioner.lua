local orienter = include("CraftingFramework.components.Orienter")
local Util = require("CraftingFramework.util.Util")
local config = require("CraftingFramework.config")
local decals = require('CraftingFramework.components.Decals')
local m1 = tes3matrix33.new()
local logger = Util.createLogger("Positioner")

---@class CraftingFramework.Positioner
local Positioner = {
    maxReach = 100,
    minReach = 100,
    currentReach = 500,
    holdKeyTime = 0.75,
    rotateMode = false,
    verticalMode = 0,
    wallAlignMode = true
}
local function wrapRadians(x)
    return x % (2 * math.pi)
end

---@alias CraftingFramework.Positioner.PlacementSetting
---| '"free"' #Free placement
---| '"ground"' #Ground placement

local settings = {
    free = 'free',
    ground = 'ground'
}
local endPlacement

local function isPlaceable(target)
    return target.data.crafted
end

local function getKeybindName(scancode)
    return tes3.findGMST(tes3.gmst.sKeyName_00 + scancode).value
end
-- Show keybind help overlay.
local function showGuide()
    local menu = tes3ui.findHelpLayerMenu(Positioner.id_guide)

    if (menu) then
        menu.visible = true
        menu:updateLayout()
        return
    end

    menu = tes3ui.createHelpLayerMenu{ id = Positioner.id_guide, fixedFrame = true }
    menu:destroyChildren()
    menu.disabled = true
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.04
    menu.color = {0, 0, 0}
    menu.alpha = 0.8
    menu.width = 330
    menu.autoWidth = false
    menu.autoHeight = true
    menu.paddingAllSides = 12
    menu.paddingLeft = 16
    menu.paddingRight = 16
    menu.flowDirection = "top_to_bottom"

    local function addLine(line, verb, scancode)
        local row = menu:createBlock{}
        row.widthProportional = 1.0
        row.autoHeight = true
        row.borderTop = 9
        row.borderBottom = 9
        row:createLabel{ text = line }
        local bind = row:createLabel{ text = verb .. getKeybindName(scancode) }
        bind.absolutePosAlignX = 1.0
    end

    addLine("Rotate", "Hold ", config.mcm.keybindRotate.keyCode)
    addLine("Cycle Drop Mode", "Press ", config.mcm.keybindModeCycle.keyCode)
    menu:updateLayout()

end

local function finalPlacement()
    logger:debug("finalPlacement()")
    Positioner.shadow_model.appCulled = true
    Positioner.lastItemOri = Positioner.active.orientation:copy()

    if Util.isShiftDown() then
        Positioner.active.position = Positioner.itemInitialPos
        Positioner.active.orientation = Positioner.itemInitialOri
    end

    tes3.playSound{ sound = "Menu Click" }
    if Positioner.active.baseObject.objectType == tes3.objectType.light then
        Util.removeLight(Positioner.active.sceneNode)
        Util.onLight(Positioner.active)
    end

    endPlacement()
end

local function doPinToWall()
    return config.persistent.placementSetting == settings.ground
        or Positioner.pinToWall == true
end

local function getWidth()
    if not (Positioner and Positioner.boundMax) then
        return 0
    end
    return math.min(Positioner.boundMax.x - Positioner.boundMin.x, Positioner.boundMax.y - Positioner.boundMin.y)
end

---@param ref tes3reference
local function getMinWidth(ref)
    ref = ref or Positioner.active
    return math.min(ref.object.boundingBox.max.x - ref.object.boundingBox.min.x,
                    ref.object.boundingBox.max.y - ref.object.boundingBox.min.y,
                    ref.object.boundingBox.max.z - ref.object.boundingBox.min.z)
            * ref.scale
end


-- Called every simulation frame to reposition the item.
local function simulatePlacement()
    if not Positioner.active then
        return
    end
    Positioner.maxReach = tes3.getPlayerActivationDistance() + getWidth()
    Positioner.currentReach = math.min(Positioner.currentReach, Positioner.maxReach)

    -- Stop if player takes the object.
    if (Positioner.active.deleted) then
        logger:debug("simulatePlacement: Positioner.active is deleted, ending placement")
        endPlacement()
        return
    -- Check for glitches.
    elseif (Positioner.active.sceneNode == nil) then
        logger:debug("simulatePlacement: sceneNode missing, ending placement")
        tes3.messageBox{ message = "Item location was lost. Placement reset."}
        Positioner.active.position = Positioner.itemInitialPos
        Positioner.active.orientation = Positioner.itemInitialOri
        endPlacement()
        return
    -- Drop item if player readies combat or casts a spell.
    elseif (tes3.mobilePlayer.weaponReady) then
        logger:debug("simulatePlacement: weapon ready, drop active")
        finalPlacement()
        return
    --Drop item if no longer able to manipulate
    elseif not config.persistent.positioningActive then
        logger:debug("simulatePlacement: not positioningActive, drop active")
        finalPlacement()
        return
    end

    local d_theta = tes3.player.orientation.z - Positioner.playerLastOri.z
    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    Positioner.shadow_model.appCulled = true
    Positioner.active.sceneNode.appCulled = true

    local eyePos = tes3.getPlayerEyePosition()
    local eyeVec = tes3.getPlayerEyeVector()

    ---The position from the player's view to the max distance
    local lookPos = eyePos + eyeVec * Positioner.currentReach
    logger:trace("eyePos: %s, eyeVec: %s, lookPos: %s", eyePos, eyeVec, lookPos)

    if Positioner.offset == nil then
        logger:trace("Positioner.offset is nil, setting to lookPos - active.position")
        Positioner.offset = lookPos - Positioner.active.position
    else
        m1:toRotationZ(d_theta)
    end
    logger:trace("Positioner.offset: %s", Positioner.offset)

    ---The position to place the object
    ---@type any
    local targetPos = eyePos + eyeVec * Positioner.currentReach - Positioner.offset
    logger:trace("targetPos: %s", targetPos)

    if doPinToWall() then
        logger:trace("Pin to wall")
        local rayVec = (targetPos - eyePos):normalized()
        logger:trace("rayVec: %s", rayVec)
        local ray = tes3.rayTest{
            position = eyePos,
            direction = rayVec,
            ignore = { Positioner.active, tes3.player },
            maxDistance = Positioner.currentReach,
            accurateSkinned = true,
        }
        if ray and ray.intersection then
            local width = getWidth()
            logger:trace("width: %s", width)
            local vertDistance = math.min(ray.distance, Positioner.currentReach) + Positioner.boundMin.z
            local horiDistance = math.min(ray.distance, Positioner.currentReach)

            local vertDiff = targetPos:distance(eyePos) - vertDistance
            local horiDiff = targetPos:distance(eyePos) - horiDistance

            local newPos = targetPos - rayVec * horiDiff
            newPos.z = (targetPos - rayVec * vertDiff).z
            targetPos = newPos

            ---@cast targetPos tes3vector3
            logger:trace("new targetPos: %s", targetPos)
        end
    end


    if Positioner.doFloat then
        local waterLevel = Positioner.active.cell.waterLevel
        if waterLevel and targetPos.z < waterLevel then
            targetPos.z = waterLevel - Positioner.floatOffset
        end
    end

    -- Incrementally rotate the same amount as the player, to keep relative alignment with player.
    Positioner.playerLastOri = tes3.player.orientation:copy()
    if (Positioner.rotateMode) then
        -- Use inputController, as the player orientation is locked.
        logger:trace("rotate mode is active")
        local mouseX = tes3.worldController.inputController.mouseState.x
        logger:trace("mouse x: %s", tes3.worldController.inputController.mouseState.x)
        d_theta = 0.001 * 15 * mouseX
    end

    Positioner.active.sceneNode.appCulled = false
    Positioner.active.position = targetPos
    Positioner.active.orientation = tes3vector3.new(0, 0, wrapRadians(Positioner.active.orientation.z + d_theta))


    local doOrient = config.persistent.placementSetting == settings.ground
    if doOrient then
        if orienter.orientRefToGround{
            ref = Positioner.active,
            maxVerticalDistance = (Positioner.boundMax.z-Positioner.boundMin.z),
            doFloat = Positioner.doFloat,
            floatOffset = Positioner.floatOffset
        } then
            return
        end
    end
    Positioner.active.orientation = tes3vector3.new(0, 0, Positioner.active.orientation.z)
end

-- cellChanged event handler.
local function cellChanged(e)
    -- To avoid problems, reset item if moving in or out of an interior cell.
    if (Positioner.active.cell.isInterior or e.cell.isInterior) then
        tes3.messageBox{ message = "You cannot move items between cells. Placement reset."}
        Positioner.active.position = Positioner.itemInitialPos
        Positioner.active.orientation = Positioner.itemInitialOri
        endPlacement()
    end
end

-- Match vertical mode from an orientation.
local function matchVerticalMode(orient)
    if (math.abs(orient.x) > 0.1) then
        local k = math.floor(0.5 + orient.z / (0.5 * math.pi))
        if (k == 0) then
            Positioner.verticalMode = 1
            Positioner.height = -Positioner.boundMin.y
        elseif (k == -1) then
            Positioner.verticalMode = 2
            Positioner.height = -Positioner.boundMin.x
        elseif (k == 2) then
            Positioner.verticalMode = 3
            Positioner.height = Positioner.boundMax.y
        elseif (k == 1) then
            Positioner.verticalMode = 4
            Positioner.height = Positioner.boundMax.x
        end
    else
        Positioner.verticalMode = 0
        Positioner.height = -Positioner.boundMin.z
    end
end


local function toggleBlockActivate()
    event.trigger("BlockScriptedActivate", { doBlock = true })
    timer.delayOneFrame(function()
        event.trigger("BlockScriptedActivate", { doBlock = false })
    end)
end


-- On grabbing / dropping an item.
Positioner.togglePlacement = function(e)
    Positioner.maxReach = tes3.getPlayerActivationDistance() + getWidth()
    e = e or { target = nil }

    config.persistent.placementSetting = config.persistent.placementSetting or "ground"
    logger:debug("togglePlacement")
    toggleBlockActivate()
    if Positioner.active then
        logger:debug("togglePlacement: isActive, calling finalPlacement()")
        finalPlacement()
        return
    end

    --init settings
    Positioner.pinToWall = e.pinToWall or false
    Positioner.blockToggle = e.blockToggle or false
    Positioner.doFloat = e.doFloat or false
    Positioner.floatOffset = e.floatOffset or 0

    local target
    if not e.target then
        logger:debug("togglePlacement: no target")
        if tes3.menuMode() then
            logger:debug("togglePlacement: menuMode, return")
            return
        end
        local ray = tes3.rayTest({
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector(),
            ignore = { tes3.player, Positioner.active },
            maxDistance = Positioner.maxReach,
            root = config.persistent.placementSetting == "ground"
                and tes3.game.worldLandscapeRoot or nil,
            accurateSkinned = true,
        })

        target = ray and ray.reference
        if target and ray then
            logger:debug("togglePlacement: ray found target, doing reach stuff")
            Positioner.offset = target.position - ray.intersection
            Positioner.currentReach = ray and math.min(ray.distance, Positioner.maxReach)
        end
    else
        logger:debug("togglePlacement: e.target, doing reach stuff")
        target = e.target
        local dist = target.position:distance(tes3.getPlayerEyePosition())
        Positioner.currentReach = math.min(dist, Positioner.maxReach)
        Positioner.offset = nil
    end

    if not target then
        logger:debug("togglePlacement: no e.target or ray target, return")
        return
    end

    -- Filter by allowed object type.
    if not (isPlaceable(target) or e.nonCrafted ) then
        logger:debug("togglePlacement: not placeable")
        return
    end

    -- if target.position:distance(tes3.player.position) > Positioner.maxReach  then
    --     logger:debug("togglePlacement: out of reach, return")
    --     return
    -- end

    -- Workaround to avoid dupe-on-load bug when moving non-persistent refs into another cell.
    if (target.sourceMod and not target.cell.isInterior) then
        tes3.messageBox{ message = "You must pick up and drop Positioner item first." }
        return
    end

    logger:debug("togglePlacement: passed checks, setting position variables")

    -- Calculate effective bounds including scale.
    Positioner.boundMin = target.object.boundingBox.min * target.scale
    Positioner.boundMax = target.object.boundingBox.max * target.scale
    matchVerticalMode(target.orientation)

    -- Get exact ray to selection point, relative to 1st person camera.
    local eye = tes3.getPlayerEyePosition()
    local basePos = target.position - tes3vector3.new(0, 0, Positioner.height or 0)
    Positioner.ray = tes3.worldController.armCamera.cameraRoot.worldTransform.rotation:transpose() * (basePos - eye)
    Positioner.playerLastOri = tes3.player.orientation:copy()
    Positioner.itemInitialPos = target.position:copy()
    Positioner.itemInitialOri = target.orientation:copy()
    Positioner.orientation = target.orientation:copy()


    Positioner.active = target
    Positioner.active.hasNoCollision = true
    decals.applyDecals(Positioner.active, config.persistent.placementSetting)
    tes3.playSound{ sound = "Menu Click" }

    event.register("cellChanged", cellChanged)
    tes3ui.suppressTooltip(true)

    logger:debug("togglePlacement: showing guide")
    showGuide()

    config.persistent.positioningActive = true
    event.register("simulate", simulatePlacement)

    event.trigger("CraftingFramework:StartPlacement", { reference = target })
end

---@param from tes3reference
---@param to tes3reference
local function copyRefData(from, to)
    if from.data then
        for k, v in pairs(from.data) do
            to.data[k] = v
        end
    end
end

---@param ref tes3reference
local function recreateRef(ref)
    ref:disable()
    ref:enable()
end

--pre-declared above
endPlacement = function()
    logger:debug("endPlacement()")
    --if ground mode, drop to ground
    if config.persistent.placementSetting == "ground" then
        logger:warn("doFloat: %s, floatOffset: %s"
            , Positioner.doFloat, Positioner.floatOffset)
        orienter.orientRefToGround{
            ref = Positioner.active,
            doFloat = Positioner.doFloat,
            floatOffset = Positioner.floatOffset
        }
    end

    recreateRef(Positioner.active)
    decals.applyDecals(Positioner.active)
    event.unregister("simulate", simulatePlacement)
    event.unregister("cellChanged", cellChanged)
    tes3ui.suppressTooltip(false)
    local ref = Positioner.active
    Positioner.active.hasNoCollision = false
    Positioner.active = nil
    Positioner.rotateMode = nil
    tes3.mobilePlayer.mouseLookDisabled = false

    local menu = tes3ui.findHelpLayerMenu(Positioner.id_guide)
    if (menu) then
        menu:destroy()
    end
    timer.delayOneFrame(function()timer.delayOneFrame(function()
        config.persistent.positioningActive = nil
    end)end)
    event.trigger("CraftingFramework:EndPlacement", { reference = ref })
end


-- End placement on load game. Positioner.active would be invalid after load.
local function onLoad()
    if (Positioner.active) then
        endPlacement()
    end
end

local function rotateKeyDown(e)
    if (Positioner.active) then
        if (e.keyCode == config.mcm.keybindRotate.keyCode) then
            logger:debug("rotateKeyDown")
            Positioner.rotateMode = true
            tes3.mobilePlayer.mouseLookDisabled = true
            return false
        end
    end
end

local function rotateKeyUp(e)
    if (Positioner.active) then
        if (e.keyCode == config.mcm.keybindRotate.keyCode) then
            logger:debug("rotateKeyUp")
            Positioner.rotateMode = false
            tes3.mobilePlayer.mouseLookDisabled = false
        end
    end
end

local function toggleMode(e)
    if not config.persistent then return end
    if Positioner.blockToggle then return end
    Positioner.shadow_model = tes3.loadMesh("craftingFramework/shadow.nif")
    if (config.persistent.positioningActive) then
        if (e.keyCode == config.mcm.keybindModeCycle.keyCode) then

            local cycle = {
                [settings.free] = settings.ground,
                [settings.ground] = settings.free
            }

            config.persistent.placementSetting = cycle[config.persistent.placementSetting]
            if Positioner.active then
                decals.applyDecals(Positioner.active, config.persistent.placementSetting)
            end
            tes3.playSound{ sound = "Menu Click" }

        end
    end
end

local function onInitialized()
    Positioner.shadow_model = tes3.loadMesh("craftingFramework/shadow.nif")

    Positioner.id_guide = tes3ui.registerID("ObjectPlacement:GuideMenu")
    event.register("load", onLoad)
    event.register("keyDown", rotateKeyDown, { priority = -100})
    event.register("keyUp", rotateKeyUp)
    event.register("keyDown", toggleMode)

end
event.register("initialized", onInitialized)


local function onMouseScroll(e)
    if Positioner.active then
        local multi = Util.isShiftDown() and 0.02 or 0.1
        local change = multi * e.delta
        local newMaxReach = math.clamp(Positioner.currentReach + change, Positioner.minReach, Positioner.maxReach)
        Positioner.currentReach = newMaxReach
    end
end
event.register("mouseWheel", onMouseScroll)


local function blockActivation(e)
    logger:debug("blockActivation")
    if config.persistent.positioningActive then
        logger:debug("Positioning Active")
        return (e.activator ~= tes3.player)
    end
end
event.register("activate", blockActivation, { priority = 500 })


local function onActiveKey(e)
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if keyTest then
        if config.persistent.positioningActive then
            Positioner.togglePlacement()
        end
    end
end
event.register("keyDown", onActiveKey, { priority = 100 })


---@class Positioner.startPositioning.params
---@field target tes3reference
---@field nonCrafted? boolean
---@field pinToWall? boolean
---@field placementSetting? CraftingFramework.Positioner.PlacementSetting
---@field blockToggle? boolean
---@field doFloat? boolean
---@field floatOffset? number

---@param e Positioner.startPositioning.params
Positioner.startPositioning = function(e)
    -- Put those hands away.
    if (tes3.mobilePlayer.weaponReady) then
        tes3.mobilePlayer.weaponReady = false
    elseif (tes3.mobilePlayer.castReady) then
        tes3.mobilePlayer.castReady = false
    end
    if e.placementSetting then
        config.persistent.placementSetting = e.placementSetting
    end
    Positioner.togglePlacement(e)
end

event.register("CraftingFramework:startPositioning", function(e)
    Positioner.startPositioning(e)
end)

return Positioner
