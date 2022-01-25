local common = require('ss20.common')
local config = common.config
local decals = require('ss20.decal')
local m1 = tes3matrix33.new()

local this = {
    maxReach = 700,
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
    drop = 'drop',
    free = 'free',
    wall = 'wall'
}
local endPlacement

local function isPlaceable(target)
    local isInShop = false
    for _, pack in ipairs(config.resourcePacks) do
        for _, item in ipairs(pack.items) do
            if target.baseObject.id:lower() == item.id:lower() then
                isInShop = true
            end
        end
    end
    return isInShop
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
    
    addLine("Rotate", "Hold ", config.keybindRotate)
    addLine("Cycle Drop Mode", "Press ", config.keybindModeCycle)
    addLine("Recover Soul Shards", "Press ", tes3.scanCode.delete)
    menu:updateLayout()
end

local function finalPlacement()
    this.shadow_model.appCulled = true
    this.lastItemOri = this.active.orientation:copy()

    if common.isShiftDown() then
        this.active.position = this.itemInitialPos
        this.active.orientation = this.itemInitialOri
    elseif config.placementSetting == settings.drop then
        -- Drop to ground.
        local from = this.active.position + tes3vector3.new(0, 0, this.height + const_epsilon + 10)
        local rayhit = tes3.rayTest{ position = from, direction = tes3vector3.new(0, 0, -1), ignore = { this.active} }
        if (rayhit) then
            this.active.position = rayhit.intersection + tes3vector3.new(0, 0, this.height + const_epsilon)
        end
    end

    tes3.playSound{ soundPath = "ss20\\ss20_s_drop.wav" }
    if this.active.baseObject.objectType == tes3.objectType.light then
        common.removeLight(this.active.sceneNode)
        common.onLight(this.active)
    end

    endPlacement()
end

local function doDestroyActive(shardsRecovered)
    tes3.playSound{ soundPath = "ss20\\ss20_s_destroy.wav"}
    this.active:disable()
    mwscript.setDelete{ reference = this.active }
    common.modSoulShards(shardsRecovered)
    tes3.messageBox("Recovered %s Soul Shards.", shardsRecovered)
    endPlacement()
end

local function deleteActive()
    if this.active then
        local soulShards = this.active.data and this.active.data.soulShards or 0
        if this.active.baseObject.objectType == tes3.objectType.container then
            if #this.active.object.inventory > 0 then
                tes3.messageBox()
                common.messageBox{
                    message  = string.format("Destroy and recover %d soul shards?",soulShards),
                    buttons = {
                        { text = "Transfer Contents and Destroy", callback = function()
                            for _, stack in pairs(this.active.object.inventory) do
                                tes3.transferItem{from=this.active, to=tes3.player, item=stack.object, count=stack.count, playSound=false}
                            end
                            tes3.playSound{reference=tes3.player, sound="Item Misc Up"}
                            doDestroyActive(soulShards)
                        end},
                        { text = "Destroy Container and all Contents", callback = function()
                            doDestroyActive(soulShards)
                        end},
                        { text = "Cancel"}
                    }
                }
                return
            end
        end

        common.messageBox{
            message  = string.format("Destroy and recover %d soul shards?",soulShards),
            buttons = {
                { text = "Destroy", callback = function()
                    doDestroyActive(soulShards)
                end},
                { text = "Cancel"}
            }
        }

    end
end


