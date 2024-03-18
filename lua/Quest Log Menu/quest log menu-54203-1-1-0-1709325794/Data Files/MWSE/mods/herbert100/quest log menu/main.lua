
-- local livecoding = include("herbert100.livecoding.livecoding")
-- local register = livecoding and livecoding.registerEvent or event.register

local cfg = require("herbert100.quest log menu.config")
local log = Herbert_Logger.new()




local Quest_Log = require("herbert100.quest log menu.Quest_Log")

local quest_log ---@type herbert.QLM.Quest_Log

local kc = cfg.key

---@param e mouseButtonDownEventData
local function mouse_button_clicked(e)
    if e.button == kc.mouseButton and not tes3.menuMode() and tes3.player then
        quest_log = Quest_Log()
    end
end


---@param e keyDownEventData
local function key_pressed(e)
    if e.keyCode == kc.keyCode and not tes3.menuMode() and tes3.player then
        quest_log = Quest_Log()
    end
end


local function down_arrow_pressed()
    if tes3.menuMode() and quest_log and quest_log:is_valid() then
        quest_log:next_quest()
    end
end

local function up_arrow_pressed()
    if tes3.menuMode() and quest_log and quest_log:is_valid() then
        quest_log:prev_quest()
    end
end


local function esc_pressed()
    Quest_Log.close(true)
end

local function initialized()
    Quest_Log.initialize()
    event.register(tes3.event.mouseButtonDown, mouse_button_clicked)
    event.register(tes3.event.keyDown, key_pressed)
    event.register(tes3.event.keyDown, esc_pressed, {filter=tes3.scanCode.esc, priority=1000})
    event.register(tes3.event.keyDown, down_arrow_pressed, {filter=tes3.scanCode.keyDown})
    event.register(tes3.event.keyDown, up_arrow_pressed, {filter=tes3.scanCode.keyUp})
    log:write_init_message()
end
event.register(tes3.event.initialized, initialized)

-- if livecoding and tes3.isInitialized() then
--     log:info("livecoding installed, using livecoding")
--     log("debug message test")
--     initialized()
-- end

event.register("loaded", function (e)
    local data = table.getset(tes3.player.data, "herbert_QL", {})
    local hidden_quests = table.getset(data, "hidden_ids", {})
end)


event.register("modConfigReady", function (e)
    local MCM = require("herbert100.MCM").new()
    local page = MCM:new_sidebar_page{label="Settings", 
        desc='This mod makes it easier to keep track of your active quests. It comes with some robust searching features.\n\n\z
            \z
            When searching for quests, the mod will check: the quest name, names and locations of quest givers, and relevant topics (i.e., highlighted words). \z
            If "search quest progress" is enabled, then the mod will also check everything in the "Quest Progress" section of the quest menu.\n\n\z
            \z
            Fuzzy searching is enabled for quest names, quest giver names, and quest giver locations. \z
            This basically means that you\'re allowed to make minor typos when searching for these things, and you can search using acronyms. \z
            For example, "DBA" will match "Dark Brotherhood Attacks".\n\n\z
            \z
            Searching is done via keywords (unless "search keywords" is disabled). This is explained in more detail in that setting.\n\n\z
            \z
            Searching is only case-sensitive if you type an upper-case letter. (So, "dark brotherhood" will match "Dark Brotherhood Attacks", but "dArk" won\'t.) \z
            This is to make it easier to search for names and acronyms. (For example, "DBA" basically only match acronyms, while "dba" won\'t.)\n\n\z
            \z
            With the exception of the "logging level" and "keybind" settings, all the settings on this page can also be changed in the quest menu itself.\z
            \z
            
            
        '
    }
    page.component:createKeyBinder{label="Quest log key",
        description="This key opens the quest log.",
        variable=mwse.mcm.createTableVariable{id="key", table=MCM.config},
    }

    page:new_button{label="Show completed quests?", id="show_completed", 
        desc="If true, completed quests will also be shown in the journal, underneath the active quests. \n\n\z
        This setting will slightly increase the time it takes to open the journal for the first time. \z
        (It won't have a performance impact afterwards.)\z
        ",
    }

    page:new_button{label="Show hidden quests?", id="show_hidden", 
        desc="If true, \"hidden\" quests will also be shown in the journal, underneath the active quests. \n\n\z
            You can hide/unhide quests by clicking on the appropriate button at the bottom of the quest menu. (In the miscellaneous information section.) \z
        ",
    }
    page:new_button{label="Search quest progress?", id="search_quest_text", 
        desc='If true, then you\'ll be able to search for quests by typing in words that appear in the \"Quest Progress\" section.\n\n\z
            \z
            For example, this option will let you search for the quest "Fargoth\'s Hiding Place" by typing "at night"\n\n\z
            \z
            Default: No.\z
            '   
    }
    page:new_button{label="Fuzzy search everything?", id="all_fzy", 
        desc='If true, then quest topics (and quest progression, if applicable) will be searched using fuzzy search.\n\n\z
            This means that you can use abbreviations when searching against quest progression/topics, but it will likely \z
            mean you\'ll need to type in more characters before you find what you\'re looking for.\n\n\z
            \z
            If this setting is disabled, then fuzzy search will only be used on quest names, quest giver names, and quest giver locations. \z
            Everything else will be matched literally (after taking into account the "use keywords" settings).\n\n\z
            Default: No.\z
            '
    }

    page:new_button{label="Use keyword search?", id="keyword_search",
        desc='If enabled, the order of the words you type in won\'t matter, except when checking against quest names. (i.e., quest names never use keyword search.) \z
            Enabling this setting can make searching quest progress a bit more accurate, as otherwise you will have to exactly match the order that words are said. \n\n\z
            \z
            This option also makes searching based on relevant actors/cells more accurate, as otherwise you will have to search based on the order in which those actors/cells appeared.\n\n\z
            For example, if this setting is off, then you may find that "mournhold ebonheart" doesn\'t match anything, but "ebonheart mournhold" does.\n\n\z
            \z
            Default: Yes.\z
        '
        }
    MCM:register()
    page:add_log_settings()

    log("finished making mcm. logger is now = %s", log)

end)