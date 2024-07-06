
-- local livecoding = include("herbert100.livecoding.livecoding")
-- local register_event = livecoding and livecoding.registerEvent or event.register
local register_event = event.register
local log = Herbert_Logger()



if lfs.fileexists("data files\\mwse\\mods\\herbert100\\quest log menu\\config.lua") then
    log:info("found old config file, trying to delete it.......")
    local status = os.remove("data files\\mwse\\mods\\herbert100\\quest log menu\\config.lua")
    if status then
        log:info("old config file was deleted successfully")
    else
        log:error("old config file (\"quest log menu\\config.lua\") could not be deleted. this may cause problems")
    end
end
local hlib = require("herbert100")
local cfg = hlib.get_mod_config() --[[@as herbert.QLM.config]]

local Quest_Log = hlib.import("quest_log_menu") ---@type herbert.QLM.Quest_Log

local quest_log ---@type herbert.QLM.Quest_Log?


-- get rid of our reference to the menu whenever it gets closed
register_event("herbert.QLM:menu_destroyed", function (e)
    quest_log = nil
end)

local kc = cfg.key

---@param e mouseButtonDownEventData
local function mouse_button_clicked(e)
    if e.button == kc.mouseButton and not tes3ui.menuMode() and tes3.player then
        quest_log = Quest_Log.new()
    end
end


---@param e keyDownEventData
local function key_pressed(e)
    if e.keyCode == kc.keyCode and not tes3ui.menuMode() and tes3.player then
        quest_log = Quest_Log.new()
    end
end

local function up_arrow_pressed()
    log:trace("pressed up arrow!")
    if quest_log and tes3ui.menuMode() then
        quest_log:prev_quest()
    end
end

local function down_arrow_pressed()
    log:trace("pressed down arrow!")
    if quest_log and tes3ui.menuMode() then
        quest_log:next_quest()
    end
end



local function esc_pressed()
    Quest_Log.close(true)
end

local function initialized()
    register_event(tes3.event.mouseButtonDown, mouse_button_clicked)
    register_event(tes3.event.keyDown, key_pressed)
    register_event(tes3.event.keyDown, esc_pressed, {filter=tes3.scanCode.esc, priority=1000})
    register_event(tes3.event.keyDown, down_arrow_pressed, {filter=tes3.scanCode.keyDown})
    register_event(tes3.event.keyDown, up_arrow_pressed, {filter=tes3.scanCode.keyUp})
    log:write_init_message()
end
register_event(tes3.event.initialized, initialized)

-- if livecoding and tes3.isInitialized() then
--     log:info("livecoding installed, using livecoding")
--     initialized()
-- end

register_event("herbert:QLM:MCM_closed", function (e)
    kc = cfg.key
    log:trace("closed mcm. config = %s", json.encode, cfg)
end, {filter=hlib.get_mod_name()})



