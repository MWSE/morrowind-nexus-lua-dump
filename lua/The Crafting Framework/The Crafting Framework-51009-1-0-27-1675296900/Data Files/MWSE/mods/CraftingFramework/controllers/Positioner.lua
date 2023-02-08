local orienter = include("CraftingFramework.controllers.Orienter")
local Util = require("CraftingFramework.util.Util")
local config = require("CraftingFramework.config")
local decals = require('CraftingFramework.controllers.Decals')
local m1 = tes3matrix33.new()
local logger = Util.createLogger("Positioner")

local this = {
    maxReach = 100,
    minReach = 100,
    currentReach = 500,
    holdKeyTime = 0.75,
    rotateMode = false,
    verticalMode = 0,
    wallAlignMode = true
}
local const_epsilon = 0.001
local function wrapRadians(x)
    return x % (2 * math.pi)
end

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
    local menu = tes3ui.findHelpLayerMenu(this.id_guide)

    if (menu) then
        menu.visible = true
        menu:updateLayout()
        return
    end

    menu = tes3ui.createHelpLayerMenu{ id = this.id_guide, fixedFrame = true }
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
    this.shadow_model.appCulled = true
    this.lastItemOri = this.active.orientation:copy()

    if Util.isShiftDown() then
        this.active.position = this.itemInitialPos
        this.active.orientation = this.itemInitialOri
    end

    tes3.playSound{ sound = "Menu Click" }
    if this.active.baseObject.objectType == tes3.objectType.light then
        Util.removeLight(this.active.sceneNode)
        Util.onLight(this.active)
    end

    endPlacement()
end

local function doPinToWall()
    return config.persistent.placementSetting == settings.ground
        or this.pinToWall == true
end

-- Called every simulation frame to reposition the item.
local function simulatePlacement()
    this.maxReach = tes3.getPlayerActivationDistance()
    this.currentReach = math.min(this.currentReach, this.maxReach)
    if not this.active then
        return
    end
    -- Stop if player takes the object.
    if (this.active.deleted) then
        logger:debug("simulatePlacement: this.active is deleted, ending placement")
        endPlacement()
        return
    -- Check for glitches.
    elseif (this.active.sceneNode == nil) then
        logger:debug("simulatePlacement: sceneNode missing, ending placement")
        tes3.messageBox{ message = "Item location was lost. Placement reset."}
        this.active.position = this.itemInitialPos
        this.active.orientation = this.itemInitialOri
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

    local d_theta = tes3.player.orientation.z - this.playerLastOri.z
    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    this.shadow_model.appCulled = true
    this.active.sceneNode.appCulled = true

    local eyePos = tes3.getPlayerEyePosition()
    local eyeVec = tes3.getPlayerEyeVector()
    ---The position from the player's view to the max distance
    local lookPos = eyePos + eyeVec * this.currentReach
    logger:trace("eyePos: %s, eyeVec: %s, lookPos: %s", eyePos, eyeVec, lookPos)

    if this.offset == nil then
        logger:trace("this.offset is nil, setting to lookPos - active.position")
        this.offset = lookPos - this.active.position
    else
        m1:toRotationZ(d_theta)
    end
    logger:trace("this.offset: %s", this.offset)

    ---The position to place the object
    local targetPos = eyePos + eyeVec * this.currentReach - this.offset
    logger:trace("targetPos: %s", targetPos)

    if doPinToWall() then
        logger:trace("Pin to wall")
        local rayVec = (targetPos - eyePos):normalized()
        logger:trace("rayVec: %s", rayVec)
        local ray = tes3.rayTest{
            position = eyePos,
            direction = rayVec,
            ignore = { this.active, tes3.player },
            maxDistance = this.currentReach,
        }
        if ray then
            local width = math.min(this.boundMax.x - this.boundMin.x, this.boundMax.y - this.boundMin.y, this.boundMax.z - this.boundMin.z)
            logger:trace("width: %s", width)
            local distance = math.min(ray.distance, this.currentReach) - width
            logger:trace("distance: %s", distance)
            local diff = targetPos:distance(eyePos) - distance
            logger:trace("diff: %s", diff)
            targetPos = targetPos - rayVec * diff ---@diagnostic disable-line
            logger:trace("new targetPos: %s", targetPos)
        end

        local dropPos = targetPos:copy()
        local rayhit = tes3.rayTest{
            position = this.active.position - tes3vector3.new(0, 0, this.offset.z),
            direction = tes3vector3.new(0, 0, -1),
            ignore = { this.active, tes3.player }
        }
        if (rayhit ) then
            dropPos = rayhit.intersection:copy()
            targetPos.z = math.max(targetPos.z, dropPos.z + (this.height or 0) )
        end

    end

    --targetPos.z = targetPos.z + const_epsilon


    -- Incrementally rotate the same amount as the player, to keep relative alignment with player.

    this.playerLastOri = tes3.player.orientation:copy()
    if (this.rotateMode) then
        -- Use inputController, as the player orientation is locked.
        logger:debug("rotate mode is active")
        local mouseX = tes3.worldController.inputController.mouseState.x
        logger:debug("mouse x: %s", tes3.worldController.inputController.mouseState.x)
        d_theta = 0.001 * 15 * mouseX
    end

    --logger:debug("simulatePlacement: position: %s", pos)
    -- Update item and shadow spot.
    this.active.sceneNode.appCulled = false
    this.active.position = targetPos
    this.active.orientation.z = wrapRadians(this.active.orientation.z + d_theta)

    local doOrient = config.persistent.placementSetting == settings.ground

    if doOrient then
        orienter.orientRefToGround{ ref = this.active, mode = config.persistent.placementSetting }
        --logger:debug("simulatePlacement: orienting %s", this.active.orientation)
    else
        this.active.orientation = tes3vector3.new(0, 0, this.active.orientation.z)
    end
