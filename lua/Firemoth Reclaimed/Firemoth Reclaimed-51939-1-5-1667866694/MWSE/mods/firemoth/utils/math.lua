local this = {}

local XY = tes3vector3.new(1, 1, 0)

---@param rangeX number
---@param rangeY number
---@param rangeZ number
---@return tes3matrix33
function this.getRandomRotation(rangeX, rangeY, rangeZ)
    local x = math.rad(math.random(-rangeX, rangeX))
    local y = math.rad(math.random(-rangeY, rangeY))
    local z = math.rad(math.random(-rangeZ, rangeZ))
    local r = tes3matrix33.new()
    r:fromEulerXYZ(x, y, z)
    return r
end

---@param node niNode
---@param translation tes3vector3
function this.setWorldTranslation(node, translation)
    if node.parent then
        local t = node.parent.worldTransform
        translation = (t.rotation * t.scale):transpose() * (translation - t.translation)
    end
    node.translation = translation
end

---@param a tes3vector3
---@param b tes3vector3
---@return number
function this.xyDistance(a, b)
    return (a * XY):distance(b * XY)
end

---@param min number
---@param max number
function this.nonRepeatNumberRNG(min, max)
    local n = 0
    return function()
        n = (n + math.random(min, max - 1) - 1) % max + 1
        return n
    end
end

---@param t table
function this.nonRepeatTableRNG(t)
    local randomIndex = this.nonRepeatNumberRNG(1, #t)

    return function()
        return t[randomIndex()]
    end
end

---@param position tes3vector3
---@param references table<tes3reference, any>
---@return tes3reference, number
function this.getClosestReference(position, references)
    local reference = nil
    local distance = math.fhuge

    for ref in pairs(references) do
        local dist = position:distance(ref.position)
        if dist < distance then
            reference = ref
            distance = dist
        end
    end

    return reference, distance
end

---@param position tes3vector3
---@param references table<tes3reference, any>
---@return tes3reference, number
function this.getFarthestReference(position, references)
    local reference = nil
    local distance = 0

    for ref in pairs(references) do
        local dist = position:distance(ref.position)
        if dist > distance then
            reference = ref
            distance = dist
        end
    end

    return reference, distance
end

return this
