local prefixCities = {
"Ald’Ruhn",
'Balmora',
'Caldera',
'Ebonheart',
'Ghostgate',
'Gnisis',
'Maar Gan',
'Molag Mar',
'Pelagiad',
'Suran',
'Vivec',
-- 'Sadrith Mora',
-- 'Wolverine Hall',


--Tamriel Rebuilt.
-- 'Akamora',
-- --'Almas Thirr',
-- 'Bal Foyen',
-- 'Firewatch',
-- 'Hlan Oek',
-- 'Hlerynhul',
-- 'Narsis',
-- --'Necrom',
-- 'Old Ebonheart',
-- 'Ebon Tower',

}

local prefixTelvanni = {
'Tel Vos',
'Tel Mora',
'Tel Auhn',
'Tel Uvirith',
'Tel Fir',
'Tel Branora',
'The Telvanni Canton (Vivec)',
'Sadrith Mora',

--Tamriel Rebuilt.
'Port Telvannis',
'Alt Bosara',
'Gah Sadrith',
'Llothanis',
'Marog',
'Sadas Plantation',
'Tel Aranyon',
'Tel Mothrivra',
'Tel Muthada',
'Tel Gilan',
'Tel Ouada',
'Tel Drevis',
'Tel Oren',
'Telvanni Waystation',
'Veralan Farm',
'Verulas Pass',

}


local prefixMages = {
'Ald’Ruhn, Mages Guild',
'Balmora, Mages Guild',
'Caldera, Mages Guild',
'Vivec, Mages Guild',
'Wolverine Hall, Mages Guild',
'Sadrith Mora, Wolverine Hall',

--Tamriel Rebuilt.
'Akamora, Guild of Mages',
'Almas Thirr, Guild of Mages',
'Bal Foyen, Guild of Mages',
'Firewatch, Guild of Mages',
'Narsis, Guild of Mages',
'Old Ebonheart, Guild of Mages',

}

local idMages = {
    ["ald-ruhn, guild of mages"] = true,
    ["balmora, guild of mages"] = true,
    ["caldera, guild of mages"] = true,
    ["vivec, guild of mages"] = true,
    ["sadrith mora, wolverine hall"] = true,
    ["#15 1"] = true, -- Tel Fyr
    ["tower of tel fyr, hall of fyr"] = true, -- Tel Fyr
    ["tower of tel fyr, onyx hall"] = true, -- Tel Fyr
    ["gnisis, arvs-drelen"] = true,


    ["firewatch, guild of mages"] = true,
    ["akamora, guild of mages"] = true,
    ["bal foyen, guild of mages"] = true,
    ["helnim, guild of mages"] = true,
    ["old ebonheart, guild of mages"] = true,
    ["almas thirr, guild of mages"] = true,
    ["narsis, guild of mages"] = true,
    ["othmura, guild of mages"] = true,
    ["nivalis, icebreaker keep: mages guild outpost"] = true,
}


local prefixTemples = {
'Molag Mar, Temple',
'Suran, Suran Temple',
'Gnisis, Temple',
'Ghostgate, Temple',
'Mournhold Temple',
'Ald-ruhn, Temple',
'Balmora, Temple',
'Vivec, Hlaalu Temple',
'Vivec, St. Olms Temple',

--Tamriel Rebuilt.
'Akamora, Temple',
'Bal Foyen, Temple',
'Bosmora, Temple',
'Hlan Oek, Temple',
'Hlersis, Temple',
'Hlerynhul, Temple',
'Mournhold Temple',
'Narsis, Eight-Bones Temple',
'Othmura, Temple',
'Ranyon-ruhn, Temple',
'Sailen, Temple',
'Vhul, Temple',

-- as temple
'Necrom', 
'Almas Thirr', 
'Number Rooms Temple'
}

