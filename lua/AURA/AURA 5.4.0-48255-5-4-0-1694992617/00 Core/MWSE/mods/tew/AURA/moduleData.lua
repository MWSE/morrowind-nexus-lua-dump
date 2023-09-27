return {
    ["outdoor"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        playUnderwater = true,
        playWindoors = true,
        soundConfig = {},
        faderData = {
            ["out"] = {
                duration = 5.0,
                inProgress = {},
            },
            ["in"] = {
                duration = 5.0,
                inProgress = {},
            },
        },
    },
    ["populated"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        playUnderwater = true,
        soundConfig = {},
        faderData = {
            ["out"] = {
                duration = 4.0,
                inProgress = {},
            },
            ["in"] = {
                duration = 4.0,
                inProgress = {},
            },
        },
    },
    ["interior"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        soundConfig = {},
        faderData = {
            ["out"] = {
                duration = 3.0,
                inProgress = {},
            },
            ["in"] = {
                duration = 3.0,
                inProgress = {},
            },
        },
	},
	["interiorWeather"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        playWindoors = true,
        soundConfig = {
            ["sma"] = {
                [4] = {mult = 0.7, pitch = 1.0},
                [5] = {mult = 0.65, pitch = 1.0},
                [6] = {mult = 0.35, pitch = 0.6},
                [7] = {mult = 0.35, pitch = 0.6},
                [9] = {mult = 0.35, pitch = 0.6}
            },
            ["big"] = {
                [4] = {mult = 0.8, pitch = 1.0},
                [5] = {mult = 0.8, pitch = 1.0},
                [6] = {mult = 0.4, pitch = 0.75},
                [7] = {mult = 0.4, pitch = 0.75},
                [9] = {mult = 0.4, pitch = 0.75}
            },
            ["ten"] = {
                [4] = {mult = 1.0, pitch = 1.0},
                [5] = {mult = 0.9, pitch = 1.0},
                [6] = {mult = 0.4, pitch = 0.8},
                [7] = {mult = 0.4, pitch = 0.8},
                [9] = {mult = 0.4, pitch = 0.8}
            }
        },
        faderData = {
            ["out"] = {
                duration = 5.0,
                inProgress = {},
            },
            ["in"] = {
                duration = 5.0,
                inProgress = {},
            },
        },
	},
    ["wind"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        playUnderwater = true,
        playWindoors = true,
        soundConfig = {},
        faderData = {
            ["out"] = {
                duration = 5.0,
                inProgress = {},
            },
            ["in"] = {
                duration = 5.0,
                inProgress = {},
            },
        },
    },
    ["rainOnStatics"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        soundConfig = {
            ["light"] = {
                [4] = {mult = 1.0, pitch = 1.0},
                [5] = {mult = 1.0, pitch = 1.0},
            },
            ["medium"] = {
                [4] = {mult = 0.7, pitch = 1.0},
                [5] = {mult = 0.8, pitch = 1.0},
            },
            ["heavy"] = {
                [4] = {mult = 0.7, pitch = 1.0},
                [5] = {mult = 0.8, pitch = 1.0},
            },
        },
        faderData = {
            ["out"] = {
                duration = 0.7,
                inProgress = {},
            },
            ["in"] = {
                duration = 0.7,
                inProgress = {},
            },
        },
    },
}