local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Ability")

---@class GuarWhisperer.Ability.TargetData
---@field reference? tes3reference
---@field intersection? tes3vector3
---@field playerTarget? tes3reference

---@class GuarWhisperer.Ability.params
---@field targetData GuarWhisperer.Ability.TargetData
---@field activeCompanion GuarWhisperer.GuarCompanion
---@field inMenu boolean

---@class GuarWhisperer.Ability.newParams
---@field id string The unique id of this ability
---@field label fun(e: GuarWhisperer.Ability.params): string A function that returns the label for this command
---@field labelColor? string *Default: "normal_color"* The color of the label, must be valid for tes3.getPalette()
---@field description string A description of this command
---@field command fun(e: GuarWhisperer.Ability.params) A function that is called when this command is selected
---@field doSteal? boolean TODO: replace with labelColor
---@field requirements fun(e: GuarWhisperer.Ability.params): boolean A function that returns true if the guar meets the requirements to perform this command
---@field priority? number Determines the order the command appears in the menu



---@class GuarWhisperer.Ability : GuarWhisperer.Ability.newParams
local Ability = {
    registeredAbilities = {}
}

---@param e GuarWhisperer.Ability.newParams
function Ability.register(e)
    local ability = Ability:new(e)
    logger:debug("Registering ability %s", ability.id)
    Ability.registeredAbilities[ability.id] = ability
end

function Ability.get(id)
    return Ability.registeredAbilities[id]
end

function Ability:new(ability)
    ability = ability or {}
    setmetatable(ability, self)
    self.__index = self
    return ability
end

return Ability