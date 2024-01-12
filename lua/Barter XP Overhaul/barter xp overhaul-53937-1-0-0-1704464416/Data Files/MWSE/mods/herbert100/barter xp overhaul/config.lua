 -- initialize config. im doing it this way for nice code completion suggestions in visual studio
---@class BXP.config
local default_config = {
    enable=true,                    -- award xp on successful barters
    exercise_skill_enable = true,   -- block vanilla xp
    coeff=1.5,                      -- coefficient for the formula
    haggle_coeff=1.25,              -- coefficient for the haggle bonus
    barter_offer_priority=-1,
    barter_offer_claim=false,
    exercise_skill_priority = 1000,
}
return mwse.loadConfig("Barter XP Overhaul", default_config) ---@type BXP.config
