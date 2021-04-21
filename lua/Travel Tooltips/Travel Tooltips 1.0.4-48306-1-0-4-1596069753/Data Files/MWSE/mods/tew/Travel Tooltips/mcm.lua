local config = require("tew\\Travel Tooltips\\config")
local version="1.0.4"

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Travel Tooltips",
    headerImagePath="\\Textures\\tew\\Travel Tooltips\\logo_tt.dds"}

    local page = template:createPage{label="Travel Tooltips Settings"}

    page:createCategory{
        label = "Travel Tooltips version "..version.." by tewlwolow.\nHovering over a destination in the 'Travel' tab (and, optionally, on 'Travel' button itself) will now display an appropriate map and a short description. Illustrations are courtesy of Stuporstar; slightly edited by me.\n\nSettings:",
    }

    page:createYesNoButton{
        label = "Show travel tooltips for Vivec gondoliers?\nDefault: Yes.",
        variable = registerVariable("showGondola")}

    page:createYesNoButton{
        label = "Show Vvardenfell map when hovering over 'Travel' in dialogue menu?\nDefault: Yes.",
        variable = registerVariable("showMainMap")}

    page:createDropdown{
        label = "Choose map for the above setting. Does nothing when set to 'No'.",
        options = {
            {label = "Vvardenfell Travel Routes Map (Default)", value = "\\Textures\\tew\\Travel Tooltips\\MW_travelroutes.tga"},
            {label = "Generic Vvardenfell Map", value = "\\Textures\\tew\\Travel Tooltips\\vvardenfellcitymap.tga"}
            },
            variable=registerVariable("mainMap")}

    page:createDropdown{
        label = "Choose tooltip type:",
        options = {
            {label = "Wide (Default)", value = "Wide"},
            {label = "Slim", value = "Slim"}
            },
            variable=registerVariable("size")}

    page:createDropdown{
        label = "Choose colour scheme for tooltip images:",
        options = {
            {label = "Indoril Ivory (Default)", value = "Indoril"},
            {label = "Velothi Vanilla", value = "Velothi"},
            {label = "Redoran Red", value = "Redoran"},
            {label = "Telvanni Turquoise", value = "Telvanni"},
            {label = "Dres Deluge", value = "Dres"},
            {label = "Hlaalu Hazel", value = "Hlaalu"},
            {label = "Argonian Axolotl", value ="Argonian"},
            {label= "Cyrodiil Cardinal", value = "Cyrodiil"},
            {label = "Khajiit Karry", value = "Khajiit"},
            {label = "Ayleid Aquamarine", value = "Ayleid"},
            {label = "Reman Rose", value = "Reman"}
            },
            variable=registerVariable("mapColour")}

    page:createDropdown{
        label = "Choose font for tooltip destination names:",
        options = {
            {label = "Vanilla (Magic Cards)", value = 0},
            {label = "Daedric (Default)", value = 2},
            {label = "Weird and awkward", value = 1}
            },
            variable=registerVariable("fontLabel")}

    page:createDropdown{
        label = "Choose font for tooltip description:",
        options = {
            {label = "Vanilla (Magic Cards) (Default)", value = 0},
            {label = "Daedric", value = 2},
            {label = "Weird and awkward", value = 1}
            },
            variable=registerVariable("fontText")}

    page:createSlider{
        label = "Changes UI scaling. Default = 100.\nNumbers smaller than 100 make elements smaller, numbers bigger than 100 make them bigger.\nUI Scale",
        min = 1,
        max = 200,
        step = 1,
        jump = 5,
        variable=registerVariable("scale")
}

template:saveOnClose("Travel Tooltips", config)

mwse.mcm.register(template)