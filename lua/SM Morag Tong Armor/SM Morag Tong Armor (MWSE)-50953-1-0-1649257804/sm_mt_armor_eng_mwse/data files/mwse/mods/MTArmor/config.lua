local defaultConfig = {
    modEnabled = true,
    replaceArmor = true,
    addFullSetTo = {},
    dontReplaceArmorOf = {
        huleeya = true,
        ["gluronk gra-shula"] = true
    },
}

local mwseConfig = mwse.loadConfig("MTArmor", defaultConfig)

return mwseConfig