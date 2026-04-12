HeartQuest = {
    id = "c3_destroydagoth",
    stage = 20,
}

RedMountainRegion = "red mountain region"

CellTypes = {
    exterior = "exterior",
    genericInterior = "generic interior",
    dagothUr = "dagoth ur",
    facilityCavern = "dagoth ur, facility cavern",
    akulakhansChamber = "akulakhan's chamber",
}

InteriorBlacklist = {
    -- you can easily check your current cell id by:
    -- 1. Opening the console
    -- 2. Enabling lua mode with "luap" command
    -- 3. Executing "self.cell.id" command

    -- ["cell id"] = true,
}

InteriorWhitelist = {
    -- ["cell id 2"] = true,
}

SoundsFolder = "Sound/ItBeats/"
local hol = "Heartthrum - HeartOfLorkhan.wav"
local holVanilla = "Heartthrum - HeartOfLorkhan (vanilla version).wav"
Files = {
    ["It Beats"] = {
        [CellTypes.exterior]          = SoundsFolder .. "1. Mountain.wav",
        [CellTypes.genericInterior]   = SoundsFolder .. "2. Interiors.wav",
        [CellTypes.dagothUr]          = SoundsFolder .. "3. Dagoth Ur.wav",
        [CellTypes.facilityCavern]    = SoundsFolder .. "4. Facility Cavern.wav",
        [CellTypes.akulakhansChamber] = SoundsFolder .. "5. Akulakhans Chamber.wav",
    },
    ["Heartthrum HoL"] = {
        [CellTypes.exterior]          = SoundsFolder .. hol,
        [CellTypes.genericInterior]   = SoundsFolder .. hol,
        [CellTypes.dagothUr]          = SoundsFolder .. hol,
        [CellTypes.facilityCavern]    = SoundsFolder .. hol,
        [CellTypes.akulakhansChamber] = SoundsFolder .. hol,
    },
    ["Heartthrum HoL Vanilla"] = {
        [CellTypes.exterior]          = SoundsFolder .. holVanilla,
        [CellTypes.genericInterior]   = SoundsFolder .. holVanilla,
        [CellTypes.dagothUr]          = SoundsFolder .. holVanilla,
        [CellTypes.facilityCavern]    = SoundsFolder .. holVanilla,
        [CellTypes.akulakhansChamber] = SoundsFolder .. holVanilla,
    },
}
