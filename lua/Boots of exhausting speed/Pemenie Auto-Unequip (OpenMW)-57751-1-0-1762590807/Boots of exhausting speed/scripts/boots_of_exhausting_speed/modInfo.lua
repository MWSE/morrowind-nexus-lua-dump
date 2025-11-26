local CHANGES = [[
	Pemenie cleverly unequips her boots (or pants) of exhausting speed when she is exhausted.
]]

return setmetatable({
    MOD_NAME = "Pemenie auto-unequip",
    MOD_VERSION = 1.0,
    MIN_API = 48, -- TODO: Figure out correct value for this
    CHANGES = CHANGES
}, {
    __tostring = function(modInfo)
	return string.format("\n[%s]\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME, modInfo.MOD_VERSION,
	    modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

