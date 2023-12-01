local this = {}


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

return this
