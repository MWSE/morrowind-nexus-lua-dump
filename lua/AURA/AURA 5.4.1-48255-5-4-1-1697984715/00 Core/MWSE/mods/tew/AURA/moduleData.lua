return {
    ["outdoor"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        playWindoors = true,
        blockedWeathers = {
            [5] = true,
            [6] = true,
            [7] = true,
            [9] = true,
        },
        soundConfig = {
            ["big"] = {
                [0] = {pitch = 0.8},
                [1] = {pitch = 0.8},
                [2] = {pitch = 0.78},
                [3] = {pitch = 0.79},
                [4] = {pitch = 0.79},
                [8] = {pitch = 0.82},
            },
            ["sma"] = {
                [0] = {pitch = 0.85},
                [1] = {pitch = 0.85},
                [2] = {pitch = 0.83},
                [3] = {pitch = 0.82},
                [4] = {pitch = 0.8},
                [8] = {pitch = 0.87},
            },
            ["ten"] = {
                [0] = {pitch = 0.85},
                [1] = {pitch = 0.85},
                [2] = {pitch = 0.83},
                [3] = {pitch = 0.82},
                [4] = {pitch = 0.8},
                [8] = {pitch = 0.87},
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
    ["populated"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        blockedWeathers = {
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
        },
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
        blockedWeathers = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [8] = true,
        },
        soundConfig = {
            ["big"] = {
                [4] = {mult = 0.85, pitch = 1.0},
                [5] = {mult = 0.8, pitch = 1.0},
                [6] = {mult = 0.4, pitch = 0.75},
                [7] = {mult = 0.4, pitch = 0.75},
                [9] = {mult = 0.4, pitch = 0.75}
            },
            ["sma"] = {
                [4] = {mult = 0.75, pitch = 1.0},
                [5] = {mult = 0.65, pitch = 1.0},
                [6] = {mult = 0.35, pitch = 0.6},
                [7] = {mult = 0.35, pitch = 0.6},
                [9] = {mult = 0.35, pitch = 0.6}
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
        playWindoors = true,
        blockedWeathers = {
            [6] = true,
            [7] = true,
            [9] = true,
        },
        soundConfig = {
            ["big"] = {
                [0] = {pitch = 0.82},
                [1] = {pitch = 0.82},
                [2] = {pitch = 0.81},
                [3] = {pitch = 0.8},
                [4] = {pitch = 0.8},
                [5] = {pitch = 0.79},
                [8] = {pitch = 0.78},
            },
            ["sma"] = {
                [0] = {pitch = 0.8},
                [1] = {pitch = 0.8},
                [2] = {pitch = 0.79},
                [3] = {pitch = 0.78},
                [4] = {pitch = 0.78},
                [5] = {pitch = 0.77},
                [8] = {pitch = 0.76},
            },
            ["ten"] = {
                [0] = {pitch = 0.8},
                [1] = {pitch = 0.8},
                [2] = {pitch = 0.79},
                [3] = {pitch = 0.78},
                [4] = {pitch = 0.78},
                [5] = {pitch = 0.77},
                [8] = {pitch = 0.76},
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
    ["rainOnStatics"] = {
        old = nil,
        new = nil,
        oldRef = nil,
        newRef = nil,
        lastVolume = nil,
        blockedWeathers = {
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
        },
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