end

-- cellChanged event handler.
local function cellChanged(e)
    -- To avoid problems, reset item if moving in or out of an interior cell.
    if (this.active.cell.isInterior or e.cell.isInterior) then
        tes3.messageBox{ message = "You cannot move items between cells. Placement reset."}
        this.active.position = this.itemInitialPos
        this.active.orientation = this.itemInitialOri
        endPlacement()
    end
end


-- Match vertical mode from an orientation.
local function matchVerticalMode(orient)
    if (math.abs(orient.x) > 0.1) then
        local k = math.floor(0.5 + orient.z / (0.5 * math.pi))
        if (k == 0) then
            this.verticalMode = 1
            this.height = -this.boundMin.y
        elseif (k == -1) then
            this.verticalMode = 2
            this.height = -this.boundMin.x
        elseif (k == 2) then
            this.verticalMode = 3
            this.height = this.boundMax.y
        elseif (k == 1) then
            this.verticalMode = 4
            this.height = this.boundMax.x
        end
    else
        this.verticalMode = 0
        this.height = -this.boundMin.z
    end
end


local function toggleBlockActivate()
    event.trigger("BlockScriptedActivate", { doBlock = true })
    timer.delayOneFrame(function()
        event.trigger("BlockScriptedActivate", { doBlock = false })
    end)
end


-- On grabbing / dropping an item.
this.togglePlacement = function(e)
    this.maxReach = tes3.getPlayerActivationDistance()
    e = e or { target = nil }
    --init settings
    this.pinToWall = e.pinToWall or false
    this.blockToggle = e.blockToggle or false

    config.persistent.placementSetting = config.persistent.placementSetting or "ground"
    logger:debug("togglePlacement")
    toggleBlockActivate()
    if this.active then
        logger:debug("togglePlacement: isActive, calling finalPlacement()")
        finalPlacement()
        return
    end

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
            ignore = { tes3.player },
            maxDistance = this.maxReach,
            root = config.persistent.placementSetting == "ground"
                and tes3.game.worldLandscapeRoot or nil
        })

        target = ray and ray.reference
        if target and ray then
            logger:debug("togglePlacement: ray found target, doing reach stuff")
            this.offset = target.position - ray.intersection
            this.currentReach = ray and math.min(ray.distance, this.maxReach)
        end
    else
        logger:debug("togglePlacement: e.target, doing reach stuff")
        target = e.target
        local dist = target.position:distance(tes3.getPlayerEyePosition())
        this.currentReach = math.min(dist, this.maxReach)
        this.offset = nil
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

    -- if target.position:distance(tes3.player.position) > this.maxReach  then
    --     logger:debug("togglePlacement: out of reach, return")
    --     return
    -- end

    -- Workaround to avoid dupe-on-load bug when moving non-persistent refs into another cell.
    if (target.sourceMod and not target.cell.isInterior) then
        tes3.messageBox{ message = "You must pick up and drop this item first." }
        return
    end

    logger:debug("togglePlacement: passed checks, setting position variables")

    -- Calculate effective bounds including scale.
    this.boundMin = target.object.boundingBox.min * target.scale
    this.boundMax = target.object.boundingBox.max * target.scale
    matchVerticalMode(target.orientation)

    -- Get exact ray to selection point, relative to 1st person camera.
    local eye = tes3.getPlayerEyePosition()
    local basePos = target.position - tes3vector3.new(0, 0, this.height or 0)
    this.ray = tes3.worldController.armCamera.cameraRoot.worldTransform.rotation:transpose() * (basePos - eye)
    this.playerLastOri = tes3.player.orientation:copy()
    this.itemInitialPos = target.position:copy()
    this.itemInitialOri = target.orientation:copy()
    this.orientation = target.orientation:copy()


    this.active = target
    this.active.hasNoCollision = true
    decals.applyDecals(this.active, config.persistent.placementSetting)
    tes3.playSound{ sound = "Menu Click" }

    event.register("cellChanged", cellChanged)
    tes3ui.suppressTooltip(true)

    logger:debug("togglePlacement: showing guide")
    showGuide()

    config.persistent.positioningActive = true
    event.register("simulate", simulatePlacement)
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
    if (this.matchTimer) then
        this.matchTimer:cancel()
    end
    recreateRef(this.active)
    decals.applyDecals(this.active)
    event.unregister("simulate", simulatePlacement)
    event.unregister("cellChanged", cellChanged)
    tes3ui.suppressTooltip(false)
    local ref = this.active
    this.active.hasNoCollision = false
    this.active = nil
    this.rotateMode = nil
    tes3.mobilePlayer.mouseLookDisabled = false

    local menu = tes3ui.findHelpLayerMenu(this.id_guide)
    if (menu) then
        menu:destroy()
    end
    timer.delayOneFrame(function()timer.delayOneFrame(function()
        config.persistent.positioningActive = nil
    end)end)
    event.trigger("CraftingFramework:EndPlacement", { reference = ref })
