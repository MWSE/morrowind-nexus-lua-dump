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

return this