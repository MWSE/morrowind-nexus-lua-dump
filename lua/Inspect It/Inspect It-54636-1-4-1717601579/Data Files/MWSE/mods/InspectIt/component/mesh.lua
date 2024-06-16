---@class MeshProcessor
local this = {}
local logger = require("InspectIt.logger")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")

local sameArmor = nil ---@type string[]
local sameClothing = nil ---@type string[]

---@param node niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
---@param func fun(node : niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape, depth : number)
---@param depth integer?
function this.foreach(node, func, depth)
    depth = depth or 0
    func(node, depth)
    if node.children then
        local d = depth + 1
        for _, child in ipairs(node.children) do
            if child then
                this.foreach(child, func, d)
            end
        end
    end
end

---@param a tes3vector3
---@param b tes3vector3
local function DistanceSquared(a, b)
    local c = a - b
    return c:dot(c)
end

-- FIXME Usually, this is not a problem, but if the same mesh is diverted from the armor, even if it is not from the left or right side, it will not work.
-- We need more information to record in the memo.
---@param objectType tes3.objectType
---@return string[] ids
local function CollectSameMeshAsRightPart(objectType)
    local result = {} ---@type {[string]: boolean}
    local memo = {} ---@type {[string]: string|boolean}
    for o in tes3.iterateObjects(objectType) do
        ---@cast o tes3armor|tes3clothing
        if o.mesh then
            local mesh = o.mesh:lower()
            if o.isLeftPart then
                local id = o.id:lower()
                if memo[mesh] == true then -- contain boolean
                    result[id] = true
                    logger:trace("same mesh: %s, %s, %s", id, o.sourceMod, mesh)
                else
                    memo[mesh] = id
                end
            else -- right or normal
                if memo[mesh] and memo[mesh] ~= true then -- contain id
                    result[memo[mesh]] = true
                    logger:trace("same mesh: %s, %s, %s", memo[mesh], o.sourceMod, mesh)
                end
                memo[mesh] = true
            end
        end
    end
    return table.keys(result, true)
end

---@return string[]
function this.GetArmorSameMeshAsRightPart()
    if not sameArmor then
        sameArmor = CollectSameMeshAsRightPart(tes3.objectType.armor)
        logger:debug("same mesh armor count: %d", table.size(sameArmor))
    end
    return sameArmor
end

---@return string[]
function this.GetClothingSameMeshAsRightPart()
    if not sameClothing then
        sameClothing = CollectSameMeshAsRightPart(tes3.objectType.clothing)
        logger:debug("same mesh clothing count: %d", table.size(sameClothing))
    end
    return sameClothing
end

---@param id string
---@return boolean
function this.CanMirrorById(id)
    if config.leftPartFilter[id:lower()] == true then
        logger:debug("Exclude mirror the left part by id: %s", id)
        return false
    end
    return true
end

---@param sourceMod string
---@return boolean
function this.CanMirrorBySourceMod(sourceMod)
    if sourceMod and config.leftPartFilter[sourceMod:lower()] == true then
        logger:debug("Exclude mirror the left part by plugin: %s", sourceMod)
        return false
    end
    return true
end

---@param object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon
---@return boolean
function this.CanMirror(object)
    if object.isLeftPart and config.display.leftPart then
        if this.CanMirrorBySourceMod(object.sourceMod) == false then
            return false
        end
        if this.CanMirrorById(object.id) == false then
            return false
        end
        return true
    end
    return false
end

---@param key string
---@return boolean
function this.ToggleMirror(key)
    key = key:lower()
    if config.leftPartFilter[key] == true then
        config.leftPartFilter[key] = false
    else
        config.leftPartFilter[key] = true
    end
    mwse.saveConfig(settings.configPath, config)
    return config.leftPartFilter[key]
end


