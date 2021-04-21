--[[
	Mod: Perfect Placement
	Author: Hrnchamd
    Version: 1.0
]]--

-- Version check
if (mwse.buildDate == nil or mwse.buildDate < 20190416) then
	mwse.log("[Perfect Placement] Build date of %s does not meet minimum build date of 20190416.", mwse.buildDate)
	return
end

local configId = "Perfect Placement"
local config = mwse.loadConfig(configId)
if (config == nil) then
	config = {
        keybind = 34,
        keybindRotate = 42,
        keybindSnap = 54,
        keybindVertical = 56,
        keybindWallAlign = 53,
        sensitivity = 15,
        showGuide = true,
        snapN = 1
	}
end

local this = {
    maxReach = 1.2,
    holdKeyTime = 0.75,
    rotateMode = false,
    snapMode = false,
    verticalMode = 0,
    wallAlignMode = true
}

local const_epsilon = 0.001

local placeableTypes = {
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.ammunition] = true,
    [tes3.objectType.apparatus] = true,
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.ingredient] = true,
    [tes3.objectType.light] = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.miscItem] = true,
    [tes3.objectType.probe] = true,
    [tes3.objectType.repairItem] = true,
    [tes3.objectType.weapon] = true,
}

local endPlacement

local function wrapRadians(x)
    return x % (2 * math.pi)
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
        local text = row:createLabel{ text = line }
        local bind = row:createLabel{ text = verb .. getKeybindName(scancode) }
        bind.absolutePosAlignX = 1.0
    end
    
    addLine("Rotate item", "Hold ", config.keybindRotate)
    addLine("Vertical mode cycle", "", config.keybindVertical)
    addLine("Match last placed item", "Hold ", config.keybindVertical)
    addLine("Snap rotation toggle", "", config.keybindSnap)
    addLine("Snap to vertical surface toggle", "", config.keybindWallAlign)
    addLine("Drop item", "", config.keybind)

    menu:updateLayout()
end

-- Called to confirm final placement, drops item to ground if not attaching to wall.
local function finalPlacement()
    this.shadow_model.appCulled = true
    this.lastItemOri = this.active.orientation:copy()

    if (not this.wallMount) then
        -- Drop to ground.
        this.active.sceneNode.appCulled = true
        local from = this.active.position + tes3vector3.new(0, 0, -this.height + const_epsilon)
        local rayhit = tes3.rayTest{ position = from, direction = tes3vector3.new(0, 0, -1) }
        this.active.sceneNode.appCulled = false

        if (rayhit) then
            this.active.position = rayhit.intersection + tes3vector3.new(0, 0, this.height + const_epsilon)
        end
    end
    
    tes3.playItemPickupSound{ item = this.active.object, pickup = false }
    endPlacement()
end

