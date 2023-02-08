---@meta

---@class craftingFrameworkSkillRequirementData
---@field skill string **Required.** The name of the skill of this `skillRequirement`. If vanilla skill, it needs to be a camelCased name of the skill. Supports skills added with the Skills Module.
---@field requirement number **Required.** The needed skill value to pass this `skillRequirement`'s skill check.
---@field maxProgress number *Default*: `30`. The maximal amount of experience the player can get, when crafting an item that has this `skillRequirement`.


---@class craftingFrameworkSkillRequirement
---@field skill string The name of the skill of this `skillRequirement`. If vanilla skill, it needs to be a camelCased name of the skill. Supports skills added with the Skills Module.
---@field requirement number The needed skill value to pass this `skillRequirement`'s skill check.
---@field maxProgress number The maximal amount of experience the player can get, when crafting an item that has this `skillRequirement`.
craftingFrameworkSkillRequirement = {}

---Creates a new skillRequirement object.
---@param data craftingFrameworkSkillRequirementData This table accepts following values:
---
--- `skill`: string — **Required.** The name of the skill of this `skillRequirement`. If vanilla skill, it needs to be a camelCased name of the skill. Supports skills added with the Skills Module.
---
--- `requirement`: number — **Required.** The needed skill value to pass this `skillRequirement`'s skill check.
---
--- `maxProgress`: number — *Default*: `30`. The maximal amount of experience the player can get, when crafting an item that has this `skillRequirement`.
---@return craftingFrameworkSkillRequirement skillRequirement
function craftingFrameworkSkillRequirement:new(data) end

---This method returns the player's current skill value of this `skillRequirement.skill`. Supports skills added with the Skills Module.
---@return number|nil
function craftingFrameworkSkillRequirement:getCurrent() end

---This method returns the vanilla game skillId (1-based).
---@return number skillId
function craftingFrameworkSkillRequirement:getVanillaSkill() end

---This method will progress the player's skill associated with this `skillRequirement`. The progress amount equals to `maxProgress` value multiplied by the difference multiplier. This multiplier is higher when the current skill is low.
function craftingFrameworkSkillRequirement:progressSkill() end

---This method returns the name of the skill. For vanilla skills, it reads the names from skill name GMSTs. Supports skills added with the Skills Module.
---@return string name
function craftingFrameworkSkillRequirement:getSkillName() end

---Checks if the player has the required skill level.
---@return boolean passed
function craftingFrameworkSkillRequirement:check() end
