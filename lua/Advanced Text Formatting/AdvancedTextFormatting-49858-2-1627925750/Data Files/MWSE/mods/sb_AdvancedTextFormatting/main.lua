local config = require("sb_AdvancedTextFormatting.config")

local replacementTable = {
    ["$pname"]              = config.GetPlayerName, -- get player name
    ["$pfname"]             = config.GetPlayerFirstName, -- get player first name
    ["$plname"]             = config.GetPlayerLastName, -- get player last name
    ["$plevel"]             = config.GetPlayerLevel, -- get player level
    ["$prace"]              = config.GetPlayerRace, -- get player race
    ["$pclass"]             = config.GetPlayerClass, -- get player class
    ["$pskill{(%d)}"]       = config.GetPlayerSkill, -- get player skill
    ["$pbirth"]             = config.GetPlayerBirthsign, -- get player birthsign
    ["$psex"]               = config.GetPlayerSex, -- get player sex
    ["$pclothing{(%d)}"]    = config.GetPlayerClothing, -- get player clothing
    ["$parmour{(%d)}"]      = config.GetPlayerArmour, -- get player armour
    ["$parmor{(%d)}"]       = config.GetPlayerArmour, --
    ["$pfaction{(%d)}"]     = config.GetPlayerFactionRank, -- get player faction rank
    ["$prank{(%d)}"]        = config.GetPlayerFactionRank, --
    ["$pgold"]              = config.GetPlayerGold, -- get player gold
    ["$pg"]                 = config.GetPlayerGold, --
    ["$gold"]               = config.GetPlayerGold, --
    ["$g"]                  = config.GetPlayerGold, --

    ["$date{(%d)}"]         = config.GetDate, -- get nth date
    ["$month{(%d)}"]        = config.GetMonthName, -- get nth month
    ["$class{(%d)}"]        = config.GetClassName, -- get nth class
    ["$skill{(%d)}"]        = config.GetSkillName, -- get nth skill
    ["$spell{(%d)}"]        = config.GetSpellName, -- get nth spell
    ["$magic{(%d)}"]        = config.GetMagicEffectName, -- get nth magic effect
    ["$faction{(%d)}"]      = config.GetFactionName, -- get nth faction
    ["$rank{(%d),%s*(%d)}"] = config.GetFactionRankName, -- get nth rank of mth faction
    ["$race{(%d)}"]         = config.GetRaceName, -- get nth race
    ["$birthsign{(%d)}"]    = config.GetBirthsignName, -- get nth birthsign
    ["$birth{(%d)}"]        = config.GetBirthsignName, --
    ["$sign{(%d)}"]         = config.GetBirthsignName, --
    ["$weather{(%d)}"]      = config.GetWeather, -- get nth weather type

    ["$HH"]                 = config.GetHour, -- get this 24 hour
    ["$mm"]                 = config.GetMinute, -- get this minute
    ["$ss"]                 = config.GetSecond, -- get this second
    ["$hh"]                 = config.GetAmPmHour, -- get this 12 hour
    ["$ap"]                 = config.GetAmPm, -- get am / pm
    ["$dd"]                 = config.GetThisDay, -- get this day
    ["$MM"]                 = config.GetThisMonth, -- get this month
    ["$yy"]                 = config.GetThisYear, -- get this year
    ["$YY"]                 = config.GetThisYearTh, -- get this year with ordinal
    ["$GG"]                 = config.GetThisEra, -- get this era
    ["$cweather"]           = config.GetCurrentWeather, -- get current weather

    -- deprecated --
    ["$cday"]               = config.GetThisDay, -- get this day
    ["$cmonth"]             = config.GetThisMonth, -- get this month
    ["$cyear"]              = config.GetThisYear, -- get this year
    ["$cyearth"]            = config.GetThisYearTh, -- get this year with ordinal
    ["$cera"]               = config.GetThisEra, -- get this era
    ----------------

    ["$gv{(%a+)}"]          = config.GetGlobal, -- get global variable
    ["$sv{(%a+), (.++)}"]   = config.SetGlobal, -- set global variable
    ["${(.+)}"]             = config.ExecuteCode, -- execute lua code

    ["%[(.+)%]"]            = config.ToUppercase, -- uppercase
    ["<(.+)>"]              = config.ToLowercase, -- lowercase
}

--------------------------------------------------

local function kLoop(child)
    for k, v in pairs(replacementTable) do
        child.text = child.text:gsub(k, v)
    end
end

local function findAndReplace(child)
    if (child) then
        kLoop(child)
    end
end

local function childLoop(child)
    if (child.children) then
        for _, ch in pairs(child.children) do
            findAndReplace(ch)
            childLoop(ch)
        end
    end
end

--------------------------------------------------

local function replaceDialogue(e)
    local child = { text = e:loadOriginalText() }

    findAndReplace(child)
    e.text = child.text
end

local function bookGetText(e)
    local book_scroll = { text = e.text }
    kLoop(book_scroll)
    e.text = book_scroll.text
end

local function replaceUI(e)
    local menuMap = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
    if (menuMap) then
        findAndReplace(menuMap)
    end

    local menuPopup = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if (menuPopup) then
        local child = menuPopup:findChild(tes3ui.registerID("MenuMulti_map_notify"))
        findAndReplace(child)
    end

    local menuDialogue = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    if (menuDialogue) then
        local child = menuDialogue:findChild(tes3ui.registerID("PartDragMenu_main"))
        childLoop(child)
    end

    local menuJournal = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
    if (menuJournal) then
        local children = {
            menuJournal:findChild(tes3ui.registerID("MenuBook_page_1")),
            menuJournal:findChild(tes3ui.registerID("MenuBook_page_2")),
            menuJournal:findChild(tes3ui.registerID("MenuJournal_topicscroll"))
        }
        for _, child in ipairs(children) do
            if (child) then
                childLoop(child)
            end
        end
    end

    local menuContents = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if (menuContents) then
        findAndReplace(menuContents)
    end
end

--------------------------------------------------

local function init()
    event.register("infoGetText", replaceDialogue)
    event.register("bookGetText", bookGetText)
    event.register("uiEvent", replaceUI)
end

event.register("initialized", init)
