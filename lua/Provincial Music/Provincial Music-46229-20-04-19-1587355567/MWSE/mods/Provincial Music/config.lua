---------------------------
-- Provincial Music by Texafornian
-- 
-- Configuration File

local this = {}

--[[
Outputs Provincial Music debug information to mwse.log file.
0 - All Info, 1 - Only Errors
]]
this.debugLevel = 0

--[[
Table that contains all Vanilla, PT, and TR folder paths.
Don't edit this unless you know what you're doing.
Don't forget the use of commas on all but the last line of the table!
Format:
    ["music type"] = {
        ["Province name"] = "Music folder's path within Morrowind/Data Files"
    }
]]
this.paths = {
    ["battle"] = {
        ["Cyrodiil"] = "cyrodiil/battle/",
        ["Morrowind"] = "morrowind/battle/",
        ["Skyrim"] = "skyrim/battle/",
        ["Solstheim"] = "solstheim/battle/",
        ["Vanilla"] = "battle/"
    },
    ["explore"] = {
        ["Cyrodiil"] = "cyrodiil/explore/",
        ["Morrowind"] = "morrowind/explore/",
        ["Skyrim"] = "skyrim/explore/",
        ["Solstheim"] = "solstheim/explore/",
        ["Vanilla"] = "explore/"
    }
}

--[[
Table that contains all Vanilla, PT, and TR regions and their associated provinces.
Don't forget the use of commas on all but the last line of the table!
Format: ["Region ID"] = "Province Name"
]]
this.regions = {
    ["Aanthirin Region"] = "Morrowind",
    ["Abecean Sea Region"] = "Cyrodiil",
    ["Alt Orethan Region"] = "Morrowind",
    ["Aranyon Pass Region"] = "Morrowind",
    ["Armun Ashlands Region"] = "Morrowind",
    ["Arnesian Jungle Region"] = "Morrowind",
    ["Ascadian Bluffs Region"] = "Morrowind",
    ["Ascadian Isles Region"] = "Vanilla",
    ["Ashlands Region"] = "Vanilla",
    ["Azura's Coast Region"] = "Vanilla",
    ["Bitter Coast Region"] = "Vanilla",
    ["Boethiah's Spine Region"] = "Morrowind",
    ["Clambering Moor Region"] = "Morrowind",
    ["Colovian Barrowlands Region"] = "Cyrodiil",
    ["Colovian Highlands Region"] = "Cyrodiil",
    ["Deshaan Plains Region"] = "Morrowind",
    ["Druadach Highlands Region"] = "Skyrim",
    ["Falkheim Region"] = "Skyrim",
    ["Gilded Hills Region"] = "Cyrodiil",
    ["Gold Coast Region"] = "Cyrodiil",
    ["Grazelands Region"] = "Vanilla",
    ["Grey Meadows Region"] = "Morrowind",
    ["Helnim Fields Region"] = "Morrowind",
    ["Julan-Shar Region"] = "Morrowind",
    ["Kilkreath Mountains Region"] = "Skyrim",
    ["Lan Orethan Region"] = "Morrowind",
    ["Lorchwuir Heath Region"] = "Skyrim",
    ["Mephalan Vales Region"] = "Morrowind",
    ["Midkarth Region"] = "Skyrim",
    ["Molag Mar Region"] = "Vanilla",
    ["Molagreahd Region"] = "Morrowind",
    ["Mournhold Region"] = "Morrowind",
    ["Mudflats Region"] = "Morrowind",
    ["Nedothril Region"] = "Morrowind",
    ["Old Ebonheart Region"] = "Morrowind",
    ["Othreleth Woods Region"] = "Morrowind",
    ["Padomaic Ocean Region"] = "Morrowind",
    ["Red Mountain Region"] = "Vanilla",
    ["Ridgelands Region"] = "Skyrim",
    ["Roth Roryn Region"] = "Morrowind",
    ["Sacred Lands Region"] = "Morrowind",
    ["Salt Marsh Region"] = "Morrowind",
    ["Sea of Ghosts Region"] = "Morrowind",
    ["Seitur Region"] = "Morrowind",
    ["Shambalun Veil Region"] = "Morrowind",
    ["Sheogorad"] = "Vanilla",
    ["Shipal-Shin Region"] = "Morrowind",
    ["Solitude Forest Region"] = "Skyrim",
    ["Solstheim, Brodir Grove"] = "Solstheim",
    ["Solstheim, Felsaad Coast"] = "Solstheim",
    ["Solstheim, Hirstaang Forest"] = "Solstheim",
    ["Solstheim, Isinfier Plains"] = "Solstheim",
    ["Solstheim, Moesring Mountains"] = "Solstheim",
    ["Southern Gold Coast Region"] = "Cyrodiil",
    ["Stirk Isle Region"] = "Cyrodiil",
    ["Sundered Scar Region"] = "Morrowind",
    ["Sundered Hills Region"] = "Skyrim",
    ["Telvanni Isles Region"] = "Morrowind",
    ["Thirr Valley Region"] = "Morrowind",
    ["Thirsk Region"] = "Solstheim",
    ["Uld Vraech Region"] = "Morrowind",
    ["Velothi Mountains Region"] = "Morrowind",
    ["Vorndgad Forest Region"] = "Skyrim",
    ["West Gash Region"] = "Vanilla",
    ["West Weald Region"] = "Cyrodiil"
}

return this