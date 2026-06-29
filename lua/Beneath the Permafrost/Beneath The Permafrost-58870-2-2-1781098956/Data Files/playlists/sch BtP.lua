local FjollvintRegion = {
    ["fjollvint region"] = true,
}

local HjelmgaardCells = {
    allowed = {
        "hjelmgaard",
    },
}

local DungeonCells = {
    ["morasil skarr"] = true,

    ["the frozen crypt of nhar'zekhaal"] = true,
    ["the frozen crypt of nhar’zekhaal"] = true,

    ["the frozen crypt of nhar'zekhaal, chamber of the lich"] = true,
    ["the frozen crypt of nhar’zekhaal, chamber of the lich"] = true,

    ["vvardaguul, inner shrine"] = true,
    ["vvardaguul, shrine"] = true,

    ["vethrakh's maw"] = true,
    ["vethrakh’s maw"] = true,
}

local function addCopies(tracks, path, count)
    for i = 1, count do
        tracks[#tracks + 1] = path
    end
end

local function hjelmgaardTracks()
    local tracks = {
        "Music/sch/SouD/Epl_Gen01.mp3",
        "Music/sch/SouD/Epl_Gen02.mp3",
        "Music/sch/SouD/Epl_Gen03.mp3",
        "Music/sch/SouD/Epl_Gen04.mp3",

        "Music/Explore/mx_explore_2.mp3",
        "Music/Explore/mx_explore_4.mp3",
    }

    addCopies(tracks, "Music/sch/SouD/Sil_12.mp3", 5)
    addCopies(tracks, "Music/sch/SouD/Sil_25.mp3", 5)

    return tracks
end

local function fjollvintTracks()
    local tracks = {
        "Music/sch/SouD/Epl_Gen01.mp3",
        "Music/sch/SouD/Epl_Gen02.mp3",
        "Music/sch/SouD/Epl_Gen03.mp3",
        "Music/sch/SouD/Epl_Gen04.mp3",

        "Music/sch/SouD/Epl_Odo01.mp3",
        "Music/sch/SouD/Epl_Odo02.mp3",

        "Music/Explore/mx_explore_2.mp3",
        "Music/Explore/mx_explore_6.mp3",
    }

    addCopies(tracks, "Music/sch/SouD/Sil_12.mp3", 6)
    addCopies(tracks, "Music/sch/SouD/Sil_25.mp3", 6)

    return tracks
end

local function isInDungeonCell()
    return Playback.rules.cellNameExact(DungeonCells)
end

local function isInHjelmgaard()
    return not Playback.state.isInCombat
        and not isInDungeonCell()
        and Playback.rules.cellNameMatch(HjelmgaardCells)
end

local function isInFjollvintExterior()
    return not Playback.state.isInCombat
        and not isInDungeonCell()
        and Playback.state.cellIsExterior
        and Playback.rules.region(FjollvintRegion)
end

return {
    {
        id = "Beneath the Permafrost - Dungeon Silence",
        priority = 1,
        randomize = false,
        cycleTracks = true,
        interruptMode = INTERRUPT.Me,
        fadeOut = 0,

        tracks = {
            "Music/sch/SouD/Sil_90.mp3",
        },

        isValidCallback = isInDungeonCell,
    },

    {
        id = "Beneath the Permafrost - Hjelmgaard",
        priority = 2,
        randomize = true,
        cycleTracks = true,
        interruptMode = INTERRUPT.Other,

        tracks = hjelmgaardTracks(),

        isValidCallback = isInHjelmgaard,
    },

    {
        id = "Beneath the Permafrost - Fjollvint",
        priority = 3,
        randomize = true,
        cycleTracks = true,
        interruptMode = INTERRUPT.Other,

        tracks = fjollvintTracks(),

        isValidCallback = isInFjollvintExterior,
    },
}