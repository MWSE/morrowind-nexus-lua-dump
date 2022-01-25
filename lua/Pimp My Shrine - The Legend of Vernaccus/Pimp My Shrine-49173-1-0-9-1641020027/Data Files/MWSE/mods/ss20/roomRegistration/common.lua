local this  = {}
this.config = require("ss20.roomRegistration.config")
this.mcmConfig = mwse.loadConfig(this.config.modName, this.config.mcmDefaultValues)
function this.keyPressed(keyEvent, expected)
    return (
        keyEvent.keyCode == expected.keyCode and
        not not keyEvent.isShiftDown == not not expected.isShiftDown and
        not not keyEvent.isControlDown == not not expected.isControlDown and
        not not keyEvent.isAltDown == not not expected.isAltDown
    )
end


this.debug = function(message, ...)
    if this.mcmConfig.debug then
        local output = string.format("[%s] %s", this.config.modName, tostring(message):format(...) )
        mwse.log(output)
    end
end



--Initialisation
local function initData()
    tes3.player.data[this.config.modName] = tes3.player.data[this.config.modName] or {}
    this.data = tes3.player.data[this.config.modName]
    mwse.log("Shrine of Vernaccus Data Initialised")
end
event.register("loaded", initData)

function this.messageBox(params)
    --[[
        Button = { text, callback}
    ]]--
    local message = params.message
    local buttons = params.buttons
    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            button.callback()
        end
    end
    --Make list of strings to insert into buttons
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end
    tes3.messageBox({
        message = message,
        buttons = buttonStrings,
        callback = callback
    })
end

this.sortByName = function(a,b) return a.name < b.name; end
this.sortById = function(a,b) return a.id < b.id; end
function this.makeFilteredList(objectTypes, searchParam)


    local list = {}
    mwse.log("searchParam: %s, objectTypes: %s", searchParam)
    for objectType, _ in ipairs(objectTypes) do
        for obj in tes3.iterateObjects(objectType) do
            if not searchParam or searchParam.len == 0 then
                table.insert(list, obj);
            elseif obj.id:lower():find(searchParam:lower()) then
                table.insert(list, obj);
            end
        end
    end
    table.sort(list, this.sortById);
    return list
end

local function isCollisionNode(node)
    return node:isInstanceOfType(tes3.niType.RootCollisionNode) 
end

function this.onLight(lightRef)
    
    if (not lightRef.object.mesh) or (string.len(lightRef.object.mesh) == 0) then
        return
    end

    lightRef:deleteDynamicLightAttachment()
    local newNode = tes3.loadMesh(lightRef.object.mesh):clone()
    
    --[[
        Remove existing children and reattach them from the base mesh,
        to restore light properties. Ignore collision node to avoid 
        crashes from collision detection. 
    ]]
    for i, childNode in ipairs(lightRef.sceneNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:detachChildAt(i)
        end
    end
    for i, childNode in ipairs(newNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:attachChild(newNode.children[i], true)
        end
    end
    local lightNode = niPointLight.new()
    lightNode.name = "LIGHTNODE"
    if lightRef.object.color then
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(
            lightRef.object.color[1] / 255,
            lightRef.object.color[2] / 255,
            lightRef.object.color[3] / 255
        )
    else
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(255, 255, 255)
    end
    lightNode:setAttenuationForRadius(lightRef.object.radius)
    --see if there's an attachlight node to work with
    local attachLight = lightRef.sceneNode:getObjectByName("attachLight")
    local windowsGlowAttach = lightRef.sceneNode:getObjectByName("NightDaySwitch")
    attachLight = attachLight or windowsGlowAttach or lightRef.sceneNode
    attachLight:attachChild(lightNode)

    lightRef.sceneNode:update()
    lightRef.sceneNode:updateNodeEffects()
    lightRef:getOrCreateAttachedDynamicLight(lightNode, 1.0)
    mwse.log("onlight done")
end

function this.isShiftDown()
    local ic = tes3.worldController.inputController
	return ic:isKeyDown(tes3.scanCode.leftShift) or ic:isKeyDown(tes3.scanCode.rightShift)
end

return this