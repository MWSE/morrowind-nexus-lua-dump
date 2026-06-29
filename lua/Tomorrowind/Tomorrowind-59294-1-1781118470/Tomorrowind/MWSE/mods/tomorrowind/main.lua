--[[
	Tomorrowind — Emissive Rave Edition

	An entry to the Mollython 2026.

]] local log = mwse.Logger.new({
    name = "Tomorrowind",
    level = mwse.logLevel.debug
})

local GEOMETRY = ni.type.NiTriBasedGeom
local NODE = ni.type.NiNode

---@return number r, number g, number b
local function randomGlow()
    local r, g, b = math.random(), math.random(), math.random()
    local max = math.max(r, g, b, 0.001)
    return r / max, g / max, b / max
end

---@param shape niAVObject
local function recolor(shape)
    if not shape:isInstanceOfType(GEOMETRY) then return end

    local r, g, b = randomGlow()
    local src = shape.materialProperty
    local mat = (src and src:clone() or niMaterialProperty.new()) --[[@as niMaterialProperty]]

    -- All three channels — see header note on NiVertexColorProperty.
    -- IMPORTANT: the color getters return a COPY, so `mat.emissive.r = x`
    -- mutates a throwaway and never persists. We must assign a whole niColor
    -- to invoke the real setter.
    local color = niColor.new(r, g, b)
    mat.ambient = color
    mat.diffuse = color
    mat.emissive = color
    mat.alpha = 1

    -- Attaching to the shape itself overrides any inherited material.
    shape.materialProperty = mat
    mat:incrementRevisionId()
    -- Rebuild the renderer's per-geometry effective-material cache; without
    -- this, draws keep using the stale cached material.
    shape:updateProperties()
end

--- Recolor every geometry leaf under a scene-graph node.
---
--- We recurse manually instead of using niNode:traverse({type=...}): that C
--- binding null-derefs (hard crash) on nil child entries when a type filter is
--- set, and skinned actor skeletons routinely have nil children. The manual
--- walk below skips nil slots safely.
---@param node niAVObject?
local function recolorTree(node)
    if not node then return end

    recolor(node) -- no-op unless `node` is itself geometry

    if node:isInstanceOfType(NODE) then
        local children = (node --[[@as niNode]]).children
        if children then
            for i = 1, #children do
                recolorTree(children[i]) -- nil slots handled by the guard above
            end
        end
    end
end

-- New meshes as they stream in from disk.
---@param e meshLoadedEventData
local function onMeshLoaded(e)
    if not tes3.player then return end
    recolorTree(e.node)
end
event.register(tes3.event.meshLoaded, onMeshLoaded)

-- Everything already on screen — independent of the mesh cache.
local function recolorLoadedWorld()
    for _, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            if ref.sceneNode then recolorTree(ref.sceneNode) end
        end
    end
    log:debug("Recolored the active cells.")
end
event.register(tes3.event.loaded, recolorLoadedWorld)
event.register(tes3.event.cellChanged, recolorLoadedWorld)

log:info("Tomorrowind loaded — the world will now glow.")
