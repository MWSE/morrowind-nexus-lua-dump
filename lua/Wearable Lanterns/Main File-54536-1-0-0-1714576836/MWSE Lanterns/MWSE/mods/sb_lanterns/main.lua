local onion = require("sb_onion.interop")

local wearableID = {
    "LanternDwem",
    "LanternPaper14",
    "LanternPaper11",
    "LanternPaper10",
    "LanternPaper7",
    "LanternPaper5",
    "LanternPaper1",
    "GlassLantern2",
    "GlassLantern6",
    "TravelLantern1",
    "TravelLantern2",
    "IndorilGreen1",
    "IndorilGreen2",
    "IndorilGreen3",
    "Indoril1",
    "Indoril2",
    "Indoril3",
    "IndorilPur1",
    "IndorilPur2",
    "IndorilPur3",
    "GlassLanternyel",
    "GlassLanternred",
    "GlassLanterngrn",
    "LanternPapery1",
    "LanternPapery4",
    "LanternPaperprp4",
    "colovianlant2",
    "colovianlant3",
    "colovianlant4",
    "colovianlant5",
    "cavernlant",
    "woodlantern",
    "orclantern1",
    "orclantern2",
    "LanternPapergrn4",
    "LanternPapergrn1",
    "LanternPaperprp1",
    "LanternPaperblue1",
    "LanternPaperblue4",
    "ashl1",
    "ashl2",
    "ashl3",
    "ashl4",
    "ashl5",
    "ashl6",
    "ashl7",
}

local wearableSlot = {
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
    onion.slots.buttocks,
}

local wearableOffset = {
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
    { [""] = { -18, 0, 14 } },
}

local wearableRotation = {
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
    { 
        [""] = { 0, 20, 90 } 
    },
}

local wearableScale = {
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
    { 
        [""] = 0.5 
    },
}

local function initializedCallback(e)
    for i = 1, table.getn(wearableID), 1 do
        onion.register {
            id      = wearableID[i],
            slot    = wearableSlot[i],
            racePos = wearableOffset[i],
            raceRot = wearableRotation[i],
            raceScale = wearableScale[i]
        }-- , onion.types.eyewear, wearableSubstituteID[i] or {}, wearableOffset[i] or {}, wearableScale[i] or {})
    end
end
event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })