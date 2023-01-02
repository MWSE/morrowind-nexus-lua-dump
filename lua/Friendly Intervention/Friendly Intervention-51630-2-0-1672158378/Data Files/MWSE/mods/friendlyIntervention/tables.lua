local stuff = {}

stuff.scrollType = {
    [0] = "sc_almsiviintervention",
    [1] = "sc_divineintervention",
    [2] = "sc_leaguestep"
}

stuff.raceNames = {
    [1] = "Wood Elf",
    [2] = "Dark Elf",
    [3] = "High Elf",
    [4] = "Breton",
    [5] = "Imperial",
    [6] = "Redguard",
    [7] = "Nord",
    [8] = "Argonian",
    [9] = "Khajiit",
    [10] = "Orc"
}

stuff.noTeleportMsg = {
    [1] = "What..? I can't get it to work!",
    [2] = "...Something is wrong. Teleportation won't work.",
    [3] = "...Even my teleportation will not function here! Be wary.",
    [4] = "Odd. Some force prevents me from doing so...",
    [5] = "...It seems my teleportation won't work here.",
    [6] = "Wait. I don't think we can leave like that.",
    [7] = "...Something stifles the air. Not even the wind will reach us here.",
    [8] = "...The teleportation spells will not work. We must find another way.",
    [9] = "...Nowhere? Strange...the spells will not work!",
    [10] = "...I cannot take us anywhere. Not from here."
}


--Magicka Expanded-------------------------------------------------------------

stuff.meSpells = {
    [4] = "OJ_ME_TeleportToAldRuhn",
    [5] = "OJ_ME_TeleportToBalmora",
    [6] = "OJ_ME_TeleportToEbonheart",
    [7] = "OJ_ME_TeleportToVivec",
    [8] = "OJ_ME_TeleportToCaldera",
    [9] = "OJ_ME_TeleportToGnisis",
    [10] = "OJ_ME_TeleportToMaarGan",
    [11] = "OJ_ME_TeleportToMolagMar",
    [12] = "OJ_ME_TeleportToPelagiad",
    [13] = "OJ_ME_TeleportToSuran",
    [14] = "OJ_ME_TeleportToTelMora",
    [15] = "OJ_ME_TeleportToMournhold"
}

stuff.meText = {
    [4] = "Ald-Ruhn",
    [5] = "Balmora",
    [6] = "Ebonheart",
    [7] = "Vivec",
    [8] = "Caldera",
    [9] = "Gnisis",
    [10] = "Maar Gan",
    [11] = "Molag Mar",
    [12] = "Pelagiad",
    [13] = "Suran",
    [14] = "Tel Mora",
    [15] = "Mournhold, Plaza Brindisi Dorom"
}

stuff.mePosition = {
    [4] = { -16328, 52678, 1841 },
    [5] = { -22707, -17639, 403 },
    [6] = { 18122, -101919, 337 },
    [7] = { 29906, -76553, 790 },
    [8] = { -10373, 17241, 1284 },
    [9] = { -86430, 91415, 1035 },
    [10] = { -22118, 102242, 1979 },
    [11] = { 106763, -61839, 780 },
    [12] = { 1008, -56746, 1360 },
    [13] = { 56217, -50650, 52 },
    [14] = { 106925, 117169, 264 },
    [15] = { -4, 3170, 199 }
}

stuff.meOrientation = {
    [4] = { x = 0, y = 0, z = 92 },
    [5] = { x = 0, y = 0, z = 0 },
    [6] = { x = 0, y = 0, z = 268 },
    [7] = { x = 0, y = 0, z = 178 },
    [8] = { x = 0, y = 0, z = 4 },
    [9] = { x = 0, y = 0, z = 34 },
    [10] = { x = 0, y = 0, z = 34 },
    [11] = { x = 0, y = 0, z = 92 },
    [12] = { x = 0, y = 0, z = 86 },
    [13] = { x = 0, y = 0, z = 178 },
    [14] = { x = 0, y = 0, z = 34 },
    [15] = { x = 0, y = 0, z = 0 }
}


return stuff
