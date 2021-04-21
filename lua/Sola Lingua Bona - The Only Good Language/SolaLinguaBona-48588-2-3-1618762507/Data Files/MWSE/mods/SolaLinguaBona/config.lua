local config = {}

local settings = {
    enabled = true,
    langID = 0
}
local races = {
    {"^High Elf$", "Altmer", 1, "High Elf"},
    {"Argonian", "Argonian"},
    {"^Wood Elf$", "Bosmer", 1, "Wood Elf"},
    {"Breton", "Breton"},
    {"^Dark Elf$", "Dunmer", 1, "Dark Elf"},
    {"^Imperial$", "Cyrodiil", 1, "Imperial"},
    {"Khajiit", "Khajiit"},
    {"Nord", "Nord"},
    {"^Orc$", "Orsimer", 1, "Orc"},
    {"Redguard", "Redguard"}
}
local birthsigns = {
    {"The Warrior", "Ge'Ayem"},		-- Vivec Star
    {"The Mage", "Ge'Seht"},                                    -- Sotha Sil Star
    {"The Thief", "Ge'Vehk"},                                   -- Almalexia Star
	
    {"The Serpent", "Ge'Sharmat"},  -- Dagoth Ur Star
	
    {"The Lady", "Ge'Rilms"},		-- Rilms Star
    {"The Steed", "Ge'Felms"},		-- Felms Star
    {"The Lord", "Ge'Olms"},		-- Olms Star
	
    {"The Apprentice", "Ge'Delyn"},	-- Delyn Star
    {"The Atronach", "Ge'Seryn"},	-- Seryn Star
    {"The Ritual", "Ge'Llothis"},	-- Llothis Star
	
    {"The Lover", "Ge'Meris"},		-- Meris Star
    {"The Shadow", "Ge'Aralor"},	-- Aralor Star
    {"The Tower", "Ge'Roris"}		-- Roris Star
}
local npcRaces = {
    ["High Elf"] = 1,
    ["Argonian"] = 0,
    ["Wood Elf"] = 1,
    ["Breton"] = 2,
    ["Dark Elf"] = 1,
    ["Imperial"] = 2,
    ["Khajiit"] = 0,
    ["Nord"] = 2,
    ["Orc"] = 1,
    ["Redguard"] = 2
}
local npcFactions = {
    ["Hlaalu"] = 1,
    ["Redoran"] = 1,
    ["Telvanni"] = 1,
    
    ["Blades"] = 2,
    ["Census and Excise"] = 2,
    ["Dark Brotherhood"] = 2,
    ["East Empire Company"] = 2,
    ["Fighters Guild"] = 2,
    ["Imperial Cult"] = 2,
    ["Imperial Knights"] = 2,
    ["Imperial Legion"] = 2,
    ["Mages Guild"] = 2,
    ["Talos Cult"] = 2,
    ["Thieves Guild"] = 2,

    ["Ashlanders"] = 1,
    ["Camonna Tong"] = 1,
    ["Morag Tong"] = 1,
    ["Nerevarine Cult"] = 1,
    ["Tribunal Temple"] = 1,
    ["Twin Lamps"] = 0,

    ["Aundae Clan"] = 1,
    ["Berne Clan"] = 2,
    ["Quarra Clan"] = 2
}
local places = {                                                                    -- PREFIX   MIDFIX  PROPER      SUFFIX
    {"Ascadian Isles", "Ascadivir"},                                                -- Ascadi-                      -land
    {"Ashlands", "Kazahvir"},                                                       --                  Volcano     -land
    {"Azura's Coast", "Gah-Gnaar Azura"},                                           -- Great    Coast   Azura
    {"Bitter Coast", "Gah-Gnaar Numa"},                                             -- Great    Coast   Swamp
    {"Grazelands", "Sunna Guradan"},                                                --
    {"Valley of Fire", "Molag Amur"},                                               -- Fire             River
    {"Red Mountain", "Sei Vvardenfell"},                                            -- True             Vvardenfell
    {"Sheogorath's Torment", "Sheogorad"},                                          --                  Sheogorath
    {"West Gash", "Gah-Gnaar Gnis"},                                                -- Great    Coast   West
    
    {"Elder Home", "Ald'ruhn"},                                                     -- Old              Home
    {"Stoneforest", "Balmora"},                                                     -- Stone            Forest
    {"Mushroom Forest", "Sadrith Mora"},                                            -- Mushroom         Forest
    {"Vivec", "Vivec"},                                                             --
    {"Foreign Quarter", "Guhn Tamriel"},                                            -- District         Tamriel
    {"Hlaalu Canton", "Guhn Hlaalu"},                                               -- District         Hlaalu
    {"Redoran Canton", "Guhn Redoran"},                                             -- District         Redoran
    {"Telvanni Canton", "Guhn Telvanni"},                                           -- District         Telvanni
    {"Arena Canton", "Guhn Ald"},                                                   -- District         Old
    {"St. Olms Canton", "Guhn Ge'Olms"},                                            -- District	Saint	Olms
    {"St. Delyn Canton", "Guhn Ge'Delyn"},                                          -- District	Saint	Delyn
    {"Temple Canton", "Guhn Seliffrnsae"},                                          -- District         Council
    {"Ministry of Truth", "Baar Dau"},                                              -- Lie              Rock
    {"Palace Canton", "Guhn Alt'Seliffrnsae"},                                      -- District High    Council
    
    {"Old Velothi", "Ald Velothi"},                                                 -- Old              Velothi
    {"Caldera", "Caldera"},                                                         --
    {"Dagon Fel", "Dagon Fel"},                                                     --
    {"Port Mok", "Gnaar Mok"},                                                      -- Coast            Mok
    {"Westden", "Gnisis"},                                                          --
    {"Odai's Passing", "Hla Oad"},                                                  --
    {"Seiden", "Khuul"},                                                            --
    {"Pompe", "Maar Gan"},                                                          --
    {"Pelagiad", "Pelagiad"},                                                       --
    {"Seyda Neen", "Seyda Neen"},                                                   --
    {"Pilgrim's Respite", "Suran"},                                                 --
    {"Home Tower", "Tel Aruhn"},                                                    -- Tower            Home
    {"Southern Tower", "Tel Branora"},                                              -- Tower            Southern
    {"Fyr Tower", "Tel Fyr"},                                                       --
    {"Forest Tower", "Tel Mora"},                                                   -- Tower            Forest
    {"Arboris Umbra Tower", "Tel Vos"},                                             -- Tower
    {"Arboris Umbra", "Vos"},                                                       --

    {"Indarys Manor", "Indarys'Ruhn"},                                              --                  Indarys     'house
    {"Rethan Manor", "Rethan'Ruhn"},                                                --                  Rethan      'house
    {"Uvirith Tower", "Tel Uvirith"},                                               --
    
    {"Buckmoth Legion Fort", "Fort Buckmoth"},                                      --
    {"Ebonheart", "Ebonheart"},                                                     --
    {"Moonmoth Legion Fort", "Fort Moonmoth"},                                      --
    {"Wolverine Hall", "Hall Wolverine"},                                           --
    
    {"Ahemmusa Camp", "Val Ahemmusa"},                                              -- Camp             Ahemmusa
    {"Erabenimsun Camp", "Val Erabenimsun"},                                        -- Camp             Erabenimsun
    {"Urshilaku Camp", "Val Urshilaku"},                                            -- Camp             Urshilaku
    {"Zainab Camp", "Val Zainab"},                                                  -- Camp             Zainab
    
    {"Aharasaplit Camp", "Val Aharasaplit"},                                        -- Camp             Aharasaplit
    {"Aidanat Camp", "Val Aidanat"},                                                -- Camp             Aidanat
    {"Ashamanu Camp", "Val Ashamanu"},                                              -- Camp             Ashamanu
    {"Bensiberib Camp", "Val Bensiberib"},                                          -- Camp             Bensiberib
    {"Elanius Camp", "Val Elanius"},                                                -- Camp             Elanius
    {"Kaushtababi Camp", "Val Kaushtababi"},                                        -- Camp             Kaushtababi
    {"Mamshar[-]Disamus Camp", "Val Mamshar-Disamus", 1, "Mamshar-Disamus Camp"},   -- Camp             Mamshar-Disamus
    {"Massahanud Camp", "Val Massahanud"},                                          -- Camp             Massahanud
    {"Mila[-]Nipal", "Val Mila-Nipal", 1, "Mila-Nipal"},                            -- Camp             Mila-Nipal
    {"Salit Camp", "Val Salit"},                                                    -- Camp             Salit
    {"Shashmanu Camp", "Val Shashmanu"},                                            -- Camp             Shashmanu
    {"Shashurari Camp", "Val Shashurari"},                                          -- Camp             Shashurari
    {"Sobitbael Camp", "Val Sobitbael"},                                            -- Camp             Sobitbael
    {"Yakaridan Camp", "Val Yakaridan"},                                            -- Camp             Yakaridan

    {"Arvel Plantation", "Arvel"},                                                  --
    {"Stonerow", "Bal Isra"},                                                       -- Stone            Row
    {"Dren Plantation", "Dren"},                                                    --
    {"Fields of Kummu", "Kummu Guradan"},                                           -- Kummu            Fields
    {"Ghostgate", "Ghostgate"},                                                     --
    {"Holamayan Monastery", "Holamayan"},                                           --
    {"Khartag Point", "Khartag"},                                                   --
    {"Manor District", "Guhn Ruhn"},                                                -- District         Home
    {"Mount Assarnibibi", "Dal Assarnibibi"},                                       -- Mount            Assarnibibi
    {"Mount Kand", "Dal Kand"},                                                     -- Mount            Kand
    {"Odai Plateau", "Odai", 1, "Odai Plateau"},                                    --
    {"Sanctus Shrine", "Sanctus Shrine"},                                           --
    {"Shrine of Azura", "Azura Shrine"},                                            --
    {"Uvirith's Grave", "Uvirith's Grave"},                                         --
    {"Valley of the Wind", "Thulu Amur"},                                           -- Wind             River

    {"Fire-River Ashur-Dan", "Foyada Ashur[-]Dan", 2, "Foyada Ashur-Dan"},          -- Fire-River       Ashur-Dan
    {"Fire-River Bani-Dad", "Foyada Bani[-]Dad", 2, "Foyada Bani-Dad"},             -- Fire-River       Bani-Dad
    {"Fire-River Esannudan", "Foyada Esannudan"},                                   -- Fire-River       Esannudan
    {"Fire-River Ilibaal", "Foyada Ilibaal"},                                       -- Fire-River       Ilibaal
    {"Fire-River Mamaea", "Foyada Mamaea"},                                         -- Fire-River       Mamaea
    {"Fire-River Nadanat", "Foyada Nadanat"},                                       -- Fire-River       Nadanat
    
    {"Inner Sea", "Inner Sea"},                                                     --
    {"Lake Amaya", "Gah-Ouada Amaya"},                                               --
    {"Lake Hairan", "Gah-Ouada Hairan"},                                             --
    {"Lake Masobi", "Gah-Ouada Masobi"},                                             --
    {"Lake Nabia", "Gah-Ouada Nabia"},                                               --
    {"Nabia River", "Ouada Nabia"},                                                  -- River            Nabia
    {"^Odai$", "Ouada Odai", 1, "Odai River"},                                       -- River            Odai
    {"River Samsi", "Ouada Samsi"},                                                  -- River            Samsi
    {"Sea of Ghosts", "Sea of Ghosts"}                                              --
}
local other = {
    {"Ashlander[s]?", "Velothi", 1, "Ashlander"},

    {"a High Elf", "an @?Altmer#?", 2},
    {"a Wood Elf", "a @?Bosmer#?", 2},
    {"a Dark Elf", "a @?Dunmer#?", 2},
    {"an @?Imperial#?", "a Cyrodiil", 1},
    {"an @?Orc#?", "an Orsimer", 1},

    {"High Elf", "Altmer", 2},
    {"Wood Elf", "Bosmer", 2},
    {"Dark Elf", "Dunmer", 2},

    {"High Elves", "Altmer", 1},
    {"Wood Elves", "Bosmer", 1},
    {"Dark Elves", "Dunmer", 1},
    {"@Imperial#", "Cyrodiil", 1},
    {"@Orc#s", "Orsimer", 1},
    {"Elder Home", "Ald[-]ruhn", 1},
    {"Odai River", "Ouada Odai", 1},
    {"River Odai", "Ouada Odai", 1},
    {"Odai River", "@Odai#", 2}
}
local protected = {
    {"Palace of Vivec", "PoV"},
    {"Imperial Blades", "ImpBla"},
    {"Imperial cult", "ImpCult"},
    {"Imperial corruption", "ImpCor"},
    {"Imperial Guard", "ImpGua"},
    {"Imperial guilds", "ImpGui"},
    {"Imperial law", "ImpLaw"},
    {"Imperial Legion", "ImpLeg"},
    {"Imperial neighbors", "ImpLeg"},
    {"Imperial Office", "ImpOff"},
    {"Imperial provinces", "ImpProvs"},
    {"Imperial urban", "ImpUrb"},
    {"@Imperial# outsiders", "ImpOut"},
    {"@Imperial# Authority", "ImpAuth"},
    {"@Imperial# modernism", "ImpMod"},
    {"@Imperial# style", "ImpSty"},
    {"@Imperial# government", "ImpGov"},
    {"@Imperial# town", "ImpTown"},
    {"@Imperial# fashion", "ImpFash"},
    {"@Imperial# shrine", "ImpShr"},
    {"@Imperial# citizen", "ImpCit"},
    {"@Imperial# Intelligence", "ImpInt"},
    {"pre-Imperial", "PreImp"},
    {"@Imperial# City", "ImpCity"},
    {"@Imperial# agent", "ImpAge"},
    {"@Imperial# Province", "ImpProv"},
    {"gone @Imperial#", "GoneImp"},
    {"@Imperial# influence", "ImpInf"},
    {"@Imperial# Chapel", "ImpCha"},
    {"@Imperial# veteran", "ImpVet"},
    {"@Imperial# Dragon", "ImpDra"},
    {"@Imperial# Commission", "ImpCom"},
    {"@Imperial# @justice#", "ImpJus"},
    {"@Imperial#s have stolen", "ImpSto"},
    {"money from the @Imperial#s", "MonImp"},
    {"@Imperial# @trader#", "ImpTra"},
    {"@Imperial#s are apes", "ImpApe1"},
    {"@Imperial#s as apes", "ImpApe2"},
    {"respect @Imperial#", "ResImp"},
    {"@Imperial#s as apes", "ImpApe2"},
    {"@Imperial# cunning", "ImpCun"},
}
local translationID = {
    { label = "Default", value = 0 },
    { label = "Dunmeris", value = 1 },
    { label = "Cyrodilic", value = 2 }
}
local mods = {}
local updates = {
    {"v1", "Hello world!"},
    {"v1.1", "Bug fixes."},
    {"v1.2", "Translation changes; birthsigns, plurals, etc."},
    {"v2", "Added creature translations.\nAdd journal translations."},
    {"v2.1", "Bug fixes."},
    {"v2.2", "Bug fixes."},
    {"v2.3", "Bug fixes.\nAdded updates section to mod config (hi)."}
}