-- Called every simulation frame to reposition the item.
local function simulatePlacement()
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
    elseif (tes3.mobilePlayer.weaponReady) then
        finalPlacement()
        return
    --Drop item if no longer able to manipulate
    elseif not common.data.manipulation then
        finalPlacement()
        return
    end
    
    -- Cast ray along initial pickup direction rotated by the 1st person camera.
    this.shadow_model.appCulled = true
    this.active.sceneNode.appCulled = true

    local eyePos = tes3.getPlayerEyePosition()
    local eyeVec = tes3.getPlayerEyeVector()
    local rayhit = tes3.rayTest{ 
        position = eyePos,
        direction = eyeVec,
        ignore = { tes3.player },
    }
    local pos
    local distance

    local width = math.min(this.boundMax.x - this.boundMin.x, this.boundMax.y - this.boundMin.y, this.boundMax.z - this.boundMin.z)
    if rayhit and config.placementSetting ~= settings.free then
        distance = math.min(rayhit.distance - width, this.currentReach)  
    else
        distance = this.currentReach
    end

    local d_theta = tes3.player.orientation.z - this.playerLastOri.z
    m1:toRotationZ(d_theta)
    this.offset = m1 * this.offset
    pos = (eyePos ) + (eyeVec* distance ) + this.offset
    pos.z = pos.z + const_epsilon


    -- Find drop position for shadow spot.
    local dropPos = pos:copy()
    rayhit = tes3.rayTest{ 
        position = this.active.position - tes3vector3.new(0, 0, this.offset.z), 
        direction = tes3vector3.new(0, 0, -1),
        ignore = { this.active }  
    }
    if (rayhit ) then
        dropPos = rayhit.intersection:copy()
        if config.placementSetting == settings.drop then
        
            pos.z = math.max(pos.z, dropPos.z + this.height )
        
        end
    end
    
    -- Incrementally rotate the same amount as the player, to keep relative alignment with player.
    
    this.playerLastOri = tes3.player.orientation:copy()
    if (this.rotateMode) then
        -- Use inputController, as the player orientation is locked.
        d_theta = 0.001 * 15 * tes3.worldController.inputController.mouseState.x
    end

    -- Apply rotation.
    if (this.verticalMode == 0) then
        this.orientation.z = wrapRadians(this.orientation.z + d_theta)
    else
        this.orientation.y = wrapRadians(this.orientation.y + d_theta)
    end

    -- Update item and shadow spot.
    this.active.sceneNode.appCulled = false
    this.active.position = pos
    this.active.orientation = this.orientation:copy()
    this.shadow_model.appCulled = false
    this.shadow_model.translation = dropPos
    this.shadow_model:propagatePositionChange()
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
local function togglePlacement(e)
    toggleBlockActivate()
    e = e or { target = nil }
    if this.active then 
        finalPlacement()
        return
    end

    local target
    if not e.target then
            -- Do not active in menu mode and during attacking/casting.
        -- if (tes3.mobilePlayer.actionData.animationAttackState > 1) then
    
        --     return
        -- end
        if tes3.menuMode() then
            return
        end
        local ray = tes3.rayTest({
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector(),
            ignore = { tes3.player },
            maxDistance = this.maxReach
        })
    
        target = ray and ray.reference
        if target then
            this.offset = target.position - ray.intersection
            this.currentReach = ray and math.min(ray.distance, this.maxReach)
        end
    else
        target = e.target
        local dist = target.position:distance(tes3.getPlayerEyePosition())
        this.currentReach = math.min(dist, this.maxReach)
    end

    if not target then 
        return 
    end

    if target.position:distance(tes3.player.position) > this.maxReach  then
        return
    end

    -- Filter by allowed object type.
    if not isPlaceable(target) then
        if target.baseObject.objectType == tes3.objectType.static then
            tes3.playSound{ soundPath = "ss20\\ss20_s_bad.wav"}
        end
        return
    end


    -- Workaround to avoid dupe-on-load bug when moving non-persistent refs into another cell.
    if (target.sourceMod and not target.cell.isInterior) then
        tes3.messageBox{ message = "You must pick up and drop this item first." }
        return
    end

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
    decals.applyDecals(this.active, config.placementSetting)
    tes3.playSound{ soundPath = "ss20\\ss20_s_pickup.wav" }

    

    -- Add shadow spot to scene.
    tes3.dataHandler.worldObjectRoot:attachChild(this.shadow_model)
    this.shadow_model.appCulled = false
    this.shadow_model.translation = basePos + tes3vector3.new(0, 0, const_epsilon)
    this.shadow_model:propagatePositionChange()

    event.register("simulate", simulatePlacement)
    event.register("cellChanged", cellChanged)
    tes3ui.suppressTooltip(true)
    
    showGuide()

end


endPlacement = function()
    if (this.matchTimer) then
        this.matchTimer:cancel()
    end

    --decals.applyDecals(this.active)
    event.unregister("simulate", simulatePlacement)
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
local function onLoad()
    if (this.active) then
        endPlacement()
    end