-- Called every simulation frame to reposition the item.
local function simulatePlacement(e)
    -- Stop if player takes the object.
    if (this.active.deleted) then
        endPlacement()
        return
    -- Check for glitches.
    elseif (this.active.sceneNode == nil) then
        tes3.messageBox{ message = "Item location was lost. Placement reset."}
        this.active.position = this.itemInitialPos
        this.active.orientation = this.itemInitialOri
        endPlacement()
        return
    -- Drop item if player readies combat or casts a spell.
    elseif (tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.castReady or tes3.mobilePlayer.actionData.animationAttackState > 1) then
        finalPlacement()
        return
    end

    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    this.shadow_model.appCulled = true
    this.active.sceneNode.appCulled = true
    local ray = tes3.worldController.armCamera.cameraRoot.worldTransform.rotation * this.ray
    local eye = tes3.player.position + tes3vector3.new(0, 0, 128)
    local rayhit = tes3.rayTest{ position = eye, direction = ray, maxDistance = 800 }
    
    -- Limit holding distance to a maxReach * initial distance.
    local pos
    if (rayhit and rayhit.distance <= this.maxReach) then
        pos = rayhit.intersection:copy()
    else
        pos = eye + ray * this.maxReach
    end
    -- Add epsilon to ensure the intersection is not inside the model during to floating point precision.
    pos.z = pos.z + const_epsilon

    -- Vertical mode handling.
    this.wallMount = false
    if (this.verticalMode > 0) then
        -- Check if the bottom of the model is close to other geometry.
        local clearance = math.max(2, -this.boundMin.z)
        ray = tes3vector3.new(clearance * math.sin(this.orientation.y), clearance * math.cos(this.orientation.y), 0)
        rayhit = tes3.rayTest{ position = pos + ray * -const_epsilon, direction = ray, maxDistance = 2, returnNormal = true }
        
        if (rayhit and rayhit.distance < 1) then
            -- Place at minimum distance outside wall, and optionally align rotation with normal.
            pos = rayhit.intersection - ray
            if (this.wallAlignMode and math.abs(rayhit.normal.z) < 0.2) then
                this.orientation.y = math.atan2(-rayhit.normal.x, -rayhit.normal.y)
            end
            this.wallMount = true
        end
    end

    -- Find drop position for shadow spot.
    local dropPos = pos:copy()
    rayhit = tes3.rayTest{ position = pos, direction = tes3vector3.new(0, 0, -1) }
    if (rayhit) then
        dropPos = rayhit.intersection:copy()
    end

    -- Get object centre from base point
    pos.z = pos.z + this.height

    -- Incrementally rotate the same amount as the player, to keep relative alignment with player.
    local d_theta = tes3.player.orientation.z - this.playerLastOri.z
    this.playerLastOri = tes3.player.orientation:copy()
    if (this.rotateMode) then
        -- Use inputController, as the player orientation is locked.
        d_theta = 0.001 * config.sensitivity * tes3.worldController.inputController.mouseState.x
    end

    -- Apply rotation.
    if (this.verticalMode == 0) then
        this.orientation.z = wrapRadians(this.orientation.z + d_theta)
    else
        this.orientation.y = wrapRadians(this.orientation.y + d_theta)
    end

    -- Rotation snap.
    local orient = this.orientation:copy()
    if (this.snapMode) then
        local quantizer = (0.5 / config.snapN) * math.pi
        if (this.verticalMode == 0) then
            orient.z = quantizer * math.floor(0.5 + orient.z / quantizer)
        else
            orient.y = quantizer * math.floor(0.5 + orient.y / quantizer)
        end
    end

    -- Update item and shadow spot.
    this.active.sceneNode.appCulled = false
    this.active.position = pos
    this.active.orientation = orient
    this.shadow_model.appCulled = false
    this.shadow_model.translation = dropPos
    this.shadow_model:propagatePositionChange()
end

-- activate event while holding an item.
local function onActivate(e)
    -- Prevent player from activating anything.
    return (e.activator ~= tes3.player)
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

-- Set rotation frame and effective height for vertical modes.
local function setVerticalMode(n)
    local prevHeight = this.height
    local orient = this.orientation
    orient.x = -0.5 * math.pi
    orient.y = tes3.player.orientation.z
    
    if (n == 1) then
        orient.z = 0
        this.height = -this.boundMin.y
    elseif (n == 2) then
        orient.z = -0.5 * math.pi
        this.height = -this.boundMin.x
    elseif (n == 3) then
        orient.z = math.pi
        this.height = this.boundMax.y
    elseif (n == 4) then
        orient.z = 0.5 * math.pi
        this.height = this.boundMax.x
    end
    
    this.position = this.position + tes3vector3.new(0, 0, this.height - prevHeight)
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

-- Copy orientation event handler.
local function copyLastOri()
    if (this.lastItemOri) then
        this.orientation = this.lastItemOri:copy()
        matchVerticalMode(this.orientation)
    end
end

