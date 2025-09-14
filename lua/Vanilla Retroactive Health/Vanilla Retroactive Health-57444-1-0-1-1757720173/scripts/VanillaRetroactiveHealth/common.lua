local metadata = {
    modId = 'VanillaRetroactiveHealth',
    modName = 'Vanilla Retroactive Health',
}

local events = {
    RetroactiveHealthModeChanged = metadata.modId .. "RetroactiveHealthModeChanged"
}

return {
    events = events,
    metadata = metadata
}
