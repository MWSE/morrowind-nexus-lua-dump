
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

local prefixTelvanniMage = {
    'Sadrith Mora, Wolverine Hall', 
    'Wolverine Hall' ,

--Tamriel Rebuilt.
    'Akamora, Guild of Mages',
    'Almas Thirr, Guild of Mages',
    'Bal Foyen, Guild of Mages',
    'Firewatch, Guild of Mages',
    'Narsis, Guild of Mages',
    'Old Ebonheart, Guild of Mages',    
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


local SadrithMoraNotAllow = {
    ["Esm3ExteriorCell:18:4"] = true, 
    ["Esm3ExteriorCell:17:5"] = true,
    ["sadrith mora, fara's hole in the wall"] = true,
    ["sadrith mora, nirasa aren's house"] = true,
    ["sadrith mora, madran ulvel's house"] = true,
    ["sadrith mora, thervul serethi: healer"] = true,
    ["sadrith mora, urtiso faryon: sorcerer"] = true,
    ["sadrith mora, hleras gidren's house"] = true,
    ["sadrith mora, volmyni dral's house"] = true,
    ["sadrith mora, pierlette rostorard: apothecary"] = true,
    ["sadrith mora, trendrus dral's house"] = true,
    ["sadrith mora, llaalam madalas: mage"] = true
}


local function isInn(data)
    return startsWith(data.cellId, "sadrith mora, gateway inn")
end

local function isMage(data)
    return startsWithArray(data.cellName, prefixTelvanniMage )
end

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
    return startsWith(data.cellName, "Sadrith Mora")
end

local function isTelvanniSadrithMoraNotAllow(data)
    return (SadrithMoraNotAllow[data.cellId] or isTelvanniSadrithMora(data)) and not (data.cellId == "Esm3ExteriorCell:17:4") and not isInn(data) and not isMage(data)
end

local function isTelvanniTelNaga(data)
    return startsWith(data.cellName, "Sadrith Mora, Tel Naga")
end




return {
    isTelvanni = isTelvanni,
    isTelvanniSadrithMora = isTelvanniSadrithMora,
    isTelvanniSadrithMoraNotAllow = isTelvanniSadrithMoraNotAllow,
    isTelvanniTelNaga = isTelvanniTelNaga,
    isMage = isMage,
    isInn = isInn,
    
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
        ["slowfall"] = true,
    }, 

    telvanniNotAllowedEffects = {
        ["feather"] = true,
        ["firesheild"] = true,
        ["frostshield"] = true,
        ["jump"] = true,
        ["levitate"] = true,
        ["lightningshield"] = true,
        ["lock"] = true,
        ["open"] = true,
        ["shield"] = true,
        ["slowfall"] = true,
        ["swiftswim"] = true,
        ["waterbreathing"] = true,
        ["boundbattleaxe"] = true,
        ["boundboots"] = true,
        ["boundcuirass"] = true,
        ["bounddagger"] = true,
        ["boundgauntlets"] = true,
        ["boundhelm"] = true,
        ["boundlongbow"] = true,
        ["boundlongsword"] = true,
        ["boundmace"] = true,
        ["boundshield"] = true,
        ["boundspear"] = true,
        ["summonclannfear"] = true,
        ["summondaedroth"] = true,
        ["summonancestralghost"] = true,
        ["summonbonelord"] = true,
        ["summonbonewalker"] = true,
        ["summoncenturion"] = true,
        ["summonsphere"] = true,
        ["summondremora"] = true,
        ["summonflameatronach"] = true,
        ["summonfrostatronach"] = true,
        ["summongoldensaint"] = true,
        ["summonleastbonewalker"] = true,
        ["summongreaterbonewalker"] = true,
        ["summonhunger"] = true,
        ["summonscamp"] = true,
        ["summonskeletalminion"] = true,
        ["summonstormatronach"] = true,
        ["summonwingedtwilight"] = true,
        ["chameleon"] = true,
        ["nighteye"] = true,
        ["sanctuary"] = true,
        ["detectanimal"] = true,
        ["detectenchantment"] = true,
        ["detectkey"] = true,
        ["spellabsorption"] = true,
        ["reflect"] = true,
        ["telekinesis"] = true,
        ["fortifyfatigue"] = true,
        ["fortifyhealth"] = true,
        ["fortifymagicka"] = true,
        ["fortifystrength"] = true,
        ["fortifyagility"] = true,
        ["fortifyendurance"] = true,
        ["fortifyspeed"] = true,
        ["fortifywillpower"] = true,
        ["fortifyintelligence"] = true,
        ["fortifyluck"] = true,
        ["fortifypersonality"] = true,
        ["resistblightdisease"] = true,
        ["resistcommondisease"] = true,
        ["resistcorprusdisease"] = true,
        ["resistfire"] = true,
        ["resistfrost"] = true,
        ["resistmagicka"] = true,
        ["resistparalysis"] = true,
        ["resistpoison"] = true,
        ["resistshock"] = true
    },

    telvanniNotAllowedCast = {
        --["destructionschool"] = true,
        ["almsiviintervention"] = true,
        ["divineintervention"] = true,
        ["mark"] = true,
        ["recall"] = true,
        ["dispel"] = true,
        ["silence"] = true,
        ["sound"] = true,
        ["burden"] = true,
        ["paralyze"] = true,
        ["soultrap"] = true,
        ["frenzycreature"] = true,
        ["frenzyhumanoid"] = true,
        ["calmcreature"] = true,
        ["calmhumanoid"] = true,
        ["charm"] = true,
        ["commandcreature"] = true,
        ["commandhumanoid"] = true,
        ["rallycreature"] = true,
        ["rallyhumanoid"] = true,
        ["demoralizehumanoid"] = true,
        ["turnundead"] = true,
        ["absorbhealth"] = true,
        ["absorbfatigue"] = true,
        ["absorbstrength"] = true,
        ["absorbagility"] = true,
        ["absorbendurance"] = true,
        ["absorbspeed"] = true,
        ["absorbpersonality"] = true,
        ["absorbluck"] = true,
        ["absorbintelligence"] = true,
        ["absorbwillpower"] = true
    }

}

