local core = require('openmw.core')

local module = {
    MOD_NAME = "StatCounters",
    savedGameVersion = 0.5,
    -- Requires OpenMW 0.51+
    -- DialogueResponse support is used by the People Met and Insults counters.
    minAPIRevision = 75,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.renderers = {
    number = key("number"),
    resetButton = key("resetButton"),
}

return module
