


---@class GuarWhisperer.Syntax
---@field name string The name of the guar
---@field gender GuarWhisperer.Gender The gender of the guar
---@field substitutions table<string, function> A table of substitutions to make when formatting a string
local Syntax = {}

---@param e {name: string, gender: GuarWhisperer.Gender}
---@return GuarWhisperer.Syntax
function Syntax.new(e)
    local self = setmetatable({}, { __index = Syntax })
    self.gender = e.gender or ""
    self.name = e.name
    self.substitutions = {}
    return self
end

---Returns the string "He", "She" or "It",
--- depending on the configured gender.
---@return "he" | "she" | "it"
function Syntax:getHeShe()
    local map = {
        male = "he",
        female = "she",
        none = "it"
    }
    local name =  map[self.gender] or map.none
    return name
end

---Returns the string "Him", "Her" or "It",
--- depending on the configured gender.
---@return "him" | "her" | "it"
function Syntax:getHimHer()
    local map = {
        male = "him",
        female = "her",
        none = "it"
    }
    local name =  map[self.gender] or map.none
    return name
end

---Returns the string "His", "Her" or "Its",
--- depending on the configured gender.
---@return "his" | "her" | "its"
function Syntax:getHisHer()
    local map = {
        male = "his",
        female = "her",
        none = "its"
    }
    local name =  map[self.gender] or map.none
    return name
end

function Syntax:getMaleFemale()
    return self.gender
end


return Syntax