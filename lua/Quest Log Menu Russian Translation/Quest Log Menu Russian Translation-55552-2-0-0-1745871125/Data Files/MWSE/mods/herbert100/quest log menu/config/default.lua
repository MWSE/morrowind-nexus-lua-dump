---@class herbert.QLM.config : herbert.config
---@field show_completed boolean
---@field show_finished boolean
---@field show_hidden boolean
---@field version herbert.SemVer
local default = {
    load_subtopics = false,
    show_technical_info = false,
    lazy_loading = true,
    log_level = 3, ---@type herbert.Logger.LEVEL
    
    quest_list = {
        show_completed = false,
        show_hidden = false,
    },

    search = {
        -- all_fzy = true,
        keywords = false,
        fzy_confidence = 0.35,
        -- quest_progress = false,
        set_first_result_active = true,
        weights = {
            quest_name = 1.3,
            actor_names = 1.2,
            location_data = 1.15,
            region_names = 0.9,
            topics = 1,
            quest_progress = 0.7,
        }

    },
    


    ui = {
        x_size = 0.8,
        y_size = 0.9,
        show_icons = true,
        light_mode = false,
        region_names = false,
    },


    ---@type mwseKeyMouseCombo
    key = { ---@diagnostic disable-next-line: assign-type-mismatch
        keyCode=tes3.scanCode.h,
    }
}

return default