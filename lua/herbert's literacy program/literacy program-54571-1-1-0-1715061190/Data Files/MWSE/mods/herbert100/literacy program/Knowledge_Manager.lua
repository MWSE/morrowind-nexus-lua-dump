local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local common = hlib.import("common") ---@type herbert.HLP.common
local cfg = hlib.get_mod_config() ---@type herbert.HLP.config

local Knowledge_Bonus = hlib.import("Knowledge_Bonus") ---@type herbert.HLP.Knowledge_Bonus

--- performs in-place addition: `tbl[key] = tbl[key] + val`
---@generic K, V, T
---@param tbl T|{[K]: V}
---@param key K
---@param val V
local function iadd(tbl, key, val) 
    tbl[key] = tbl[key] + val
end

local log = hlib.Logger()

local skill_books = common.skill_books ---@type table<string, tes3.skill>

local function encode_by_skill_name(tbl)
    if not tbl then return "N/A" end
    local t = {}
    for id, name in pairs(tes3.skillName) do
        t[name] = tbl[id]
    end
    return json.encode(t)
end
local mod_info = hlib.get_mod_info()


---@class herbert.HLP.data.player
---@field book_prog table<string, number>
---@field read_at_lvl table<string, integer> a table of book ids, storing information about which skill level they were read at.
-- used by the `blk_until_lvled` config setting
---@field chk boolean? have we already done an import check?
---@field ver string?
local default_player_data = {
    book_prog = {},
    read_at_lvl = {}, ---@type table<string, integer> 
    chk = false,
    ver = tbl_ext.recursive_get(mod_info, "metadata.package.version")
}

--- singleton class that manages and keeps track of:
--- 1. how much we've learned from skill books
--- 2. how much we're able to learn from skill books (based on current stats and player knowledge)
--- 3. all the bonuses that should apply, based on our current knowledge
--- 
--- the naming conventions are as follows: 
--- - **"knowledge":** tends to refer to the collective total of what we've learned from reading skill books for a given skill
--- - **"progress":** refers to how much progress we've made reading a particular skill book.
--- - there is one edge case to this convention: `progress_limits`, which refers to the maximum progress we're allowed to make on any skill book corresponding to a specific skill id.
---@class herbert.HLP.Knowledge_Manager : herbert.Class
---@field skill_knowledge herbert.Extended_Table|table<tes3.skill, number> how much you know about each skill
---@field knowledge_bonuses_by_id herbert.Extended_Table|table<string, herbert.HLP.Knowledge_Bonus> all registered knowledge bonuses
---@field player_data herbert.HLP.data.player access to player data
---@field progress_limits herbert.Extended_Table|table<tes3.skill, number> the limit on how much you can progress any skill book for a given `tes3.skill`.
---@field new fun(): herbert.HLP.Knowledge_Manager
local KM = hlib.Class.new{
    fields={
        {"skill_knowledge", 
            factory=function() return tbl_ext.to_constant(tes3.skillName, 0) end, 
            tostring=encode_by_skill_name,
        },
        {"progress_limits", 
            factory=function() return tbl_ext.to_constant(tes3.skillName, 0) end, 
            tostring=encode_by_skill_name,
        },
        {"knowledge_bonuses_by_id", factory=function() return tbl_ext.new() end},
        {"player_data", tostring=json.encode},
    },
}


function KM:update_progress_limits()

    local player_object = tes3.player.object
    local player_mobile = tes3.mobilePlayer

    local total_prog_by_skill = tbl_ext.inv_map(tes3.skill, function() return 0 end)

    for book_id, progress in pairs(self.player_data.book_prog) do
        iadd(total_prog_by_skill, skill_books[book_id], progress)
    end

    -- multiplier for how much you can learn. this will be multiplied by the base value of the skill
    -- major skills get 1, minor get 0.75, misc get 0.5
    local skill_type_mult = {[0]=1, 0.75, 0.5} ---@type table<tes3.skillType, number>

    -- skills in your specialization get a bonus of 20%, non major skills get a penalty of -15%
    local spec_mults = tbl_ext.new{[0]=0.85, 0.85, 0.85} ---@type table<tes3.specialization, number>
    spec_mults[player_object.class.specialization] = 1.2

    -- favored attributes count 20% more
    local attr_mults = tbl_ext.inv_map(tes3.attribute, function() return 0.2 end)
    for _, attr_id in pairs(player_object.class.attributes) do
        attr_mults[attr_id] = 0.25
    end


    for skill_id, progress in pairs(total_prog_by_skill) do
        local skill = tes3.getSkill(skill_id)
        local skill_stat = player_mobile.skills[1 + skill_id]
        local attr_base = player_mobile.attributes[1 + skill.attribute].base


        local limit = math.max(0, 
            skill_type_mult[skill_stat.type] * spec_mults[skill.specialization] * skill_stat.base 
            -- limit attribute contribution by effectively making the attribute level capped by 100 or 3 * skill_base, whichever is lower
            -- this is so that having 10k strength doesn't overpower things, for example
            + attr_mults[skill.attribute] * math.min(100, 3 * skill_stat.base, attr_base)
        )

        -- heuristically: each skill book that gets fully read will multiply the amount you can learn by 20%
        -- so, if your limit is supposed to be 50 and you read two skill books for 50 points, your new limit will be 50 * (100/500) == 50 * 0.2
        local progress_mult = 1 + progress / 500

        self.progress_limits[skill_id] = math.clamp(limit * progress_mult, 0, 100)
            
        log:trace("calculating max progress for %q.\n\t\z
            book_mult = %s\n\t\z
            max_prog = %s\n\t\z
            total_max_prog = %s",
            skill.name,
            progress,
            limit,
            self.progress_limits[skill_id]
        )
    end
