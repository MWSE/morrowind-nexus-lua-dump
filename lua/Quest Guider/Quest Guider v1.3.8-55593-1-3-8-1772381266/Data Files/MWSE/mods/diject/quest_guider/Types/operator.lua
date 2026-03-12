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


---@param operator integer
---@return integer
function this.invert(operator)
    return (operator == 48 and 49) or
        (operator == 49 and 48) or
        (operator == 50 and 53) or
        (operator == 51 and 52) or
        (operator == 52 and 51) or
        (operator == 53 and 50) or 48
end


return this