function this.CalculateBounds(model)
    local bounds = model:createBoundingBox():copy()
    if config.display.recalculateBounds then
        local backup = bounds:copy()
        -- vertex only bounds
        -- more tight bounds, but possible too heavy.
        logger:debug("MWSE bounds: %s", bounds)
        bounds.max = tes3vector3.new(-math.fhuge, -math.fhuge, -math.fhuge)
        bounds.min = tes3vector3.new(math.fhuge, math.fhuge, math.fhuge)
        local accept = false
        this.foreach(model, function(node)
            if node:isOfType(ni.type.NiTriShape) then
                ---@cast node niTriShape
                local data = node.data
                if data.vertexCount == 0 then
                    logger:warn("NiTriShape has no geometry: %s", node.name)
                    return
                end

                local transform = node.worldTransform:copy()
                if node.skinInstance and node.skinInstance.root then
                    -- skinning seems still skeleton relative or the original world coords from the root to this node
                    -- correct mul order? or just copy.
                    transform = node.skinInstance.root.worldTransform:copy() * transform:copy()
                end

                -- object world bounds
                local max = tes3vector3.new(-math.fhuge, -math.fhuge, -math.fhuge)
                local min = tes3vector3.new(math.fhuge, math.fhuge, math.fhuge)
                for _, vert in ipairs(data.vertices) do
                    local v = transform * vert:copy()
                    max.x = math.max(max.x, v.x);
                    max.y = math.max(max.y, v.y);
                    max.z = math.max(max.z, v.z);
                    min.x = math.min(min.x, v.x);
                    min.y = math.min(min.y, v.y);
                    min.z = math.min(min.z, v.z);
                end

                -- Some meshes seem to contain incorrect vertices.
                -- FIXME Or calculations required to transform are still missing.
                -- In especially 'Tri chest' of 'The Imperfect'.
                -- worldBounds always seems correctly, but it's a sphere, lazy bounds. These need to be combined well.
                local center = node.worldBoundOrigin
                local radius = node.worldBoundRadius
                local threshold = radius * 2 -- FIXME In theory, it should fit within the radius, but often it does not. Allow for more margin.
                threshold = threshold * threshold
                -- boundingbox is some distance away from bounding sphere.
                if DistanceSquared(center, max) > threshold or DistanceSquared(center, min) > threshold then
                    logger:debug("Use bounding sphere: %s", tostring(node.name))
                    logger:trace("origin %s, radius %f", node.worldBoundOrigin, node.worldBoundRadius)
                    logger:trace("world max %s, min %s, size %s, center %s, length %f", max, min, (max - min), ((max + min) * 0.5), (max - min):length())
                    local smax = center:copy() + radius
                    local smin = center:copy() - radius
                    max = smax
                    min = smin
                end

                -- merge all
                bounds.max.x = math.max(bounds.max.x, max.x);
                bounds.max.y = math.max(bounds.max.y, max.y);
                bounds.max.z = math.max(bounds.max.z, max.z);
                bounds.min.x = math.min(bounds.min.x, min.x);
                bounds.min.y = math.min(bounds.min.y, min.y);
                bounds.min.z = math.min(bounds.min.z, min.z);
                accept = true
            end
        end)

        -- no geometry
        if not accept then
            bounds = backup
            -- original may also be incorrect?
            logger:warn("There was no geometry, MWSE bounds will be used.")
        end
    end

    return bounds
end

---@param model niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
---@param scale number
function this.RescaleParticle(model, scale)
    -- rescale particle
    -- It seems that the scale is roughly doubly applied to the size of particles. Positions are correct. Is this a specification?
    -- Apply the scale of counterparts
    -- Works well in most cases, but does not seem to work well for non-following types of particles, etc.
    -- Torch, Mace of Aevar Stone-Singer
    -- This requires setting the 'trailer' to 0 in niParticleSystemController , which cannot be changed from MWSE.
    this.foreach(model, function(node, _)
        if node:isInstanceOfType(ni.type.NiParticles) then
            ---@cast node niParticles
            for index, value in ipairs(node.data.sizes) do
                node.data.sizes[index] = value * scale
            end
            node.data:markAsChanged()
            node.data:updateModelBound() -- need?
        end
    end)
end

--- removeunnecessary node
---@param model niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
function this.CleanMesh(model)
    local bit = require("bit")
    this.foreach(model, function(node, _)
        if not node.parent then
            return
        end
        local remove = false
        -- In OpenMW only except for creature, but is it bad for creature?
        -- If it is because the animation changes the visibility, then it should be removed if there is no animation.
        -- if not isCreature then
        if bit.band(node.flags, 0x1) == 0x1 then -- invisible
            remove = true
            logger:trace("Remove by visibility")
        end
        -- end
        if node:isInstanceOfType(ni.type.RootCollisionNode) then -- collision
            remove = true
            logger:trace("Remove by collision")
        elseif node:isOfType(ni.type.NiTriShape) then
            if node.name then
                local n = node.name:lower()
                -- https://morrowind-nif.github.io/Notes_EN/module_2_3_1_3_2_1.htm
                if n:startswith("tri shadow") then -- shadow
                    remove = true
                    logger:trace("Remove by Tri Shadow")
                elseif n:startswith("tri bip") then -- dummy
                    remove = true
                    logger:trace("Remove by Tri Bip")
                end
            end
        end
        if remove then
            node.parent:detachChild(node)
        end
    end)
end

--- The player is affected by the same effects as the player,
--- which is not a problem during FPV since they are almost in the same position,
--- but may be unnatural during TPV if the distance is too far apart.
--- But we do not want to probe which effects are affected.
---@param node niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
function this.AttachDynamicEffect(node)
    local src = tes3.player1stPerson.sceneNode
    if tes3.is3rdPerson() then
        src = tes3.player.sceneNode
    end
    if src then
        local effects = src.effectList
        while effects do
            if effects.data then
                local effect = effects.data --[[@as niAmbientLight|niDirectionalLight|niPointLight|niSpotLight|niTextureEffect]]
                if effect:isInstanceOfType(ni.type.NiLight) then -- only light or point
                    logger:debug("Attach effect: %s", effect)
                    node:attachEffect(effect)
                    effect:attachAffectedNode(node)
                    effect:updateEffects()
                end
            end
            effects = effects.next
        end
    end
end

