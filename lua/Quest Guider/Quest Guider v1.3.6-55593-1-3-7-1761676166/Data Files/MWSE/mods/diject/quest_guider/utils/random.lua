local this = {}

local function getStringHash(str)
    if not str then return 0 end
    local ret = 0
    local length = #str
    for i = 1, length do
        local byte = string.byte(str, i)
        ret = ret + byte * i
    end
    return ret
end

---@param str string
function this.setSeedByStringHash(str)
    local playerHash = 0
    if tes3.player then
        playerHash = getStringHash(tes3.player.object.name)
    end
    local seed = getStringHash(str) + playerHash
    math.randomseed(seed % 1000000000)
end

function this.resetRandomSeed()
    math.randomseed(os.time())
end


---@param vector tes3vector3
---@param radius number
---@return tes3vector3
function this.changeVectorPosByRandomInRadius(vector, radius)
    local theta = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * radius
    local x = r * math.cos(theta)
    local y = r * math.sin(theta)

    vector.x = vector.x + x
    vector.y = vector.y + y

    return vector
end

return this