local idTemples = {
    ["#3 -13"] = true, -- Vivec Temple
    ["#3 -14"] = true, -- Vivec Temple
    ["#4 -13"] = true, -- Vivec Temple
    ["#4 -14"] = true, -- Vivec Temple
    ["ald-ruhn, temple"] = true,
    ["balmora, temple"] = true,
    ["ghostgate, temple"] = true,
    ["gnisis, temple"] = true,
    ["molag mar, temple"] = true,
    ["suran, suran temple"] = true,
    ["vivec, hlaalu temple"] = true,
    ["vivec, st. olms temple"] = true,
    ["vivec, telvanni temple"] = true,
}
local function startsWith(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
end

local function startsWithArray(str, array)
    for _, prefix in ipairs(array) do
        if string.sub(str, 1, #prefix) == prefix then return true end
    end
    return false
end


local telvanniCells = {
    ["#36 -4"] = true,
    ["#36 -5"] = true, 
    ["#37 -4"] = true,
    ["#37 -5"] = true,
    ["#32 10"] = true,
    ["#33 10"] = true,
    ["#23 -2"] = true,
    ["#28 12"] = true,
    ["#33 2"] = true,
    ["#33 3"] = true,
    ["#27 -5"] = true,
    ["#26 1"] = true,
    ["#24 18"] = true,
    ["#25 18"] = true,
    ["#28 4"] = true,
    ["#21 11"] = true,
    ["Telvanni Waystation"] = true,
    ["#25 3"] = true,
    ["#35 6"] = true,
}
local telvanniEceptionCells = {
    ["#5 -11"] = true
}






local summonPrefix = {
"Sadrith Mora",
"Tel Mora",
"Tel Vos",
"Tel Aruhn",
"Tel Uvirith",
"Tel Branora",
"Vivec, Telvanni",
"Tel Naga",

--Tamriel Rebuilt.
"Necrom",
"Ranyon-ruhn",
"Almas Thirr",
"Bal Foyen",
"Hlan Oek",
"Firewatch",
"Akamora",
"Bal Foyen",
"Helnim",
"Old Ebonheart",
"Almas Thirr",
"Narsis",
"Othmura",
"Nivalis",
"Port Telvannis",
"Alt Bosara",
"Gah Sadrith",
"Llothanis",
"Marog",
"Sadas Plantation",
"Tel Aranyon",
"Tel Mothrivra",
"Tel Muthada",
"Tel Gilan",
"Tel Ouada",
"Tel Drevis",
"Tel Oren",
"Telvanni Waystation",
"Veralan Farm",
"Verulas Pass",
}

local function isTelvanni(data)
    local isTelvanni = startsWithArray(data.cellName, prefixTelvanni ) 
    if data.cellRegion == "Telvanni Isles Region" then isTelvanni = true end

    if isTelvanni and not telvanniEceptionCells[data.cellId] then 
        return true 
    else
        return false
    end
end

local function isTelvanniSadrithMora(data)
    return startsWithArray(data.cellName, "Sadrith Mora")
end
local function isTelvanniTelNaga(data)
    return startsWithArray(data.cellName, "Sadrith Mora, Tel Naga")
end
local function isTemple(data)
    return idTemples[data.cellId] or startsWithArray(data.cellName, prefixTemples ) 
end

local function isMage(data)
    return idMages[data.cellId] or startsWithArray(data.cellName, prefixMages )
end

local function isCities(data)
    return startsWithArray(data.cellName, prefixCities )
end

local function isVivec(data)
    return startsWith(data.cellName, "Vivec, Puzzle Canal, Level") 
end

local suspiciousActivitiesCells = {
    ["#-2 6"] = true,
    ["#-2 7"] = true,
    ["#-3 6"] = true,
    ["#-2 -2"] = true,
    ["#-3 -2"] = true,
    ["#-3 -3"] = true,
    ["#-4 -2"] = true,
    ["#-2 2"] = true,
    ["#1 -13"] = true,
    ["#2 -13"] = true,
    ["#2 4"] = true,
    ["#-10 11"] = true,
    ["#-11 10"] = true,
    ["#-11 11"] = true,
    ["#-3 12"] = true,
    ["#12 -8"] = true,
    ["#13 -8"] = true,
    ["#0 -7"] = true,
    ["#0 -8"] = true,
    ["#6 -6"] = true,
    ["#6 -7"] = true,
    ["#2 10"] = true,
    ["#3 9"] = true,
    ["#5 10"] = true
}

local function issuspiciousActivities(data)
    return (suspiciousActivitiesCells[data.cellId] or isCities(data) or isTelvanni(data)) and not isMage(data) and not isVivec(data) 
end

return {
    isTemple = isTemple,
    isTelvanni = isTelvanni,
    isMage = isMage,
    isCities = isCities,
    isVivec = isVivec,
    issuspiciousActivities  = issuspiciousActivities,

    telvanniAllowedEffects = {
        ["restorestrength"] = true,
        ["restoreagility"] = true,
        ["restoreintelligence"] = true,
        ["restorewillpower"] = true,
        ["restoreendurance"] = true,
        ["restorespeed"] = true,
        ["restorepersonality"] = true,
        ["restoreluck"] = true,
        ["restorehealth"] = true,
        ["restorefatigue"] = true,
        ["restoremagicka"] = true,
        ["curepoison"] = true,
        ["cureparalyzation"] = true,
        ["curecommondisease"] = true,
        ["cureblightdisease"] = true,
        ["feather"] = true,
        ["light"] = true,
        ["waterwalking"] = true,
    },
    
    telvanniAllowedEffectsTelNaga = {
        ["levitate"] = true,
        ["jump"] = true,
    }  
}