---@param node niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
---@param recursive boolean
function this.DetachDynamicEffect(node, recursive)
    local list = {} -- Detaching and then iterating seems to cause linked list to shrink and crash?
    local effects = node.effectList
    while effects do
        if effects.data then
            -- logger:trace("effect: %s", effects.data)
            table.insert(list, effects.data)
        end
        effects = effects.next
    end
    for _, effect in ipairs(list) do
        logger:debug("Dettach effect: %s", effect)
        effect:detachAffectedNode(node)
        effect:updateEffects()
    end
    if node.detachAllEffects then
        node:detachAllEffects()
    end
    list = nil

    if recursive and node.children then
        for _, child in ipairs(node.children) do
            if child then
                ---@cast child niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode
                this.DetachDynamicEffect(child, recursive)
            end
        end
    end
end

---@diagnostic disable-next-line: undefined-doc-name
---@param prop niAlphaProperty|niDitherProperty|niFogProperty|niMaterialProperty|niRendererSpecificProperty|niShadeProperty|niSpecularProperty|niStencilProperty|niTexturingProperty|niVertexColorProperty|niWireframeProperty|niZBufferProperty
---@return string?
local function DumpProperty(prop)
    ---@type { [string] : fun() :string? }
    local func = {
        ["NiAlphaProperty"] = function()
            ---@cast prop niAlphaProperty
            return string.format("alphaTestRef: %f", prop.alphaTestRef)
        end,
        ["NiDitherProperty"] = function() end,
        ["NiFogProperty"] = function() end,
        ["NiMaterialProperty"] = function()
            ---@cast prop niMaterialProperty
            return string.format("alpha: %f, ambient: %s, diffuse: %s, emissive: %s, shininess: %f, specular: %s",
                prop.alpha,
                prop.ambient:toVector3(),
                prop.diffuse:toVector3(),
                prop.emissive:toVector3(),
                prop.shininess,
                prop.specular:toVector3())
        end,
        ["NiRendererSpecificProperty"] = function() end,
        ["NiShadeProperty"] = function() end,
        ["NiSpecularProperty"] = function()end,
        ["NiStencilProperty"] = function()end,
        ["NiTexturingProperty"] = function()end,
        ["NiVertexColorProperty"] = function()
            ---@cast prop  niVertexColorProperty
            return string.format("lighting: %d, source: %d", prop.lighting, prop.source)
        end,
        ["NiWireframeProperty"] = function()end,
        ["NiZBufferProperty"] = function()end,
    }
    local f = func[prop.RTTI.name]
    if f then
        return f()
    end
    return nil
end

---@param effect niAmbientLight|niDirectionalLight|niPointLight|niSpotLight|niTextureEffect
---@return string?
local function DumpDynamicEffect(effect)
    ---@type { [string] : fun() :string? }
    local func = {
        ["NiAmbientLight"] = function()
        end,
        ["NiDirectionalLight"] = function()
        end,
        ["NiPointLight"] = function()
            -- local affected = {}
            -- ---@cast effect niPointLight
            -- local node = effect.affectedNodes
            -- while node do
            --     if node.data then
            --         table.insert(affected, node.data.name)
            --     end
            --     node = node.next
            -- end
            -- return table.concat(affected)
        end,
        ["NiSpotLight"] = function()
        end,
        ["NiTextureEffect"] = function()
        end,
    }
    local f = func[effect.RTTI.name]
    if f then
        return f()
    end
    return nil
end

---@param root niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
---@return string
function this.Dump(root)
    if not config.development.experimental then
        return "Enable experimental to dump the scene graph."
    end
    -- TODO json format
    local str = {}
    this.foreach(root,
        function(node, depth)
            local indent = string.rep("    ", depth)
            if node then
                local out = string.format("%s:%s", node.RTTI.name, tostring(node.name))
                if node.translation and node.rotation and node.scale then
                    out = out .. "\n" .. indent .. string.format("  local trans %s, rot %s, scale %f", node.translation, node.rotation, node.scale)
                end
                if node.worldTransform then
                    out = out .. "\n" .. indent .. string.format("  world trans %s, rot %s, scale %f", node.worldTransform.translation, node.worldTransform.rotation, node.worldTransform.scale)
                end
                local props = node.properties
                while props and props.data do
                    out = out .. "\n" .. indent .. string.format("  prop: %s", props.data.RTTI.name)
                    local p = DumpProperty(props.data)
                    if p then
                        out = out .. "\n" .. p .. string.format(" propertyFlags: %d", props.data.propertyFlags)
                    end
                    props = props.next
                end
                local effect = node.effectList
                while effect and effect.data do
                    out = out .. "\n" .. indent .. string.format("  effect: %s", effect.data.RTTI.name)
                    local p = DumpDynamicEffect(effect.data)
                    if p then
                        out = out .. "\n" .. p
                    end
                    effect = effect.next
                end

                table.insert(str, indent .. "- " .. out)
            else
                table.insert(str, indent .. "- " .. "nil")
            end
        end)
    -- return str
    return "\n" .. table.concat(str, "\n")
end

return this
