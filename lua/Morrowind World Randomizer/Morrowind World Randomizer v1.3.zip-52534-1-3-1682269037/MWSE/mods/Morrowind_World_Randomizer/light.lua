local log = include("Morrowind_World_Randomizer.log")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")

local this = {}

local function updateLight(ref, colorCarry, color, rad)
    if not ref or not ref.object.mesh or ref.object.mesh == "" then
        return
    end
    ref:deleteDynamicLightAttachment()
    local newNode = tes3.loadMesh(ref.object.mesh):clone()
    for i = 1, #ref.sceneNode.children do
        ref.sceneNode:detachChild(ref.sceneNode.children[i], true)
    end
    for i = 1, #newNode.children do
        ref.sceneNode:attachChild(newNode.children[i], true)
    end

    local lightNode = niPointLight.new()
    local radius = rad or ref.object.radius
    if ref.object.color and colorCarry then
        lightNode.ambient = tes3vector3.new(0, 0, 0)
        lightNode.diffuse = colorCarry
        this.saveLightData(ref, colorCarry, nil, radius)
    elseif color then
        lightNode.ambient = tes3vector3.new(0, 0, 0)
        lightNode.diffuse = color
        this.saveLightData(ref, nil, color, radius)
    end
    lightNode:setAttenuationForRadius(radius)
    ref.sceneNode:update()
    ref.sceneNode:updateNodeEffects()
    ref:getOrCreateAttachedDynamicLight(lightNode, 1.0)
    log("New Light %s radius %s (r %s g %s b %s)", tostring(ref), tostring(radius), tostring(lightNode.diffuse.r), tostring(lightNode.diffuse.g),
        tostring(lightNode.diffuse.b))
end

function this.randomizeCellLight(cell)
    local rm1, gm1, bm1, rm2, gm2, bm2 = math.random(), math.random(), math.random(), math.random(), math.random(), math.random()
    local rndCc = {r = {min = math.min(rm1, rm2), max = math.max(rm1, rm2)}, g = {min = math.min(gm1, gm2), max = math.max(gm1, gm2)},
        b = {min = math.min(bm1, bm2), max = math.max(bm1, bm2)}}
    rm1, gm1, bm1, rm2, gm2, bm2 = math.random(), math.random(), math.random(), math.random(), math.random(), math.random()
    local rndC = {r = {min = math.min(rm1, rm2), max = math.max(rm1, rm2)}, g = {min = math.min(gm1, gm2), max = math.max(gm1, gm2)},
        b = {min = math.min(bm1, bm2), max = math.max(bm1, bm2)}}

    for ref in cell:iterateReferences{tes3.objectType.light} do
        local color1 = tes3vector3.new(
            math.random(rndCc.r.min, rndCc.r.max),
            math.random(rndCc.g.min, rndCc.g.max),
            math.random(rndCc.b.min, rndCc.b.max))
        local color2 = tes3vector3.new(
            math.random(rndC.r.min, rndC.r.max),
            math.random(rndC.g.min, rndC.g.max),
            math.random(rndC.b.min, rndC.b.max))
        updateLight(ref, color1, color2)
    end
    cell.staticObjectsRoot:update()
    cell.staticObjectsRoot:updateEffects()
end

function this.restoreCellLight(cell)
    for ref in cell:iterateReferences{tes3.objectType.light} do
        this.restoreLightData(ref)
    end
    cell.staticObjectsRoot:update()
    cell.staticObjectsRoot:updateEffects()
end

function this.restoreLightData(ref)
    local data = dataSaver.getObjectData(ref)
    if data and data.light then
        local vec1 = data.light.colorCarry and tes3vector3.new(data.light.colorCarry.r, data.light.colorCarry.g, data.light.colorCarry.b) or nil
        local vec2 = data.light.color and tes3vector3.new(data.light.color.r, data.light.color.g, data.light.color.b) or nil
        updateLight(ref, vec1, vec2, data.light.radius)
    end
end

function this.saveLightData(ref, colorCarry, color, radius)
    local data = dataSaver.getObjectData(ref)
    if data then
        if not data.light then data.light = {} end
        if colorCarry then
            data.light.colorCarry = {r = colorCarry.r, g = colorCarry.g, b = colorCarry.b}
        end
        if color then
            data.light.color = {r = color.r, g = color.g, b = color.b}
        end
        data.light.radius = radius
    end
end

return this