---@class ModInfo
---@field name string name of the mod to use in logInfo
---@field l10nName string Name of the l10n context
---@field description string
---@field version integer
---@field logPrefix string Mostly self explanatory, but generally should include a space for ease of use.

---@type ModInfo
return {
    name = 'StarwindV4',
    l10nName = 'StarwindVersion4',
    description = 'Modernized version of the Starwind mod, with new features and bug fixes by way of its Lua reimplementation.',
    version = 16,
    logPrefix = '[ StarwindV4 ]: ',
}