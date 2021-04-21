return mwse.loadConfig("ConsistentKeys") or {
    enable = true,
    blacklist = {
        ["key_shashev"] = true,
    },
}