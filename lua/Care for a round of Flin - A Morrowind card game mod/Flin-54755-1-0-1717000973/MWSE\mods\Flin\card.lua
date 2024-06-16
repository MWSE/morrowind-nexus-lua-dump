local lib = require("Flin.lib")

-- card class
--- @class Card
--- @field value EValue?
--- @field suit ESuit?
local Card = {
    value = nil,
    suit = nil
}

-- constructor
--- @param suit ESuit
--- @param value EValue
--- @return Card
function Card:new(suit, value)
    ---@type Card
    local newObj = {
        suit = suit,
        value = value
    }
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end

---@return string
function Card:toString()
    return string.format("%s %s",
        lib.suitToString(self.suit),
        lib.valueToString(self.value)
    )
end

return Card
