local config = mwse.loadConfig('cover_yourself')

-- Everything is enabled by default except rings and amulets.
if config == nil then
    config = {}
    config.clothing = {}
    config.armor = {}
    config.blacklist = {}
    config.blacklist.clothing = {}
    config.blacklist.armor = {}
    for _, id in pairs(tes3.clothingSlot) do
        config.clothing[tostring(id)] = true
    end
    config.clothing[tostring(tes3.clothingSlot.ring)] = false
    config.clothing[tostring(tes3.clothingSlot.amulet)] = false
    for _, id in pairs(tes3.armorSlot) do
        config.armor[tostring(id)] = true
    end
    config.smart_filter = true
    config.gender_filter = false
end

return config