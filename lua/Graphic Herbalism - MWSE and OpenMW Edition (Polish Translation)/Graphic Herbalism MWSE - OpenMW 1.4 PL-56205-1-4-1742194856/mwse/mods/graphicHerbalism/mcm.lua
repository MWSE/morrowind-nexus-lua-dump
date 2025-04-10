local EasyMCM = include("easyMCM.EasyMCM")

-- Create a placeholder page if EasyMCM is not installed.
if (EasyMCM == nil) or (EasyMCM.version < 1.4) then
    local function placeholderMCM(element)
        element:createLabel{text="To menu konfiguracyjne wymaga EasyMCM v1.4 lub nowszego."}
        local link = element:createTextSelect{text="Przejdџ na stronк Nexus EasyMCM"}
        link.color = tes3ui.getPalette("link_color")
        link.widget.idle = tes3ui.getPalette("link_color")
        link.widget.over = tes3ui.getPalette("link_over_color")
        link.widget.pressed = tes3ui.getPalette("link_pressed_color")
        link:register("mouseClick", function()
            os.execute("start https://www.nexusmods.com/morrowind/mods/46427?tab=files")
        end)
    end
    mwse.registerModConfig("Graphic Herbalism", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("graphicHerbalism.config")

local function getHerbalismObjects()
    local list = {}
    for obj in tes3.iterateObjects(tes3.objectType.container) do
        if obj.organic then
            list[#list+1] = (obj.baseObject or obj).id:lower()
        end
    end
    table.sort(list)
    return list
end

local function getVolumeAsInteger(self)
    return math.round(config.volume * 100)
end

local function setVolumeAsDecimal(self, value)
    config.volume = math.round(value / 100, 2)
end


----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Graphic Herbalism"}
template:saveOnClose("graphicHerbalism", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Preferencje"}
preferences.sidebar:createInfo{text="MWSE Graphic Herbalism - wersja 1.04 PL"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Twуrcy:"}
credits:createHyperlink{
    text = "Greatness7 - Skrypty",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Merlord - Wsparcie MCM",
    exec = "start https://www.nexusmods.com/morrowind/users/3040468?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade - Wsparcie MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Petethegoat - Pomoc przy skryptowaniu i opinie",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files",
}
credits:createHyperlink{
    text = "Remiros - Modele MOP",
    exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
}
credits:createHyperlink{
    text = "Stuporstar - Konwersja modeli i ich wygіadzanie",
    exec = "start http://stuporstar.sarahdimento.com/",
}
credits:createHyperlink{
    text = "Sveng - Opinie i testowanie",
    exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
}
credits:createHyperlink{
    text = "Gruntella - Tekstury Graphic Herbalism Universal",
    exec = "start https://www.nexusmods.com/morrowind/users/2356095?tab=user+files",
}
credits:createHyperlink{
    text = "Skrawafunda and Manauser - Oryginalne tekstury Graphic Herbalism",
    exec = "start https://www.nexusmods.com/morrowind/users/13100210?tab=user+files",
}
credits:createHyperlink{
    text = "Moranar - Poprawione modele",
    exec = "start https://www.nexusmods.com/morrowind/users/6676263?tab=user+files",
}
credits:createHyperlink{
    text = "Tyddy - Poprawione modele",
    exec = "start https://www.nexusmods.com/morrowind/users/3281858?tab=user+files",
}
credits:createHyperlink{
    text = "Articus - Pomoc przy modelach i opinie",
    exec = "start https://www.nexusmods.com/morrowind/users/51799631?tab=user+files",
}
credits:createHyperlink{
    text = "DassiD - Skalowanie tekstur",
    exec = "start https://www.nexusmods.com/morrowind/users/6344059?tab=user+files",
}
credits:createHyperlink{
    text = "Nich and CJW-Craigor - Diverse Correct UV Ore",
    exec = "start http://mw.modhistory.com/download-1-13484",
}
--Translation
local credits = preferences.sidebar:createCategory{label="Tіumaczenie:"}
credits:createHyperlink{
    text = "EriEl - Tіumaczenie na jкzyk polski",
    exec = "start https://next.nexusmods.com/profile/3ri3l?gameId=100",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Opcje"}
toggles:createOnOffButton{
    label = "Opisy skіadnikуw",
    description = "Pokaї opisy skіadnikуw:\n\nTa opcja decyduje o wyњwietlaniu opisu podczas celowania na skіadnik.\n\nDomyњlnie: Wі\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showTooltips",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Informacja o zebraniu skіadnika",
    description = "Pokaї informacje o zebraniu skіadnika:\n\nTa opcja decyduje o pomyњlnym lub nieudanym zebraniu skіadnika.\n\nDomyњlnie: Wі\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showPickedMessage",
        table = config,
    },
}

-- Feature Controls
local controls = preferences:createCategory{label="Funkcje"}
controls:createSlider{
    label = "Gіoњnoњж: %s%%",
    description = "Ustaw poziom gіoњnoњci dџwiкku zbierania skіadnikуw.",
    variable = EasyMCM:createVariable{
        get = getVolumeAsInteger,
        set = setVolumeAsDecimal,
    },
}

-- Blacklist Page
template:createExclusionsPage{
    label = "Czarna Lista",
    description = "Wszystkie organiczne pojemniki s№ traktowane jak flora. Pojemniki gildii oraz niektуre z Tamriel Rebuilt s№ domyњlnie na Czarnej Liњcie. Moїna to zmieniж w tym menu.",
    leftListLabel = "Czarna Lista",
    rightListLabel = "Obiekty",
    variable = EasyMCM:createTableVariable{
        id = "blacklist",
        table = config,
    },
    filters = {
        {callback = getHerbalismObjects},
    },
}

-- Whitelist Page
template:createExclusionsPage{
    label = "Biaіa Lista",
    description = "Oskryptowane pojemniki s№ automatycznie pomijane, ale moїna je dodaж do listy w tym menu. Pojemniki zmienione przez Piratelord's Expanded Sounds domyњlnie s№ na Biaіej Liњcie. B№dџ ostroїny przy dodawaniu plikуw OnActivate na Biaі№ Listк, moїe to zepsuж ich dziaіanie.",
    leftListLabel = "Biaіa Lista",
    rightListLabel = "Obiekty",
    variable = EasyMCM:createTableVariable{
        id = "whitelist",
        table = config,
    },
    filters = {
        {callback = getHerbalismObjects},
    },
}
