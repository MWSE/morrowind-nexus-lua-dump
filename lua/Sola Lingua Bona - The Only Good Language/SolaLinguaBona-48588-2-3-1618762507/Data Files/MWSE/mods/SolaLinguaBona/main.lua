local config = require("SolaLinguaBona.config")
config.init()

--------------------------------------------------

local npcFaction
local npcRace

local function unformat(text)
    return text:gsub("@", ""):gsub("#", ""):gsub("\n\n", "$"):gsub("\n", " "):gsub("[$]", "\n\n")
end

local function kLoop(kList, child, langID)
    langID = langID or config.getSettings().langID
    for _, k in pairs(kList) do
        -- check there is a difference
        if (k[1] ~= k[2]
            and k[1] ~= "" and k[2] ~= ""
            and k[1] and k[2]) then
            -- translate Imperial to Dunmer
            if (langID == 1 and (k[3] == nil or k[3] == 0 or k[3] == 1)) then
                child.text = child.text:gsub(k[1], k[2])
            -- translate Dunmer to Imperial
            elseif (langID == 2 and (k[3] == nil or k[3] == 0 or k[3] == 2)) then
                child.text = child.text:gsub(k[2], k[1])
            end
        end
    end
end

local function findAndReplace(child, langID)
    langID = langID or config.getSettings().langID
    -- if child exists...
    if (child) then
        -- for each mod
        if (table.getn(config.getMods()) > 0) then
            for _, mod in pairs(config.getMods()) do
                local protected = mod.config["protected"]
                if (protected) then
                    for _, kvp in pairs(protected) do
                        child.text = child.text:gsub(kvp[1], kvp[2])
                    end
                end
                for k, v in pairs(mod.config) do
                    if (k ~= "protected" and k ~= "npcRaces" and k ~= "npcFactions") then
                        kLoop(v, child, langID)
                    end
                end
                if (protected) then
                    for _, kvp in pairs(protected) do
                        child.text = child.text:gsub(kvp[2], kvp[1])
                    end
                end
            end
        end
        -- temp replace protected phrases
        for _, protected in pairs(config.getProtected()) do
            child.text = child.text:gsub(protected[1], protected[2])
        end
        -- for each other
        kLoop(config.getOther(), child, langID)
        -- for each race
        kLoop(config.getRaces(), child, langID)
        -- for each birthsign
        kLoop(config.getBirthsigns(), child, langID)
        -- for each place
        kLoop(config.getPlaces(), child, langID)
        -- undo temp replace protected phrases
        for _, protected in pairs(config.getProtected()) do
            child.text = child.text:gsub(protected[2], protected[1])
        end
        child.text = unformat(child.text)
    end
end

local function childLoop(child)
    if (child.children) then
        for _,ch in pairs(child.children) do
            findAndReplace(ch)
            childLoop(ch)
        end
    end
end

--------------------------------------------------

local function getFactionAndRaceNPC(e)
    if (config.getSettings().enabled) then
        if (e.activator == tes3.player and e.target.object.objectType == tes3.objectType.npc) then
			if (e.target.object.faction) then
				npcFaction = e.target.object.faction.id
			end
			if (e.target.object.race) then
				npcRace = e.target.object.race.id
			end
        end
    end
end

local function replaceDialogue(e)
    local child = {text = e:loadOriginalText()}
    local npcFactions = {}
    local npcRaces = {}

    if (table.getn(config.getMods()) > 0) then
        for _, mod in pairs(config.getMods()) do
            table.insert(npcFactions, mod.config["npcFactions"])
            table.insert(npcRaces, mod.config["npcRaces"])
        end
    end

    if (npcFaction) then
        if (npcFactions[npcFaction]) then
            findAndReplace(child, npcFactions[npcFaction])
        else
            findAndReplace(child, config.getNpcFactions(npcFaction))
        end
    elseif (npcRace) then
        if (npcRaces[npcRace]) then
            findAndReplace(child, npcRaces[npcRace])
        else
            findAndReplace(child, config.getNpcRaces(npcRace))
        end
    end
    e.text = child.text
end

local function replaceTooltip(e)
    if (config.getSettings().enabled and config.getSettings().langID > 0) then
        local child = e.tooltip:findChild(tes3ui.registerID("HelpMenu_destinationCell"))
            or e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
            or e.tooltip:findChild(tes3ui.registerID("racename"))
            or e.tooltip:findChild(tes3ui.registerID("race"))
        findAndReplace(child)
    end
end

local function replaceUI(e)
    if (config.getSettings().enabled and config.getSettings().langID > 0) then
        local menuMap = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
        if (menuMap) then
            findAndReplace(menuMap)
        end

        local menuPopup = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
        if (menuPopup) then
            local child = menuPopup:findChild(tes3ui.registerID("MenuMulti_map_notify"))
            findAndReplace(child)
        end

        local menuStats = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
        if (menuStats) then
            local race = menuStats:findChild(tes3ui.registerID("MenuStat_race"))
            findAndReplace(race)
            local birthsign = menuStats:findChild(tes3ui.registerID("birth"))
            findAndReplace(birthsign)
        end

        local menuDialogue = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
        if (menuDialogue) then
            local child = menuDialogue:findChild(tes3ui.registerID("PartDragMenu_main"))
            childLoop(child)
        end

        local menuChargen = tes3ui.findMenu(tes3ui.registerID("MenuRaceSex")) or tes3ui.findMenu(tes3ui.registerID("MenuBirthSign")) or tes3ui.findMenu(tes3ui.registerID("MenuStatReview"))
        if (menuChargen) then
            local child = menuChargen:findChild(tes3ui.registerID("MenuRaceSex_RaceList")) or menuChargen:findChild(tes3ui.registerID("MenuBirthSign_BirthSignScroll")) or menuChargen:findChild(tes3ui.registerID("MenuStatReview_left_main"))
            if (child) then
                childLoop(child)
            end
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
end

--------------------------------------------------

local function init()
    event.register("activate", getFactionAndRaceNPC)
    event.register("infoGetText", replaceDialogue)
    event.register("uiObjectTooltip", replaceTooltip)
    event.register("uiEvent", replaceUI)
end

event.register("initialized", init, {priority = 10})