end


--- get the upper limit for how much we can learn from a book
---@param book_id string the id of the book
---@return number limit how much we can learn
function KM:get_book_progress_limit(book_id)
    return skill_books[book_id] and self.progress_limits[skill_books[book_id]]
end


---@param book_id string
---@return number? progress how much we have learned from a book. will be `nil` if player data hasn't been loaded 
function KM:get_book_progress(book_id)
    if not self.player_data then return end
    return self.player_data.book_prog[book_id] or 0
end


---@param skill_id tes3.skill
---@return number knowledge
function KM:get_skill_knowledge(skill_id)
    return self.skill_knowledge[skill_id]
end


-- recalculate our knowledge of each of the specified skills
---@param skill_ids tes3.skill|tes3.skill[]|nil . if `nil`, then all skills will be relalculated
function KM:recalculate_skill_knowledge(skill_ids)
    if not self.player_data then return end
    local SKILL_IDS = hlib.math.Set.new(skill_ids or tes3.skill)

     -- update skill_knowledge
    for skill_id in pairs(SKILL_IDS) do
        self.skill_knowledge[skill_id] = 0
    end
    log:trace("updating knowledge from player_data.book_prog = %s", json.encode, self.player_data.book_prog)
    for book_id, prog in pairs(self.player_data.book_prog) do
        local skill_id = skill_books[book_id]
        if SKILL_IDS:contains(skill_id) then
            log:trace("adding knowledge from book %q (skill_id = %s)", book_id, skill_id)
            self.skill_knowledge[skill_id] = self.skill_knowledge[skill_id] + prog
        end
    end
    log("set skill_knowledge = %s", encode_by_skill_name, self.skill_knowledge)

    -- update knowledge_bonuses
    for _, kb in pairs(self.knowledge_bonuses_by_id) do
        if kb.skill_ids:any(function(id) return SKILL_IDS:contains(id) end) then
            kb:update(self.skill_knowledge)
        end
    end
end

function KM:update_knowledge_bonuses()
     -- update knowledge_bonuses
     for _, kb in pairs(self.knowledge_bonuses_by_id) do
        kb:update(self.skill_knowledge)
    end
end


---@param book_id string id of the book to add progress to
---@param progress_to_add number? how much progress to add. if not provided, progress will be calculated
---@param update boolean? should we update the stored values? Default: true
---@return number? progress_added
function KM:add_book_progress(book_id, progress_to_add, update)
    if not book_id then return end
    local skill_id = skill_books[book_id] ---@type tes3.skill?
    if not skill_id then return end

    progress_to_add = progress_to_add or self:calculate_book_progress_to_add(book_id)
    
    if progress_to_add == 0 or not progress_to_add then return end

    local book_prog = self.player_data.book_prog
    local current_progress = book_prog[book_id] or 0
    local limit = self.progress_limits[skill_id]
    -- local limit = self:get_book_progress_limit(skill_id)

    if current_progress + progress_to_add > limit then return end

    book_prog[book_id] = current_progress + progress_to_add
    tes3.player.modified = true

    
    self.skill_knowledge[skill_id] = self.skill_knowledge[skill_id] + progress_to_add

    if update ~= false then
        for _, kb in pairs(self.knowledge_bonuses_by_id) do
            if table.find(kb.skill_ids, skill_id) then
                kb:update(self.skill_knowledge)
            end
        end
    end

    return progress_to_add

end