register_event("modConfigReady", function (e)

    local template = mwse.mcm.createTemplate{label=hlib.get_mod_name(), config=cfg, defaultConfig=hlib.import("config.default")}
    local page = template:createSideBarPage{label="Settings", 
        description='This mod makes it easier to keep track of your active quests. It comes with some robust searching features.\n\n\z
            \z
            When searching for quests, the mod will check the quest name, as well as the names and locations of quest givers. \z
                Optionally, you can allow searching quest topics and quest progress \z
                (although these options will make the first search a bit slower as more files will need to be loaded).\n\n\z
            \z
            This mod uses fuzzy searching to find quests. \z
                This basically means that you\'re allowed to make minor typos when searching for these things, and you can search using acronyms. \z
                For example, "DBA" will match "Dark Brotherhood Attacks".\n\n\z
            \z
            Searching is only case-sensitive if you type an upper-case letter. (So, "dark brotherhood" will match "Dark Brotherhood Attacks", but "dArk" won\'t.) \z
                This is to make it easier to search for names and acronyms. (For example, "DBA" will basically only match acronyms, while "dba" won\'t.)\n\n\z
                \z
            There is also an option to search via keywords. This is explained in more detail in that setting\'s description.\n\n\z
            All changes take effect immediately.\z
            \z
        '
    }

    page:createKeyBinder{label="Quest log key", configKey="key", description="This key opens the quest log menu."}
    

    do -- make ui settings
        local ui_cat = page:createCategory{label="UI Settings", configKey="ui",
            description="These settings control the appearance of the UI. They have no impact on functionality.\n\n\z
                \z
                These settings cannot be changed from within the quest log menu. \z
                (But changes made in the MCM still take effect immediately.)\z
            "
        }

        ui_cat:createPercentageSlider{label="Menu: Horizontal size", configKey="x_size",
            description="How wide should the menu be? 100% means the menu will use all available horizontal space.",
            min = .3
        }

        ui_cat:createPercentageSlider{label="Menu: Vertical size", configKey="y_size",
            description="How tall should the menu be? 100% means the menu will use all available vertical space.",
            min = .3
        }

        ui_cat:createYesNoButton{label="Show quest icons?", configKey="show_icons",
            description="If the \"Skyrim Style Quest Notifications\" is installed, this option will display those quest icons in the quest log menu.\n\n\z
            \z
            Note: only the iconlist.lua file is required in order to use this setting. You do not need to install the full mod."
        }
        ui_cat:createYesNoButton{label="Light mode?", configKey="light_mode",
            description="If enabled, a color palette more similar to the traditional journal menu will be used."
        }

        ui_cat:createYesNoButton{label="Include regions in quest header?", configKey="region_names",
            description="If enabled, then regions will be included when displaying locations of actors/quest givers.\n\n\z
                Note: This option does not impact how searching works."
        }


        page:createYesNoButton{label="Show technical quest information?", configKey="show_technical_info",
            description='If enabled, various pieces of technical information will be included in the menu.This includes:\n\z
                Which ESPs modified this quest,\n\z
                What faction the quest is associated with (if any)\n\z
                What the relevant Dialogue IDs are\n\z
                What your current journal index is.\n\n\z
                \z
                This option can also be changed in the quest log menu itself, at any time.'
        }
    end

    do -- add search settings
        local search_cat = page:createCategory{label="Search Settings", configKey="search",
            description="These settings govern how the search funcionality works. \z
                Most of these settings can be changed within the quest log menu."
        }


        search_cat:createYesNoButton{label="Use keyword search?", configKey="keywords",
            description='If enabled, the order of the words you type in won\'t matter, except when checking against quest names. \z
                    (i.e., quest names never use keyword search.) \z
                    Enabling this setting can make searching quest progress a bit more accurate, as otherwise you will have to \z
                    exactly match the order that words are said. \n\n\z
                \z
                This option also makes searching based on relevant actors/cells more accurate, as otherwise you will have to search \z
                    based on the order in which those actors/cells appeared.\n\n\z
                    For example, if this setting is off, then you may find that "mournhold ebonheart" doesn\'t match anything, but \z
                    "ebonheart mournhold" does.\z
            '
        }

        search_cat:createPercentageSlider{label="Fuzzy search confidence", configKey="fzy_confidence",
            description='How "good" should a match be in order to be displayed in the results?\n\n\z
                Roughly speaking, the closer to 100% this is, the more closely the search text has to match the target text.\n\z
                For example, searching using acronyms is less likely to succeed when this setting is close to 100%.',
            min = 0.1,
            max = .8
        }
        do -- add search weight settings
            local weights_cat = search_cat:createCategory{label="Search weights", configKey="weights",
                description="These settings control how certain things should be weighted when fuzzy searching. \z
                    Higher weights mean the corresponding field is prioritized when fuzzy searching.\n\n\z
                    \z
                    You can probably ignore these settings, but you may find them helpful if you want certain types of fields to \z
                        be \"more important\" when searching for quests. By default, quest names, the names of quest givers, and \z
                        quest locations are highest priority.\n\n\z
                    \z
                    Setting a weight to 0 means the relevant part of a quest won't be considered when fuzzy searching.\z"
            }

            weights_cat:createPercentageSlider{label="Quest Name", configKey="quest_name", max=2,
                description="How important should the quest name be when fuzzy searching?\n\nSet to 0% to ignore quest names when searching."
            }
            weights_cat:createPercentageSlider{label="Names of Quest Givers", configKey="actor_names", max=2,
                description="How important should the names of quest givers be when fuzzy searching?\n\n\z
                    This allows things like searching \"Caius\" to see all quests that involve \"Caius Cosades\".\n\n\z
                    Set to 0% to ignore the names of quest givers when searching."
            }
            weights_cat:createPercentageSlider{label="Locations of Quest Givers", configKey="location_data", max=2,
                description="How important should the locations of quest givers be when fuzzy searching?\n\n\z
                    This allows things like searching \"Foreign Quarter\" to see all quests that are connected to the Foreign Quarter canton in Vivec.\n\n\z
                    Set to 0% to ignore the locations of quest givers when searching."
            }
            weights_cat:createPercentageSlider{label="Regions", configKey="region_names", max=2,
                description="How important should the region of a quest be when fuzzy searching?\n\n\z
                    This allows things like searching \"West Gash\" to see all quests that involve the West Gash Region.\n\n\z
                    Set to 0% to ignore regions when searching."
            }
            weights_cat:createPercentageSlider{label="Quest Topics", configKey="topics", max=2,
                description="How important should quest topics be when fuzzy searching?\n\n\z
                    Quest topics are the highlighted words shown in the \"Quest Progress\" section.\n\n\z
                    This allows things like searching \"dwemer\" to see all quests that involve dwemer artifacts and dwemer technologies.\n\n\z
                    Set to 0% to ignore the locations of quest givers when searching.\n\n\z
                    Note: If this setting or the \"Quest Progress\" setting is set to something above 0%, \z
                        then the very first search that happens (per game launch) \z
                        may be noticeably slower. (About 2 seconds slower, with an SSD and 50 active quests.) \z
                        This is because searching through the progress of a quest involves loading a bunch of files.\z
                "
            }
            weights_cat:createPercentageSlider{label="Quest Progress", configKey="quest_progress", max=2,
                description="How important should quest progress entries be when fuzzy searching?\n\n\z
                    \z
                    This setting lets you search for any of the text that shows up in a numbered entry in the \"Quest Progress\" section.\n\n\z
                    \z
                    This allows things like searching \"documents\" to find the \"Report to Caius Cosades\" quest \z
                        (because the first entry contains the phrase \"I must give him a package of documents\").\n\n\z
                    \z
                    Set to 0% to ignore the quest progress entries when searching.\n\n\z
                    Note: If this setting or the \"Topics\" setting is set to something above 0%, \z
                        then the very first search that happens (per game launch) \z
                        may be noticeably slower. (About 2 seconds slower, with an SSD and 50 active quests.) \z
                        This is because searching through the progress of a quest involves loading a bunch of files.\z
                "
            }
        end 
    end
    do -- make quest list settings
        local quest_list_cat = page:createCategory{label="Quest List Settings", configKey="quest_list",
            description="These settings control which quests will appear in the quest list, shown on the left side of the menu.\n\n\z
                \z
                These settings can all be changed in the quest log menu itself.\z
            "
        }
        quest_list_cat:createYesNoButton{label="Show completed quests?", configKey="show_completed", 
            description="If true, completed quests will also be shown in the journal, underneath the active quests. \n\n\z
            This setting will slightly increase the time it takes to open the journal for the first time. \z
            (It won't have a performance impact afterwards.)\z
            ",
        }

        quest_list_cat:createYesNoButton{label="Show hidden quests?", configKey="show_hidden", 
            description="If true, \"hidden\" quests will also be shown in the journal, underneath the active quests. \n\n\z
                You can hide/unhide quests by clicking on the appropriate button at the bottom of the quest menu. (In the miscellaneous information section.) \z
            ",
        }
    end
    
    do -- advanced settings
        local adv_settings = page:createCategory{label="Advanced settings", description="These allow you to change more niche settings."}

        adv_settings:createYesNoButton{label="Lazy loading", configKey="lazy_loading", 
            description='If disabled, everything will be loaded when the menu opens. If disabled, things will be loaded only when they\'re needed.\n\n\z
                \z
                Enabling this option means this mod will wait until the last possible second to load files. This is nice because it means the menu opens much faster. \z
                    But the loading still has to happen at some point, so other things might be slightly slower.\n\n\z
                    Disabling this will typically result in the menu taking an extra 2 to 5 seconds to open, but only the very first time it\'s opened per game launch. \z
                    Each subsequent time the menu is opened, it will only take (at most) 0.05 seconds longer to open if this option is disabled.\n\n\z
                \z
                This setting only really matters if you have a large quest list, or if your game is installed on a hard drive instead of a solid state drive.\n\n\z
                \z
                Note: This setting only really affects what happens the first time the menu is opened (per game launch).\n\n\z
                \z
                If searching "topics" and "quest progress" is disabled, then it\'s recommended you keep lazy loading enabled. \z
                    This is because loading a quest\'s topics and progress involves a few slow disk operations, and those can really pile up when there are a lot of quests. \z
                    So, lazy loading allows those things to only happen whenever the quest is actually being shown in the menu.\n\n\z
                \z
            '
        }
        log:add_to_MCM(adv_settings)

    end
    

    template.onClose = function()
        -- the "modConfigClosed" event is the only part of my MCM wrapper that hasn't gotten merged 
        -- into MWSE proper (except for the i18n stuff i guess)
        -- so, i'll just fire a custom event here.
        -- if the `modConfigClosed` PR gets merged, then i'll happily start using that event
        -- and remove this custom one
        -- (so don't count on future versions of this mod triggering this event)
        event.trigger("herbert:QLM:MCM_closed", {mod_name = template.label}, {filter=template.label})
        mwse.saveConfig(template.label, cfg)
    end


    ---@param comp mwseMCMComponent|mwseMCMCategory|mwseMCMTemplate|mwseMCMSetting
    local function add_defaults_to_descriptions(comp)
        local sub_comps = comp.pages or comp.components
        if sub_comps then
            for _, sub_comp in ipairs(sub_comps) do
                add_defaults_to_descriptions(sub_comp)
            end
        end
        if not comp.variable then return end
        local default_val = comp.variable.defaultSetting
        local default_str = comp:convertToLabelValue(default_val)
        if comp.description == nil then
            comp.description = "Default: " .. default_str
        else
            comp.description = string.format("%s\n\nDefault: %s", comp.description, default_str)
        end
    end

    add_defaults_to_descriptions(template)
    template:register()

end, {doOnce=true})