end

local function rotateKeyDown(e)
    if (this.active) then
        if (e.keyCode == config.keybindRotate) then
            this.rotateMode = true
            tes3.mobilePlayer.mouseLookDisabled = true
            return false
        end
    end
end

local function rotateKeyUp(e)
    if (this.active) then
        if (e.keyCode == config.keybindRotate) then
            this.rotateMode = false
            tes3.mobilePlayer.mouseLookDisabled = false
        end
    end
end

local function toggleMode(e)
    if not common.data then return end
    this.shadow_model = tes3.loadMesh("ss20/e/shadow.nif")
    if (common.data.manipulation) then
        if (e.keyCode == config.keybindModeCycle) then
            
            local cycle = {
                [settings.drop] = settings.free,
                [settings.free] = settings.wall,
                [settings.wall] = settings.drop
            }

            config.placementSetting = cycle[config.placementSetting]
            if this.active then
                decals.applyDecals(this.active, config.placementSetting)
            end
            tes3.playSound{ soundPath = "ss20\\ss20_s_switch.wav" }

        end
    end
end

local function onInitialized()
    this.shadow_model = tes3.loadMesh("ss20/e/shadow.nif")

    this.id_guide = tes3ui.registerID("ObjectPlacement:GuideMenu")
    event.register("load", onLoad)
    event.register("keyDown", rotateKeyDown, { priority = -100})
    event.register("keyUp", rotateKeyUp)
    event.register("keyDown", toggleMode)

end
event.register("initialized", onInitialized)



local function hasSpellActive()
    return tes3.mobilePlayer.currentSpell   
        and tes3.mobilePlayer.currentSpell.id == config.manipulateSpellId
end

local function hasHandsReady()
    return tes3.mobilePlayer.spellReadied == true
end

local currentRef
local function highlightTarget()
    local manipulationActive = (
        common.isAllowedToManipulate()
        and hasSpellActive()
        and hasHandsReady()
    ) == true

    if currentRef and not manipulationActive then
        decals.applyDecals(currentRef)
        currentRef = nil
    end
    --We only raytest if we are active or there may be an existing one to remove
    if manipulationActive or currentRef then

        local rayhit = tes3.rayTest {
            position = tes3.getPlayerEyePosition(), 
            direction = tes3.getPlayerEyeVector(), 
            ignore = {tes3.player},
            maxDistance = this.maxReach
        };
        local hitRef = rayhit and rayhit.reference
        
        if not this.active then
            --remove existing decal if rayhit empty or doesn't match current
            if currentRef and hitRef ~= currentRef then
                decals.applyDecals(currentRef)
            end
            --apply new ones, only if we're not actively moving stuff
            if manipulationActive and hitRef then
                if isPlaceable(hitRef) then
                    decals.applyDecals(hitRef, 'active')
                end
            end
            currentRef = hitRef
        end     
        
    end
    common.data.manipulation = manipulationActive
end
event.register("simulate", highlightTarget)

local function onObjectInvalidated(e)
    local ref = e.object
    if ref == currentRef then
        currentRef = nil
    end
end
event.register("objectInvalidated", onObjectInvalidated)


local function onMouseScroll(e)
    if this.active then
        local multi = common.isShiftDown() and 0.02 or 0.1
        local change = multi * e.delta
        local newMaxReach = math.clamp(this.currentReach + change, this.minReach, this.maxReach)
        this.currentReach = newMaxReach
    end
end
event.register("mouseWheel", onMouseScroll)


local function blockActivation(e)
    if common.data.manipulation and isPlaceable(e.target) then
        common.log:debug("Manipulation Active")
        return (e.activator ~= tes3.player)
    end
end
event.register("activate", blockActivation, { priority = 500 })

local function onActiveKey(e)
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if keyTest then
        common.log:debug("Activate key pressed")
        if common.data.manipulation then
            common.log:debug("manipulation active activate key pressed")
            togglePlacement()
        end
    end

    if e.keyCode == tes3.scanCode.delete then
        deleteActive()
    end
end
event.register("keyDown", onActiveKey, { priority = 100 })