function KM:calculate_book_progress_to_add(book_id)
    local cur_progress = tbl_ext.getset(self.player_data.book_prog, book_id, 0)
    local skill_id = skill_books[book_id]
    if not skill_id then return 0 end

    local limit = self.progress_limits[skill_id] -- maximum knowledge the player can currently learn in this skill

    local progress_remaining = limit - cur_progress

    if progress_remaining <= 0 then return 0 end


    local mp = tes3.mobilePlayer
    local attr_id = tes3.getSkill(skill_id).attribute

    -- minimum percentage of progress to add (as an integer)
    -- should be at least 15%, but ideally 33% of the limit. (so equal to 25 when `limit == 100`)
    local min_pct = math.max(15, 0.33 * limit)
    -- maximum percentage of progress to add. 
    -- depends on skill levels, luck, and related attribute levels
    local skill_base = mp.skills[1+skill_id].base
    local attr_base = mp.attributes[attr_id+1].base
    local max_pct = min_pct
        + 0.75 * math.max(0, skill_base - 10)
        + 0.10 * mp.luck.base
        -- attr term. only consider attribute levels up to min(3.5 * skill_base, 100)
        -- and offset attr_base by 25 (since the minimum starting value for attributes is 30)
        + 0.50 * math.max(0, math.min(100, 3.5 * skill_base, attr_base - 25)) 
    

    -- the percentage of progress to add (based on the limit)
    -- but make sure it's at most 50% of what you can learn
    local new_progress_pct = math.min(
        0.5 * limit,
        0.01 * math.random(math.round(min_pct), math.round(max_pct))
    )

    -- make sure the player gets at least 5 progress, at most 30 progress
    local new_progress = math.clamp(new_progress_pct * limit, 5, 30)


    if log.level > 3 then -- log stuff
        log("adding %s progress to book %q. \n\t\z
        new_progress_pct = %s%%\n\t\z
        new_pct_min = %s%% | new_pct_max = %s%%\n\t\z
        actual progress = %s\n\t\z
        ", function ()
            local book = tes3.getObject(book_id)
            return new_progress,
            book.name,
            new_progress_pct * 100,
            min_pct, max_pct,
            cur_progress + new_progress
        end
    )
    end
    -- make sure the newly added progress does not exceed the total amount of remaining progress
    return math.min(new_progress, progress_remaining)
end


function KM:load_player_data()
    self.player_data = hlib.load_player_data("herbert.HLP", default_player_data)
    if not self.player_data then return end

    -- debugging stuff, add skill books
    
    log("player data has already been imported. updating xp multipliers and returning")

    for _, skill_id in pairs(tes3.skill) do
        self.skill_knowledge[skill_id] = 0
    end

    for book_id, progress in pairs(self.player_data.book_prog) do
        iadd(self.skill_knowledge, skill_books[book_id], progress)
    end

    self:recalculate_skill_knowledge()
    self:update_progress_limits()


    -- reading is good stuff needs more testing
    -- if self.player_data.chk then return end

    -- self:import_reading_is_good_data()
    -- self:recalculate_skill_knowledge()

    -- log("updated all books")
    -- self.player_data.chk = true
end



function KM:import_reading_is_good_data()
    if true then return end -- needs more testing

    local spammer_read = tes3.player.data.spammer_publicoRead -- set of read books
    if not spammer_read then return end
    log:info('importing %q progress', "Reading is Good")
    local spammer_books = tes3.player.data.spammer_publicoBooks -- per skill id holds number of books read
    log:trace("spammer books = %s", inspect, spammer_books)
    log:trace("spammer read = %s", inspect, spammer_read)

    for book_id in pairs(spammer_read) do
        local book = tes3.getObject(book_id)
        if book then
            self:add_book_progress(book_id)
        end
    end
end


---@param bonus_params herbert.HLP.Knowledge_Bonus.new_params
---@return herbert.HLP.Knowledge_Bonus bonus that was registered (after instantiating it if applicable)
function KM:register_knowledge_bonus(bonus_params)
    local bonus
    if Herbert_Class.is_instance_of(bonus_params, Knowledge_Bonus) then
        log:trace("bonus_params = %s was an instance of Knowledge_Bonus", bonus_params)
        bonus = bonus_params
    else
        log:trace("bonus_params = %s was not an instance of Knowledge_Bonus, instantiating it", bonus_params)
        bonus = Knowledge_Bonus.new(bonus_params)
    end
    log("registering bonus %s", bonus)
    self.knowledge_bonuses_by_id[bonus.id] = bonus
    return bonus
end