-- On grabbing / dropping an item.
local function activatePlacement(e)
    local target = tes3.getPlayerTarget()

    -- Do not active in menu mode and during attacking/casting.
    if (tes3.menuMode() or tes3.mobilePlayer.actionData.animationAttackState > 1) then
        return
    end
    
    if (this.active) then
        -- Drop item.
        finalPlacement()
    elseif (target) then
        -- Filter by allowed object type.
        if (not placeableTypes[target.object.objectType]) then
            return
        end
        -- Ownership test.
        local itemdata = target.attachments.variables
        if (itemdata and itemdata.owner) then
            local owner = itemdata.owner
            if (owner.objectType == tes3.objectType.faction and owner.playerJoined and owner.playerRank >= itemdata.requirement) then
                -- Player has sufficient faction rank.
            else
                tes3.messageBox{ message = "This item is owned by someone." }
                return
            end
        end
        -- Workaround to avoid dupe-on-load bug when moving non-persistent refs into another cell.
        if (target.sourceMod and not target.cell.isInterior) then
            tes3.messageBox{ message = "You must pick up and drop this item first." }
            return
        end

        -- Put those hands away.
        if (tes3.mobilePlayer.weaponReady) then
            tes3.mobilePlayer.weaponReady = false
        elseif (tes3.mobilePlayer.castReady) then
            tes3.mobilePlayer.castReady = false
        end

        -- Calculate effective bounds including scale.
        this.boundMin = target.object.boundingBox.min * target.scale
        this.boundMax = target.object.boundingBox.max * target.scale
        matchVerticalMode(target.orientation)

        -- Get exact ray to selection point, relative to 1st person camera.
        local eye = tes3.player.position + tes3vector3.new(0, 0, 128)
        local basePos = target.position - tes3vector3.new(0, 0, this.height)
        this.ray = tes3.worldController.armCamera.cameraRoot.worldTransform.rotation:transpose() * (basePos - eye)
        this.playerLastOri = tes3.player.orientation:copy()
        this.itemInitialPos = target.position:copy()
        this.itemInitialOri = target.orientation:copy()
        this.orientation = target.orientation:copy()

        this.active = target
        tes3.playItemPickupSound{ item = target.object }

        -- Add shadow spot to scene.
        tes3.dataHandler.worldObjectRoot:attachChild(this.shadow_model)
        this.shadow_model.appCulled = false
        this.shadow_model.translation = basePos + tes3vector3.new(0, 0, const_epsilon)
        this.shadow_model:propagatePositionChange()

        event.register("simulate", simulatePlacement)
        event.register("activate", onActivate)
        event.register("cellChanged", cellChanged)
        tes3ui.suppressTooltip(true)
        
        if (config.showGuide) then
            showGuide()
        end
    end
end

-- Clean up placement.
endPlacement = function()
    if (this.matchTimer) then
        this.matchTimer:cancel()
    end
    
    event.unregister("simulate", simulatePlacement)
    event.unregister("activate", onActivate)
    event.unregister("cellChanged", cellChanged)
    tes3ui.suppressTooltip(false)
    
    this.active = nil
    this.rotateMode = nil
    -- this.snapMode is persistent
    this.verticalMode = 0
    -- this.wallAlignMode is persistent
    this.shadow_model.appCulled = true
    tes3.mobilePlayer.mouseLookDisabled = false
    
    local menu = tes3ui.findHelpLayerMenu(this.id_guide)
    if (menu) then
        menu:destroy()
    end
end

-- End placement on load game. this.active would be invalid after load.
local function onLoad(e)
    if (this.active) then
        endPlacement()
    end
end

local function modeKeyDown(e)
    if (e.keyCode == config.keybind) then
        activatePlacement(e)
    elseif (this.active) then
        if (e.keyCode == config.keybindRotate) then
            this.rotateMode = true
            tes3.mobilePlayer.mouseLookDisabled = true
        elseif (e.keyCode == config.keybindSnap) then
            this.snapMode = not this.snapMode
        elseif (e.keyCode == config.keybindVertical) then
            this.matchTimer = timer.start({ duration = this.holdKeyTime, callback = copyLastOri })            

            this.verticalMode = this.verticalMode + 1

            if (this.verticalMode <= 4) then
                setVerticalMode(this.verticalMode)
            else
                this.orientation = tes3.player.orientation:copy()
                this.height = -this.boundMin.z
                this.verticalMode = 0
            end
        elseif (e.keyCode == config.keybindWallAlign) then
            this.wallAlignMode = not this.wallAlignMode
        end
    end
end

local function modeKeyUp(e)
    if (this.active) then
        if (e.keyCode == config.keybindVertical) then
            this.matchTimer:cancel()
        elseif (e.keyCode == config.keybindRotate) then
            this.rotateMode = false
            tes3.mobilePlayer.mouseLookDisabled = false
        end
    end
end

local function keybindUpdate()
    local menu = tes3ui.findHelpLayerMenu(this.id_guide)
    if (menu) then
        menu:destroy()
        showGuide()
    end
end

local function onInitialized(mod)
    local w = tes3.worldController.weatherController
    this.shadow_model = tes3.loadMesh("hrn/shadow.nif")

    this.id_guide = tes3ui.registerID("ObjectPlacement:GuideMenu")
    event.register("load", onLoad)
    event.register("keyDown", modeKeyDown)
    event.register("keyUp", modeKeyUp)
end

event.register("initialized", onInitialized)



-- ModConfig

local modConfig = require("hrnchamd.perfectplacement.mcm")
modConfig.config = config
modConfig.onKeybindUpdate = keybindUpdate

local function registerModConfig()
	mwse.registerModConfig("Perfect Placement", modConfig)
end

event.register("modConfigReady", registerModConfig)
mwse.log("[Perfect Placement] Loaded successfully.")
