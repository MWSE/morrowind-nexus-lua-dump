---@alias herbert.HLP.defns.study_outside_inventory
---|0 never allow it
---|1 allow it, so long as the book is not owned by a guard or a book seller
---|2 always allow it

---@class herbert.HLP.config
local default = {
    blacklist = {},

    fade_to_black_time = 0.0,
    study_pass_time = 0.0,
    play_sound = true,
    skill_book_weight = 1.0,
    blk_until_lvled = true,

    study_outside_inventory = 1, ---@type herbert.HLP.defns.study_outside_inventory
    show_reason_in_tooltip = true,
}

return default