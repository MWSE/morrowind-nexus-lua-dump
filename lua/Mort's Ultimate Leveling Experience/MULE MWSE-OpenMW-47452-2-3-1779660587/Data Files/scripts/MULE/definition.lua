local module = {
    MOD_NAME = "MULE",
    savedGameVersion = 1.0,
}

local function key(suffix)
    return string.format("%s_%s", module.MOD_NAME, suffix)
end

module.events = {
    onSkillLevelUp = key("on_skill_level_up"),
}

return module
