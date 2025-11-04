local this = {}

---@type niNode
local LEECH_MESH = nil

---@type niAVObject[]
local ATTACH_POINTS = {}
local ATTACH_CHANCE = 0.12

function this.range(n)
    local t = {}
    for i = 1, n do
        t[#t + 1] = i
    end
    return t
end

function this.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

--- Return a random number between min and max.
---@param min number
---@param max number
function this.rand(min, max)
    return min + (max - min) * math.random()
end

---@return niNode
function this.getLeechMesh()
    if LEECH_MESH == nil then
        LEECH_MESH = assert(tes3.loadMesh("leeches\\leech.nif"))
    end
    return LEECH_MESH:clone() ---@diagnostic disable-line
end

---@return niAVObject[]
function this.getAttachPoints()
    if not next(ATTACH_POINTS) then
        local mesh = tes3.loadMesh("leeches\\xbase_anim_leeches.nif")
        for node in table.traverse(mesh.children) do
            if node:isInstanceOfType(ni.type.NiTriShape) then
                table.insert(ATTACH_POINTS, node)
            end
        end
    end
    return ATTACH_POINTS
end

---@param ref tes3reference
function this.getAttachChance(ref)
    if ref.cell.id == "Hlormaren, Cultist Lair" then
        return 1.0
    end
    return ATTACH_CHANCE
end

---@param cell tes3cell
function this.isBitterCoastRegion(cell)
    if cell.isInterior then
        return cell.id == "Hlormaren, Cultist Lair"
    end
    return cell.region.id == "Bitter Coast Region"
end

---@return boolean
function this.isInWater(ref)
    local waterLevel = ref.cell.waterLevel or 0
    return ref.position.z < (waterLevel - 20)
end

---@return fun():tes3reference
function this.bitterCoastActorRefs()
    return coroutine.wrap(function()
        if this.isBitterCoastRegion(tes3.player.cell) then
            coroutine.yield(tes3.player)
        end
        for _, cell in ipairs(tes3.getActiveCells()) do
            if this.isBitterCoastRegion(cell) then
                for ref in cell:iterateReferences(tes3.objectType.npc) do
                    if not (ref.disabled or ref.deleted) then
                        coroutine.yield(ref)
                    end
                end
            end
        end
    end)
end

---@return fun():niNode
function this.get1stAnd3rdSceneNode(ref)
    return coroutine.wrap(function()
        coroutine.yield(ref.sceneNode)
        if ref == tes3.player then
            coroutine.yield(tes3.player1stPerson.sceneNode)
        end
    end)
end

--- Optimized (cached) version of `tes3.getReference`.
---
---@param id string
---@return tes3reference?
function this.getReference(id)
    ---@type table<string, mwseSafeObjectHandle>
    local cache = table.getset(tes3.player.tempData, "getReferenceCache", {})

    -- Return the cached reference if it exists.
    local handle = cache[id]
    if handle and handle:valid() then
        return handle:getObject()
    end

    -- Otherwise get the reference and cache it.
    local ref = tes3.getReference(id)
    if ref then
        cache[id] = tes3.makeSafeObjectHandle(ref)
        return ref
    end
end

return this
