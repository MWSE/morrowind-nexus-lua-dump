local this = {}

this.value = {
    Equal = 48,
    NotEqual = 49,
    Greater = 50,
    GreaterOrEqual = 51,
    Less = 52,
    LessOrEqual = 53,
}

this.name = {
    [48] = "equal",
    [49] = "not equal",
    [50] = "greater",
    [51] = "greater or equal",
    [52] = "less",
    [53] = "less or equal",
}

---@param a any
---@param b any
---@param operator integer
---@return boolean
function this.check(a, b, operator)
    return (operator == 48 and a == b) or
        (operator == 49 and a ~= b) or
        (operator == 50 and a > b) or
        (operator == 51 and a >= b) or
        (operator == 52 and a < b) or
        (operator == 53 and a <= b)
end

return this