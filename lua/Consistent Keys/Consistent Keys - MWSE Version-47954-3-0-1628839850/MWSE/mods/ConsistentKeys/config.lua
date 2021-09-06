local defaultConfig = {
    enable = true,
    changeNames = true,
    truncateLong = true,
    weightValue = true,
    isKeyFlag = true,
    logging = false,
    blacklists = {
        overall = {
            ["bm_bearheart_unique"] = true,
            ["bm_seeds_unique"] = true,
        },
        names = {
            ["key_shashev"] = true,
        },
    },
}

return mwse.loadConfig("ConsistentKeys") or defaultConfig