local function dictionaryLoop(kName, kList, impColumn, dunColumn)
    local impSection = impColumn:createCategory(kName)
    local dunSection = dunColumn:createCategory("")
    local impString = ""
    local dunString = ""
    local i = 1
    for _, kpv in pairs(kList) do
        local spacing = (i % 15 ~= 0 and "\n" or "\n\n")
        if (kpv[3] and kpv[4]) then
            if (kpv[3] == 1) then
                impString = impString .. spacing .. kpv[4]
                dunString = dunString .. spacing .. kpv[2]
                i = i + 1
            elseif (kpv[3] == 2) then
                impString = impString .. spacing .. kpv[1]
                dunString = dunString .. spacing .. kpv[4]
                i = i + 1
            end
        elseif (kpv[3] == nil) then
            impString = impString .. spacing .. kpv[1]
            dunString = dunString .. spacing .. kpv[2]
            i = i + 1
        end
    end
    impSection:createInfo{text = impString:gsub("^\n", "")}
    dunSection:createInfo{text = dunString:gsub("^\n", "")}
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Sola Lingua Bona")
    local settingsPage = template:createPage{label = "Config", noScroll = true}
    local enableSub = settingsPage:createSideBySideBlock()
    enableSub:createInfo{text = "I want people to speak in their native language..."}
    enableSub:createYesNoButton{
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = settings
        }
    }
    local configSub = settingsPage:createSideBySideBlock()
    configSub:createInfo{text = "The language I speak is..."}
    configSub:createDropdown{
        options = translationID,
        variable = mwse.mcm.createTableVariable{
            id = "langID",
            table = settings
        }
    }
    if (table.getn(mods) > 0) then
        local modListSub = settingsPage:createSideBySideBlock()
        local modNameColumn = modListSub:createCategory("Active Mods")
        local modTranslationColumn = modListSub:createCategory("")

        for _, mod in pairs(mods) do
            modNameColumn:createInfo{text = mod.name}
            local count = 0
            for _, k in ipairs(mod.config["dictKeys"]) do
                if (k ~= "protected" and k ~= "npcRaces" and k ~= "npcFactions") then
                    count = count + table.getn(mod.config[k])
                end
            end
            modTranslationColumn:createInfo{text = "(" .. tostring(count) .. " translations)"}
        end
    end
    local updatesTitle = settingsPage:createCategory("Updates")
    for _, update in pairs(updates) do
        local updateTitle = updatesTitle:createCategory(update[1])
        updateTitle:createInfo{text = update[2]}
    end

    local dictionaryPage = template:createPage("Translation")
    local columnsSub = dictionaryPage:createSideBySideBlock()
    local impColumn = columnsSub:createCategory("Cyrodilic")
    local dunColumn = columnsSub:createCategory("Dunmeris")
    dictionaryLoop("Races", races, impColumn, dunColumn)
    dictionaryLoop("Birthsigns", birthsigns, impColumn, dunColumn)
    dictionaryLoop("Places", places, impColumn, dunColumn)
    dictionaryLoop("Other", other, impColumn, dunColumn)
    if (table.getn(mods) > 0) then
        for _, mod in pairs(mods) do
            local modColumnsSub = dictionaryPage:createSideBySideBlock()
            impColumn = modColumnsSub:createCategory("Mod: " .. mod.name)
            dunColumn = modColumnsSub:createCategory("")
            for _, k in ipairs(mod.config["dictKeys"]) do
                if (k ~= "protected" and k ~= "npcRaces" and k ~= "npcFactions") then
                    dictionaryLoop(k, mod.config[k], impColumn, dunColumn)
                end
            end
        end
    end

    template:saveOnClose("SolaLinguaBona", settings)
    mwse.mcm.register(template)
end

--------------------------------------------------

function config.init()
    local tryLoadConfig = mwse.loadConfig("SolaLinguaBona")
    if (tryLoadConfig) then
        config.setSettings(tryLoadConfig)
    else
        mwse.saveConfig("SolaLinguaBona", config.getSettings())
    end
    event.register("modConfigReady", registerModConfig)
end

function config.getSettings()
    return settings
end

function config.setSettings(s)
    settings = s
end

function config.getRaces()
    return races
end

function config.getBirthsigns()
    return birthsigns
end

function config.getNpcRaces(s)
    if (s) then
        return npcRaces[s]
    else
        return npcRaces
    end
end

function config.getNpcFactions(s)
    if (s) then
        return npcFactions[s]
    else
        return npcFactions
    end
end

function config.getPlaces()
    return places
end

function config.getOther()
    return other
end

function config.getProtected()
    return protected
end

function config.getMods(n)
    if (n) then
        return mods[n]
    else
        return mods
    end
end

function config.addModTranslation(name, translation)
    table.insert(mods, {name = name, config = translation})
end

return config