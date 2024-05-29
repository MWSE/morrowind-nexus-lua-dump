local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local log = Herbert_Logger()
local cfg = hlib.get_mod_config() ---@type herbert.HLP.config

---@class herbert.HLP.common
local common = {
    -- stores a list of all skill books. saved when game launches because it will be changed during gameplay
    skill_books = hlib.tbl_ext.new() ---@type table<string, tes3.skill>|herbert.Extended_Table
}
local skill_books = common.skill_books


event.register("initialized", function(e)
    ---@param book tes3book
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if book.skill and book.skill >= 0 then
            skill_books[book.id] = book.skill
            -- book.skill = -1
        end
    end
end, {priority=-100})



-- fades to black. if a time isnt specified, the config value is used.
---@param fade_time boolean|number amount of time to fade out for
---@param game_time boolean|number amount of game time to pass
function common.fade_to_black(fade_time, game_time)
    if game_time ~= false then
        if game_time == nil or game_time == true then
            game_time = cfg.study_pass_time
            if game_time > 0 then
                tes3.advanceTime{hours=1}
            end
        end
    end
    if fade_time == false then return end
    if fade_time == nil or fade_time == true then
        log:trace("using config setting for `fade_to_black_time`")
        fade_time = cfg.fade_to_black_time
    end
    if fade_time <= math.epsilon then
        log:trace("not fading to black because time <= epsilon")
        return 
    end
    log("fading to black for %s seconds", fade_time)
    tes3.fadeOut{duration=fade_time}
    timer.start{duration=fade_time + 0.25, type=timer.real, callback=function ()
        tes3.fadeIn{duration=fade_time * 0.75}
    end}
end

local OT_book = tes3.objectType.book
-- checks if a book is a skill book, and returns its skill id if it is
---@param book tes3book
---@return tes3.skill?
function common.get_skill_id(book)
    if not book or book.objectType ~= OT_book or cfg.blacklist[book.id] then return end
    
    return skill_books[book.id]
end


--- calculates how much XP for award for progressing your knowledge in a skill book
-- default implementation is to award 0.033 * progress * (TOTAL XP FOR NEXT SKILL LEVEL)
---@param book tes3book
---@param skill_id tes3.skill
---@param progress number progress made in this book
---@param xp_requirement integer the total amount of XP needed to level up this skill to the next level
function common.calc_xp_award(book, skill_id, xp_requirement, progress)
    return 0.015 * progress * xp_requirement
end



return common