end


-- End placement on load game. this.active would be invalid after load.
local function onLoad()
    if (this.active) then
        endPlacement()
    end
end

local function rotateKeyDown(e)
    if (this.active) then
        if (e.keyCode == config.mcm.keybindRotate.keyCode) then
            logger:debug("rotateKeyDown")
            this.rotateMode = true
            tes3.mobilePlayer.mouseLookDisabled = true
            return false
        end
    end
end

local function rotateKeyUp(e)
    if (this.active) then
        if (e.keyCode == config.mcm.keybindRotate.keyCode) then
            logger:debug("rotateKeyUp")
            this.rotateMode = false
            tes3.mobilePlayer.mouseLookDisabled = false
        end
    end
end

local function toggleMode(e)
    if not config.persistent then return end
    if this.blockToggle then return end
    this.shadow_model = tes3.loadMesh("craftingFramework/shadow.nif")
    if (config.persistent.positioningActive) then
        if (e.keyCode == config.mcm.keybindModeCycle.keyCode) then

            local cycle = {
                [settings.free] = settings.ground,
                [settings.ground] = settings.free
            }

            config.persistent.placementSetting = cycle[config.persistent.placementSetting]
            if this.active then
                decals.applyDecals(this.active, config.persistent.placementSetting)
            end
            tes3.playSound{ sound = "Menu Click" }

        end
    end
end

local function onInitialized()
    this.shadow_model = tes3.loadMesh("craftingFramework/shadow.nif")

    this.id_guide = tes3ui.registerID("ObjectPlacement:GuideMenu")
    event.register("load", onLoad)
    event.register("keyDown", rotateKeyDown, { priority = -100})
    event.register("keyUp", rotateKeyUp)
    event.register("keyDown", toggleMode)

end
event.register("initialized", onInitialized)


local function onMouseScroll(e)
    if this.active then
        local multi = Util.isShiftDown() and 0.02 or 0.1
        local change = multi * e.delta
        local newMaxReach = math.clamp(this.currentReach + change, this.minReach, this.maxReach)
        this.currentReach = newMaxReach
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
            this.togglePlacement()
        end
    end
end
event.register("keyDown", onActiveKey, { priority = 100 })


this.startPositioning = function(e)
    -- Put those hands away.
    if (tes3.mobilePlayer.weaponReady) then
        tes3.mobilePlayer.weaponReady = false
    elseif (tes3.mobilePlayer.castReady) then
        tes3.mobilePlayer.castReady = false
    end
    if e.placementSetting then
        config.persistent.placementSetting = e.placementSetting
    end
    this.togglePlacement(e)
end

event.register("CraftingFramework:startPositioning", function(e)
    this.startPositioning(e)
end)

return this


