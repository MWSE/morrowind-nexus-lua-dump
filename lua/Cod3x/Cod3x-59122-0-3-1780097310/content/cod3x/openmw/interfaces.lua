---@meta

-- LuaLS stub for the dynamic OpenMW script interface registry.
-- The runtime table is populated by scripts that return { interfaceName = ..., interface = ... }.
-- Built-in OpenMW interfaces are listed as mandatory fields; mods may extend this class in sidecar stubs.

---@class openmw.interfaces: table<string, any>
---@field Activation openmw.interfaces.Activation Built-in contexts: global.
---@field AnimationController openmw.interfaces.AnimationController Built-in contexts: local.
---@field AI openmw.interfaces.AI Built-in contexts: local.
---@field Camera openmw.interfaces.Camera Built-in contexts: player.
---@field Combat openmw.interfaces.Combat
---@field MWUI openmw.interfaces.MWUI Built-in contexts: menu|player.
---@field Settings openmw.interfaces.Settings Built-in contexts: global|menu|player.
---@field UI openmw.interfaces.UI Built-in contexts: player.
---@field ItemUsage openmw.interfaces.ItemUsage Built-in contexts: global.
---@field SkillProgression openmw.interfaces.SkillProgression Built-in contexts: player.
---@field Crimes openmw.interfaces.Crimes Built-in contexts: global.
---@field Controls openmw.interfaces.Controls Built-in contexts: player.
---@field GamepadControls openmw.interfaces.GamepadControls Built-in contexts: player.
local interfaces = {}

---@param self openmw.interfaces
---@param key string
---@return any
function interfaces.__index(self, key) end

return interfaces
