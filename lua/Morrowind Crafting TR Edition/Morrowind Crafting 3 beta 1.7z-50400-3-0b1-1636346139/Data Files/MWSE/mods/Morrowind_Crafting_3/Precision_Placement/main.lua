--[[ MoveIt     c/r 2019, Drac and Toccatta
    Allows detailed movement of misc objects, books and weapons ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)
local mc = require("Morrowind_Crafting_3.mc_common")
local this = {}
local thing, ttemp, menu, vanityDelay, vanityDelayOrig
local affectList = { tes3.objectType.activator, 
            tes3.objectType.alchemy, 
            tes3.objectType.ammunition,
            tes3.objectType.apparatus, 
            tes3.objectType.armor, 
            tes3.objectType.book, 
            tes3.objectType.clothing,
            tes3.objectType.ingredient, 
            tes3.objectType.light, 
            tes3.objectType.lockpick, 
            tes3.objectType.miscItem, 
            tes3.objectType.probe, 
            tes3.objectType.repairItem, 
            tes3.objectType.weapon, 
            tes3.objectType.container }
local origX, origY, origZ, origXa, origYa, origZa, origS
local active, x, y, z, s, snap2grid = false, false, false, false, false, true
local granuList = {
    {value = 0.05, name = "Very Fine"},
    {value = 1.0, name = "Fine"},
    {value = 5.0, name = "Medium"},
    {value = 15.0, name = "Coarse"}
}
local granuChoice = 2
local axis = {"Move", "Rotate"}
local axisChoice = 1
local deg = (2 * math.pi)/360

-- Stores GMST 'fVanityDelay', sets to high value while in positioning mode; restores when done


function this.init()
    this.id_menu = tes3ui.registerID("PositioningMenu") --overall menu ID
    this.id_stats = tes3ui.registerID("PositioningBlock") --statistics block
    this.id_legend = tes3ui.registerID("PositioningHelp") -- help block
    this.id_title = tes3ui.registerID("PositioningTitle")
    this.id_body = tes3ui.registerID("PositioningBody")
    vanityDelay = tes3.findGMST("fVanityDelay")
end

local function matchOrientation(e)
    local copyFrom
    if active == true then
        copyFrom = tes3.getPlayerTarget() -- Object from which to copy orientations
        if copyFrom then -- Not nil? Got something.
            x = copyFrom.orientation.x
            y = copyFrom.orientation.y
            z = copyFrom.orientation.z
            thing.orientation = tes3vector3.new(x, y, z)
            thing:updateSceneGraph()
            this.createWindow()
        end
    end
end

local function startPositioning(e) -- Check to see if is a movable item
    if active == true then
        menu:destroy()
        active = false
    end
    thing = tes3.getPlayerTarget()
    if thing ~= nil then
        ttemp = false
        for idx = 1, #affectList do
           if affectList[idx] == thing.object.objectType then
                ttemp = true
            end
        end
    else
        active = false
        return false
    end
    if ttemp ~= true then
        return false
    end
    origX = thing.position.x
    origY = thing.position.y
    origZ = thing.position.z
    origXa = thing.orientation.x
    origYa = thing.orientation.y
    origZa = thing.orientation.z
    origS = thing.scale
    vanityDelayOrig = vanityDelay.value
    vanityDelay.value = 7200
    active = true
    tes3.messageBox("Positioning "..thing.object.name)
    this.createWindow()
end

local function restoreVanity()
    vanityDelay.value = vanityDelayOrig
end

local function snapToGrid() -- Snap to whole degrees, x/y/z coords, whole angle degrees, 1/100th unit scale
    local x, y, z = thing.position.x, thing.position.y, thing.position.z
    thing.position = tes3vector3.new(math.round(x,0), math.floor(y,0), math.floor(z,0))
    x = math.rad(math.round(math.deg(thing.orientation.x),0))
    y = math.rad(math.round(math.deg(thing.orientation.y),0))
    z = math.rad(math.round(math.deg(thing.orientation.z),0))
    thing.orientation = tes3vector3.new(x, y, z)
    thing:updateSceneGraph()
    this.createWindow()
end

local function onKeyUpEnd(e) -- Exit 'moving' mode
    if active == true then
        menu:destroy()
        menu = nil
        tes3.messageBox("Exiting Position Mode")
        active = false
        granuChoice = 2
        axisChoice = 1
        timer.start{ duration = 10, iterations = 1, type = timer.simulate, callback = restoreVanity}
        return false
    end
end

local function onKeyUpGranuCoarser()
    if active == true then
        granuChoice = granuChoice + 1
        if granuChoice > #granuList then granuChoice = 1 end
        tes3.messageBox("Granularity: "..granuList[granuChoice].name)
        this.createWindow()
    end
end

local function onKeyUpGranuFiner()
    if active == true then
        granuChoice = granuChoice - 1
        if granuChoice < 1 then granuChoice = #granuList end
        tes3.messageBox("Granularity: "..granuList[granuChoice].name)
        this.createWindow()
    end
end

local function onKeyUpHome() -- Initialize positioning (or return to starting position)
    if active == true then
        thing.position = tes3vector3.new(origX, origY, origZ)
        thing.orientation = tes3vector3.new(origXa, origYa, origZa)
        thing.scale = origS
        thing:updateSceneGraph()
        tes3.messageBox("Cancelling changes")
        this.createWindow()
    else
        startPositioning()
    end
end

local function switchAxis()
    if active == true then
        axisChoice = axisChoice + 1
        if axisChoice > #axis then
            axisChoice = 1
        end
        this.createWindow()
    end
end

local function startX()
    if active == true then
        x = true
    end
end

local function startY()
    if active == true then
        y = true
    end
end

local function startZ()
    if active == true then
        z = true
    end
end

local function startS()
    if active == true then
        s = true
    end
end

local function doneX()
    if active == true then
        x = false
    end
end

local function doneY()
    if active == true then
        y = false
    end
end

local function doneZ()
    if active == true then
        z = false
    end
end

local function doneS()
    if active == true then
        s = false
    end
end

local function rotator(e)
    local ttemp
    if active == true then
        if s == true then
            if e.delta > 0 then
                ttemp = thing.scale + (granuList[granuChoice].value/100.0)
                if ttemp > 2.0 then ttemp = 2.0 end
                thing.scale = (math.floor(ttemp*100+.005))/100
            else
                ttemp = thing.scale - (granuList[granuChoice].value/100.0)
                if ttemp < 0.5 then ttemp = 0.5 end
                thing.scale = (math.floor(ttemp*100+.005))/100
            end
        elseif axis[axisChoice] == "Rotate" then
            if x == true then
                if e.delta > 0 then -- moving mousewheel moveForward
                    thing.orientation = thing.orientation + tes3vector3.new(granuList[granuChoice].value*deg, 0, 0)
                else -- moving mousewheel backward
                    thing.orientation = thing.orientation - tes3vector3.new(granuList[granuChoice].value*deg, 0, 0)
                end
            elseif y == true then
                if e.delta > 0 then -- moving mousewheel moveForward
                    thing.orientation = thing.orientation + tes3vector3.new( 0, granuList[granuChoice].value*deg, 0)
                else -- moving mousewheel backward
                    thing.orientation = thing.orientation - tes3vector3.new( 0, granuList[granuChoice].value*deg, 0)
                end
            elseif z == true then
                if e.delta > 0 then -- moving mousewheel moveForward
                    thing.orientation = thing.orientation + tes3vector3.new( 0, 0, granuList[granuChoice].value*deg)
                else -- moving mousewheel backward
                    thing.orientation = thing.orientation - tes3vector3.new( 0, 0, granuList[granuChoice].value*deg)
                end
            end
        elseif axis[axisChoice] == "Move" then
            if x == true then
                if e.delta > 0 then
                    thing.position = thing.position + tes3vector3.new( granuList[granuChoice].value, 0, 0)
                else
                    thing.position = thing.position - tes3vector3.new( granuList[granuChoice].value, 0, 0)
                end
            elseif y == true then
                if e.delta > 0 then
                    thing.position = thing.position + tes3vector3.new( 0, granuList[granuChoice].value, 0)
                else
                    thing.position = thing.position - tes3vector3.new( 0, granuList[granuChoice].value, 0)
                end
            elseif z == true then
                if e.delta > 0 then
                    thing.position = thing.position + tes3vector3.new( 0, 0, granuList[granuChoice].value)
                else
                    thing.position = thing.position - tes3vector3.new( 0, 0, granuList[granuChoice].value)
                end
            end
        else
            mwse.log("Error using mousewheel. AxisChoice = "..axisChoice)
        end
        if (snap2grid == true) and (granuList[granuChoice].name ~= "Very Fine") then snapToGrid() end
        thing:updateSceneGraph()
        this.createWindow()
    end
end

local function dropDown()
    local newHeight
    if active == true then
        local vertex = mc.getLowestVertex(thing.sceneNode)
       local newHeight = mc.dropSpot(thing) -- (.position) Get the Z-coord of the first surface below item
       zHeight = newHeight + (thing.position.z - vertex.z) + 0.01
        thing.position = thing.position.new(thing.position.x, thing.position.y, zHeight)
        if snap2grid == true then snapToGrid() end
        thing:updateSceneGraph()
        this.createWindow()
    end
end

local function snapToGridToggle()
    if active == true then
        if snap2grid == false then
            snap2grid = true
            snapToGrid()
        else
            snap2grid = false
        end
        this.createWindow()
    end
end

function this.createWindow()
    local label, stats, legend, titleBlock, bodyBlock
    if (menu ~= nil) then
        menu:destroy()
        thing:updateSceneGraph()
    end
    menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
    menu.alpha = 0.75
    menu.text = "Adjusting"
    menu.width = 440
    menu.height = 260
    menu.minWidth = 440
    menu.minHeight = 260
    menu.absolutePosAlignX = 0.02
    menu.absolutePosAlignY = 0.04
    menu.flowDirection = "top_to_bottom"

    titleBlock = menu:createBlock{id = this.id_title}
    titleBlock.widthProportional = 1.0
    titleBlock.childAlignX = 0.5
    titleBlock.autoHeight = true
    label = titleBlock:createLabel({text = "Item: "..thing.object.name})
    label.wrapText = true

    bodyBlock = menu:createBlock{id = this.id_body}
    bodyBlock.flowDirection = "left_to_right"
    bodyBlock.widthProportional = 1.0
    bodyBlock.heightProportional = 1.0
    bodyBlock.childAlignX = -1.0

    stats = bodyBlock:createThinBorder({id = this.id_stats})
    stats.widthProportional = 0.8
    stats.heightProportional = 1.0
    stats.flowDirection = "top_to_bottom"
    stats.paddingAllSides = 5
    stats.childAlignX = 0.0
    
    local label = stats:createLabel({text = "X: "..string.format("%0.2f",thing.position.x)})
    local label = stats:createLabel({text = "Y: "..string.format("%0.2f",thing.position.y)})
    local label = stats:createLabel({text = "Z: "..string.format("%0.2f",thing.position.z)})
    local label = stats:createLabel({text = "X Axis: "..string.format("%0.2f",math.deg(thing.orientation.x))})
    local label = stats:createLabel({text = "Y Axis: "..string.format("%0.2f",math.deg(thing.orientation.y))})
    local label = stats:createLabel({text = "Z Axis: "..string.format("%0.2f",math.deg(thing.orientation.z))})
    local label = stats:createLabel({text = "Scale:  "..string.format("%0.2f",thing.scale)})
    if snap2grid == true then
        local label = stats:createLabel({text="GridSnap: ON"})
    else
        local label = stats:createLabel({text="GridSnap: Off"})
    end
    local label = stats:createLabel({text = "Precision: "..granuList[granuChoice].name})
    local label = stats:createLabel({text = "Motion: "..axis[axisChoice]})

    legend = bodyBlock:createThinBorder({id = this.id_legend})
    legend.flowDirection = "top_to_bottom"
    legend.widthProportional = 1.2
    legend.heightProportional = 1.0
    legend.paddingAllSides = 5
    --label = legend:createLabel({text = ""})
    label = legend:createLabel({text = "Reset = Home"})
    label = legend:createLabel({text = "Change Precision = PageUp"})
    label = legend:createLabel({text = "Toggle Snap to Grid = Insert"})
    label = legend:createLabel({text = "Toggle Move/Rotate = Delete"})
    label = legend:createLabel({text = "Scale = C + MouseWheel"})
    label = legend:createLabel({text = "Move = X/Y/Z + MouseWheel"})
    label = legend:createLabel({text = "Match Target Orientation"})
    label = legend:createLabel({text = "     = Aim + PageDown"})
    label = legend:createLabel({text = "Drop to Surface = Backspace"})
    label = legend:createLabel({text = ""})
    label = legend:createLabel({text = "Finish = End"})
    ttemp = 0
    menu.visible = true
    menu:updateLayout()
end

event.register("initialized", this.init)

event.register("keyDown", startX, {filter = tes3.scanCode.x})
event.register("keyDown", startY, {filter = tes3.scanCode.y})
event.register("keyDown", startZ, {filter = tes3.scanCode.z})
event.register("keyDown", startS, {filter = tes3.scanCode.c})
event.register("keyUp", doneX, {filter = tes3.scanCode.x})
event.register("keyUp", doneY, {filter = tes3.scanCode.y})
event.register("keyUp", doneZ, {filter = tes3.scanCode.z})
event.register("keyUp", doneS, {filter = tes3.scanCode.c})
event.register("keyUp", onKeyUpEnd, {filter = tes3.scanCode["end"]})
event.register("keyUp", onKeyUpGranuCoarser, {filter = tes3.scanCode.pageUp})
event.register("keyUp", onKeyUpHome, {filter = tes3.scanCode.home})
event.register("keyUp", snapToGridToggle, {filter = tes3.scanCode.insert})
event.register("keyUp", switchAxis, {filter = tes3.scanCode.delete})
event.register("keyUp", matchOrientation, {filter = tes3.scanCode.pageDown})
event.register("keyUp", dropDown, {filter = tes3.scanCode.backspace})
event.register("keyUp", onKeyUpEnd, {filter = tes3.scanCode.space})
event.register("mouseWheel", rotator)