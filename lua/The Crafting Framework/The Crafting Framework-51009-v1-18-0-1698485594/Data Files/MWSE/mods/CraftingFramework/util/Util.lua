---@class CraftingFramework.Util
local Util = {}
local config = require("CraftingFramework.config")

Util.loggers = {}
do --logger
    local logLevel = config.mcm.logLevel
    local logger = require("logging.logger")
    --[[
        Creates a logger with the given service name.
        The service name will be prefixed with the mod name.
    ]]
    Util.createLogger = function(serviceName)
        local logger = logger.new{
            name = string.format("%s: %s", config.static.modName, serviceName),
            logLevel = logLevel,
            includeTimestamp = true
        }
        Util.loggers[serviceName] = logger
        return logger
    end
end
local logger = Util.createLogger("Util")

Util.validate = require("CraftingFramework.util.validator").validate
Util.traverseRoots = function(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end
Util.onLight = function(lightRef)
    local function isCollisionNode(node)
        return node:isInstanceOfType(tes3.niType.RootCollisionNode)
    end
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
    ---@type any
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
    logger:debug("onlight done")
end
Util.removeLight = function(lightNode)

    for node in Util.traverseRoots{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        --Kill Melchior's Lantern glow effect
        if  node.name == "LightEffectSwitch" or node.name == "Glow" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end
        if node.name == "AttachLight" then
            --node.appCulled = true
            node.parent:detachChild(node)
        end

        -- Kill materialProperty
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)

                -- Kill controllers
                materialProperty:removeAllControllers()

                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive
                node:updateProperties()
            end
        end
        -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
            texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
    end
    lightNode:update()
    lightNode:updateNodeEffects()
end
function Util.deleteRef(ref, no)
    if no then
        error("You called deleteRef() with a colon, didn't you?")
    end
    ref:disable()
    ---@diagnostic disable-next-line: deprecated
    mwscript.setDelete{ reference = ref}
end
function Util.isShiftDown()
    local ic = tes3.worldController.inputController
	return ic:isKeyDown(tes3.scanCode.leftShift) or ic:isKeyDown(tes3.scanCode.rightShift)
end

function Util.isQuickModifierDown()
    local quickModifier = config.mcm.quickModifierHotkey
    local ic = tes3.worldController.inputController
    return ic:isKeyDown(quickModifier.keyCode)
end

function Util.isKeyPressed(pressed, expected)
    return (
        pressed.keyCode == expected.keyCode
         and not not pressed.isShiftDown == not not expected.isShiftDown
         and not not pressed.isControlDown == not not expected.isControlDown
         and not not pressed.isAltDown == not not expected.isAltDown
         and not not pressed.isSuperDown == not not expected.isSuperDown
    )
end

---@param ref tes3reference
function Util.canBeActivated(ref)
    local hasScript = ref.baseObject.script ~= nil
    return hasScript or ref.baseObject.objectType == tes3.objectType.container
end

---@return any
function Util.convertListTypes(list, classType)
    if list == nil then
        return nil
    end
    local newList = {}
    for _, data in ipairs(list) do
        local newItem = classType:new(data)
        table.insert(newList, newItem)
    end
    return newList
end

--[[
    Forces a container to be instanced,
    which will resolve any leveled items
    in its inventory
]]
---@param reference tes3reference
function Util.forceInstance(reference)
    local object = reference.object
    if (object.isInstance == false) then
        object:clone(reference)
        reference.modified = true
    end
    return reference --.object
end

return Util