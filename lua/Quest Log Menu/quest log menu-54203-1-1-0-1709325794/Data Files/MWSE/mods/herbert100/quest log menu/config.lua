---@class herbert.QLM.config
local default = {
    set_first_result_active = true,
    load_subtopics = false,
    search_quest_text = false,
    show_completed = false,
    show_hidden = false,
    all_fzy = false,
    keyword_search = true,
    ---@type mwseKeyMouseCombo
    key = { ---@diagnostic disable-next-line: assign-type-mismatch
        keyCode=tes3.scanCode.h,
    }
}
---@type herbert.QLM.config
local cfg = mwse.loadConfig(
    -- get the mods metadata, then get the name
    require("herbert100").get_active_mod_info(-1).metadata.package.name,
    default
)
return cfg