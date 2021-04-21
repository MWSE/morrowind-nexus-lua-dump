local defaultConfig = {
    version = "Reactive Resistance 1.0",
    universalDisableTime = 5,
    useUniversalDisableTime = true,
    universalTimeOutTime = 5 * 60,
    useUniversalTimeOutTime = true,
    effects = {
        paralyze = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = false,
            scale = 0
        },
        commandCreature = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = false,
            scale = 0
        },
        commandHumanoid = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = false,
            scale = 0
        },
        blind = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 100
        },
        calmCreature = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 50
        },
        calmHumanoid = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 50
        },
        demoralizeCreature = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 50
        },
        demoralizeHumanoid = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 50
        },
        turnUndead = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 50
        },
        burden = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 250
        },
        drainAttribute = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 100
        },
        absorbAttribute = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 100
        },
        damageAttribute = {
            resist = true,
            disableTime = 5,
            timeOutTime = 5 * 60,
            compound = true,
            scale = 5
        },
    },
    aryonsDominatorOverride = true,
    spearOfTheHuntOverride = false,
}
local config = mwse.loadConfig("Reactive Resistance", defaultConfig)
return config