-- get all the knowledge bonuses for a given skill id, or for a given list of skill ids
---@param skill_id tes3.skill|tes3.skill[]
---@param sort boolean|nil|(fun(a: herbert.HLP.Knowledge_Bonus, b: herbert.HLP.Knowledge_Bonus): boolean) should we sort it?
---@return herbert.HLP.Knowledge_Bonus[]
function KM:get_skill_knowledge_bonuses(skill_id, sort)
    local arr = tbl_ext.new()
    -- do the easy case first
    if type(skill_id) == "number" then
        for _, kb in pairs(self.knowledge_bonuses_by_id) do
            if table.find(kb.skill_ids, skill_id) then
                arr:insert(kb)
            end
        end
        return tbl_ext.sorted(arr)
    end

    local skill_ids = hlib.math.Set.new(skill_id)
    for _, kb in pairs(self.knowledge_bonuses_by_id) do
        for _, id in ipairs(kb.skill_ids) do
            if skill_ids:contains(id) then
                arr:insert(kb)
            end
        end
    end
    if sort then
        return sort == true and tbl_ext.sorted(arr) 
            or tbl_ext.sorted(arr, sort)
    end
    return arr
end


-- get all of the books we've read for a given skill id
---@param skill_id tes3.skill
---@param sort boolean|nil|(fun(a: tes3book, b: tes3book): boolean) should we sort it?
---@return tes3book[] books 
function KM:get_books_read(skill_id, sort)
    local arr = {}
    for book_id, progress in pairs(self.player_data.book_prog) do
        if skill_books[book_id] == skill_id and progress > 0 then
            local book = tes3.getObject(book_id)
            if book then
                table.insert(arr, book)
            end
        end
    end
    if sort then
        if sort == true then 
            sort = function(a,b) return a.name < b.name end
        end

        return tbl_ext.sorted(arr, sort)
    end
    return arr
end

---@class herbert.HLP.study_book.params
---@field book tes3book
---@field show_msg boolean?
---@field skill_id tes3.skill
---@field fade_to_black number|boolean? should the game fade to black after reading? if not provided, config value will be used.
---@field study_pass_time number|boolean? how many in-game hours should pass when reading this book? if not provided, config value will be used.
---@field play_sound boolean? should the game play a sound when studying this book? if not provided, config value will be used

---@param p herbert.HLP.study_book.params
function KM:study_book(p)
    local book_id = p.book.id
    
    local skill_id = p.skill_id or common.get_skill_id(p.book)
    if not skill_id then return end

    if cfg.blk_until_lvled and self.player_data.read_at_lvl[book_id] then
        if p.show_msg then
            tes3.messageBox("You need to level up this skill before you can study this book.") 
        end
        return
    end

    local new_progress = self:add_book_progress(book_id)
    if not new_progress then return end

    if new_progress == 0 then
        if p.show_msg then
            tes3.messageBox("There is nothing you can learn from this book.") 
        end
        return
    end

    local mp = tes3.mobilePlayer
    local xp_requirement = math.floor(mp:getSkillProgressRequirement(skill_id))

    local xp_award = common.calc_xp_award(p.book, skill_id, xp_requirement, new_progress)
    local xp_pct = math.floor(100 * xp_award / xp_requirement)
    if xp_award > 0 then
        mp:exerciseSkill(skill_id, xp_award)
    end

    self.player_data.read_at_lvl[book_id] = mp.skills[1+skill_id].base
    self:update_progress_limits()
    if p.show_msg then
        local skill_name = tes3.getSkillName(skill_id)
        if xp_pct > 0 then
            tes3.messageBox("You earned %i%% XP in %s.", xp_pct, skill_name)
        end
        
        local improved_bonuses = tbl_ext.new{} ---@type herbert.HLP.Knowledge_Bonus[]|herbert.Extended_Table
        local old_knowledge = self:get_skill_knowledge(skill_id) - new_progress
        for _, kb in pairs(self:get_skill_knowledge_bonuses(skill_id)) do
            local diff = math.round(kb:get_bonus(skill_id) - kb.calculate_bonus(old_knowledge, skill_id), 1)
            if diff >= 1 then
                table.insert(improved_bonuses, kb)
            end
        end

        local num_improvements = #improved_bonuses
        if num_improvements > 0 then
            if num_improvements > 3 then
                tes3.messageBox("Your proficiency in %s has increased", skill_name)
            elseif num_improvements == 1 then
                tes3.messageBox("Your proficiency in %s has increased\n%s", skill_name,
                    improved_bonuses[1]:get_display_string(skill_id)
                )
            else -- `1 < num_improvements <= 3`
                tes3.messageBox("Your proficiency in %s has increased\n%s", skill_name,
                    table.concat(improved_bonuses:map(function (v) return v:get_display_string(skill_id) end), "\n")
                )
                
            end
        end
    end

    if p.play_sound ~= false then
        tes3.playSound{reference = tes3.player, sound = "skillraise"}
    end

    common.fade_to_black(p.fade_to_black, p.study_pass_time)
end

local km = KM.new() -- make an instance and return the instance

return km