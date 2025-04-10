local function setupCustomRaceSpeech()
    speechCollections["tartarian"] = {
        default = {
            folderPath = "a",
            malePrefix = "AM",
            femalePrefix = "AF",
            maleFiles = {
                attack = { count = 15 },
                flee = { count = 5 },
                follower = { count = 3 },
                hello = { count = 139 },
                hit = { count = 16, skip = { 11 } },
                idle = { count = 8 },
                intruder = { count = 9, skip = { 7 }, indexPrefixOverride = "OP" },
                service = { count = 12 },
                thief = { count = 5 }
            },
            femaleFiles = {
                attack = { count = 17, skip = { 11, 15, 16 } },
                flee = { count = 5 },
                follower = { count = 6 },
                hello = { count = 139 },
                hit = { count = 16 },
                idle = { count = 8 },
                oppose = { count = 8 },
                service = { count = 12 },
                thief = { count = 5 }
            }
        }
    }

    speechCollections["ratkinn"] = {
        default = {
            folderPath = "k",
            malePrefix = "KM",
            femalePrefix = "KF",
            maleFiles = {
                attack = { count = 15, skip = { 11 } },
                flee = { count = 5 },
                follower = { count = 3 },
                hello = { count = 139 },
                hit = { count = 16 },
                idle = { count = 9 },
                intruder = { count = 9, skip = { 7 }, indexPrefixOverride = "OP" },
                service = { count = 9 },
                thief = { count = 5 }
            },
            femaleFiles = {
                attack = { count = 15, skip = { 11 } },
                flee = { count = 5 },
                follower = { count = 6 },
                hello = { count = 139 },
                hit = { count = 16 },
                idle = { count = 9 },
                oppose = { count = 8 },
                service = { count = 12 },
                thief = { count = 5 }
            }
        }
    }

    speechCollections["skeletonrace"] = {
        default = {
            folderPath = "h",
            malePrefix = "HM",
            femalePrefix = "HF",
            maleFiles = {
                attack = { count = 15 },
                flee = { count = 5 },
                follower = { count = 6 },
                hello = { count = 138 },
                hit = { count = 15, skip = { 14 } },
                idle = { count = 9 },
                oppose = { count = 8 },
                service = { count = 25 },
                thief = { count = 5 }
            },
            femaleFiles = {
                attack = { count = 15 },
                flee = { count = 5 },
                follower = { count = 6 },
                hello = { count = 138 },
                hit = { count = 15 },
                idle = { count = 8 },
                oppose = { count = 8 },
                service = { count = 18 },
                thief = { count = 5 }
            }
        }
    }
end

customEventHooks.registerHandler("OnServerPostInit", function()
    setupCustomRaceSpeech()
end)
