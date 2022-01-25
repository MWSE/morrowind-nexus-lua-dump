local common = require('ss20.common')
local this = {}

local function traverseNIF(roots)
    local function iter(nodes)
        for i, node in ipairs(nodes or roots) do
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

local states = {
    active = "textures\\ss20\\decal_white.dds",
    drop =  "textures\\ss20\\decal_green.dds",
    free =  "textures\\ss20\\decal_blue.dds",
    wall = "textures\\ss20\\decal_pink.dds",
}

local textures = {}

local function preloadTextures()
    common.log:debug("preloading textures for SS20")
    for state, path in pairs(states) do
        local texture = niSourceTexture.createFromPath(path)
        textures[state] = texture
    end
end
preloadTextures()


local function setDecal(property, currentState)
    local decal 
    if currentState then
        decal = textures[currentState]
    end
    --Remove old one if it exists
    for index, map in ipairs(property.maps) do
        local texture = map and map.texture
        local fileName = texture and texture.fileName
        
        if fileName then
            for _, path in pairs(states) do
                if fileName == path then
                    if decal then
                        map.texture = decal
                    else
                        property:removeDecalMap(index)
                    end
                    return
                end
            end
        end
    end
    if decal then
        --Add new decal
        if property.canAddDecal then
            property:addDecalMap(decal)
        end
    end
end

function this.applyDecals(reference, currentState)
    for node in traverseNIF{ reference.sceneNode} do
        local success, texturingProperty, _ = pcall(function() return node:getProperty(0x4), node:getProperty(0x0) end)
        if (success and texturingProperty and not (node.RTTI.name == "NiBSParticleNode") ) then
            local clonedProperty = node:detachProperty(0x4):clone()
            node:attachProperty(clonedProperty)
            setDecal(clonedProperty, currentState)
            node:updateProperties()
        end
    end
end

return this