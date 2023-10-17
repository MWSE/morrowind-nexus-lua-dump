---@class Fishing.config
local config = {}
config.configPath = "UltimateFishing"
config.metadata = toml.loadFile("Data Files\\UltimateFishing-metadata.toml")
---@class Fishing.config.constants
config.constants = {
    --How many times to try to find a valid position for a fish startPosition
    FISH_POSITION_ATTEMPTS = 50,
    --Minimum distance from lure to fish start position
    FISH_POSITION_DISTANCE_MIN = 300,
    --Maximum distance from lure to fish start position
    FISH_POSITION_DISTANCE_MAX = 600,
    --The interval between ripples when a fish is moving
    FISH_RIPPLE_INTERVAL = 0.05,
    --Fish Speed
    FISH_SPEED = 75,
    --The minimum distance the fish must be away from the shore
    WATER_POSITION_PADDING = 200,

    --Fishing line
    MIN_CAST_SPEED = 150,
    MAX_CAST_SPEED = 600,

    --The max distance the lure can be from the player before the line breaks
    FISHING_LINE_MAX_DISTANCE = 5000,
    MIN_DEPTH = 40,

    TENSION_NEUTRAL = 1.0,
    TENSION_MINIMUM = 0.2,
    TENSION_MAXIMUM = 1.8,
    FIGHT_TENSION_UPPER_LIMIT = 1.5,
    FIGHT_TENSION_LOWER_LIMIT = 0.5,

    --The effect of distance while reeling in
    FIGHT_REELING_DISTANCE_EFFECT = 150,
    --How fast tension increases while reeling in
    REEL_LENGTH_PER_SECOND = 300,
    --How fast the tension relaxes when not reeling
    RELAX_LENGTH_PER_SECOND = 150,
    --the distance at which tension will reach breaking point
    FIGHT_MAX_DISTANCE = 300,
    --Base level of fatigue drain for a fish during a fight
    FIGHT_FATIGUE_DRAIN_PER_SECOND = 5,
    ---Minimum distance to next target during fight
    FIGHT_POSITION_MIN_DISTANCE = 50,
    ---Maximum distance to next target during fight
    FIGHT_POSITION_MAX_DISTANCE = 150,

    --player fatigue
    --the amount of fatigue drained per second when the player is reeling
    FIGHT_PLAYER_FATIGUE_REELING_DRAIN_PER_SECOND = 15,
    --the amount of fatigue drained per second when the player is relaxing
    FIGHT_PLAYER_FATIGUE_RELAX_DRAIN_PER_SECOND = 3,

    -- The amount of rod damage while reeling per second
    FIGHT_ROD_DAMAGE_PER_SECOND = 0.25,

    --The a multiplier on the distance towards the player the fish will pull based on tension
    FIGHT_TENSION_DISTANCE_EFFECT_MAXIMUM = 0.5,

    --Tooltips
    TOOLTIP_COLOR_BAIT = {
        147 / 255,
        181 / 255,
        189 / 255,
    },

    MIN_BITE_CHANCE = 0.25,
    MAX_BITE_CHANCE = 0.75,

    UNCLAMP_WAVES_DURATION = 0.5,
}


---@class Fishing.config.persistent
local persistentDefault = {
    ---@type Fishing.fishingState|nil
    fishingState = nil,
    ---@type table<string, number> The number of each fish type caught
    fishTypesCaught = {}
}

---@class Fishing.config.MCM
local mcmDefault = {
    enabled = true,
    enableFishTooltips = true,
    easyHook = false,
    cheatMode = false,
    logLevel = "INFO",
    fishingMerchants = {
        ["arrille"] = true,--seyda neen trader - high elf - 800
        ["goldyn belaram"] = true,--suran pawnbroker - Dark Elf - 450
        ["clagius clanler"] = true,--balmora outfitter - Imperial - 800
        ["fadase selvayn"] = true,--tel branora trader - Dark Elf - 500
        ["tiras sadus"] = true,--ald'ruhn trader - Dark Elf - 799
        ["heifnir"] = true,--dagon fel trader - Nord - 700
        ["ancola"] = true,--sadrith mora trader - Redguard - 800
        ["ababael timsar-dadisun"] = true,--super pro ashlander merchant - Dark Elf - what 9000
        ["shulki ashunbabi"] = true,--Gnisis trader - Dark Elf - 400
        ["perien aurelie"] = true, --hla-oad pawnbroker - Breton - 150
        ["thongar"] = true,--Khuul trader/fake inkeeper - Nord - 1200
        ["vasesius viciulus"] = true,--Molag mar trader - Imperial - 1000
        ["sedam omalen"] = true,--Ald Velothi's only trader - Dark Elf 400
        ["ferele athram"] = true, --Tel Aruhn trader
    },
}
---@type Fishing.config.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)
---Save the current config.mcm to the config file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end
---@type Fishing.config.persistent
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        if tes3.player.data[config.configPath][key] == nil then
            tes3.player.data[config.configPath][key] = persistentDefault[key]
        end
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config