local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local log = hlib.Logger.new()

local cfg = hlib.get_mod_config() ---@type herbert.QLM.config
local quest_list_cfg = cfg.quest_list

local Quest = hlib.import("quest") ---@type herbert.QLM.Quest
local Fzy_Matcher =  hlib.import("Fzy_Matcher") ---@type herbert.QLM.Fzy_Matcher

local register_event = event.register

---@class herbert.QLM.Quest_List
---@field quests herbert.QLM.Quest[]|herbert.Extended_Table
local Quest_List = {
    quests = tbl_ext.new(),
    outdated = true
}

setmetatable(Quest_List, {
    __index=function(self, key) return self.quests[key] end,
    __pairs = function(self) return ipairs(self.quests) end,
    __ipairs = function(self) return ipairs(self.quests) end,
    __len = function(self) return #self.quests end,
})

---@class herbert.QLM.player_data
---@field hidden_ids table<string, boolean>
---@field active_id string?
local default_player_data = {
    hidden_ids = {},
    active_id = nil
}

local player_data ---@type herbert.QLM.player_data?


register_event("loaded", function()
    player_data = hlib.load_player_data("herbert_QL", default_player_data)
    log("updated player data to %s", json.encode, player_data)
end)

if tes3.player then
    player_data = hlib.load_player_data("herbert_QL", default_player_data)
end

-- Checks if a quest was already finished.
-- This would maybe be best done in the `Quest.lua` file itself, but doing it 
-- here makes it easier to filter out quests before getting their name
-- This helps to cut down on disk operations, since getting a quest name
-- requires some I/O stuff.
---@param quest tes3quest
---@return boolean
function Quest_List.is_tes3quest_finished(quest)
    for _, dialogue in ipairs(quest.dialogue) do
        local info = dialogue:getJournalInfo()
        if info and info.isQuestFinished then return true end
    end
    return false
end

function Quest_List.remake_quests()
    -- actor_cell_map = {}

    local include_finished = quest_list_cfg.show_completed
    local include_hidden = quest_list_cfg.show_hidden

    log("updating quests....\n\tinclude_finished = %s\n\tinclude_hidden=%s", include_finished, include_hidden)
    local quests = tbl_ext.new() ---@type herbert.QLM.Quest[]|herbert.Extended_Table
    local hidden_ids = {}
    if player_data then
        hidden_ids = player_data.hidden_ids
    else
        log:warn("could not find hidden ids when making a quest list.")
    end
    for _, q in ipairs(tes3.worldController.quests) do
        local quest, is_hidden, is_finished
        -- let's check if it's hidden or completed before getting its name
        is_hidden = hidden_ids[q.id] or false
        if is_hidden and not include_hidden then goto next_quest end

        is_finished = Quest_List.is_tes3quest_finished(q)
        if is_finished and not include_finished then goto next_quest end

        quest = Quest.new(q)
        if not quest then goto next_quest end

        log:trace("made quest %q", quest.name)
        quest.is_hidden = is_hidden
        quest.is_finished = is_finished
        table.insert(quests, quest)

        ::next_quest::
    end
    log("made %s quests.", #quests)

    -- load everything right now, if we have to
    if not cfg.lazy_loading then
        for _, quest in ipairs(quests) do
            quest:load_quest_progress()
        end
    end

    quests:sort()
    
    Quest_List.quests = quests
    Quest_List.outdated = false
end

function Quest_List.clear()
    Quest_List.quests = tbl_ext.new()
    Quest_List.outdated = true
end


---@param quest herbert.QLM.Quest
function Quest_List.toggle_hidden_flag(quest)
    if not player_data then 
        log:warn("tried to hide a quest, but `player_data` wasn't loaded.")
        return 
    end
    local quest_id = quest.quest.id

    local is_hidden = not player_data.hidden_ids[quest_id]
    quest.is_hidden = is_hidden

    player_data.hidden_ids[quest_id] = is_hidden or nil
end

---@return integer? index
function Quest_List.get_active_quest_index()
    if not player_data then return end
    local id = player_data.active_id
    if not id then return end

    -- log("searching for %q")
    for i, q in ipairs(Quest_List.quests) do
        if id == q.quest.id then
            return i
        end
    end
end

---@param quest herbert.QLM.Quest
function Quest_List.set_active_quest(quest)
    if not quest then return end
    player_data.active_id = quest.quest.id
end

-- Queue a remake whenever the journal is updated or a save is loaded
register_event(tes3.event.journal, Quest_List.clear)
register_event(tes3.event.load, Quest_List.clear)

--- Filters the quests, by searching for a certain text pattern
---@param needle string the text to search for.
---@return integer[] scores a list of booleans corresponding to `Quest_List.quests`. `true` means it passed the filter.
-- `false` means it failed.
function Quest_List.score_quests(needle)

    -- only do a case sensitive search if we found an upperase letter
    local case_sensitive = needle:find("%u") ~= nil
    -- log("doing case sensitive search? %s", case_sensitive)

    local word_matchers

    if cfg.search.keywords then
        -- split the needle into words, and then send each of those into a constructor
        word_matchers = tbl_ext.map(needle:split(), Fzy_Matcher.new, case_sensitive)
    else
        word_matchers = { Fzy_Matcher.new(needle, case_sensitive) }
    end
    
    local scores = {}

    local MAX_SCORE = Fzy_Matcher.MAX_SCORE
    local MIN_SCORE = Fzy_Matcher.MIN_SCORE

    local fzy_confidence = cfg.search.fzy_confidence

    local score_to_beat
    for i, quest in ipairs(Quest_List.quests) do
        local worst_score = MAX_SCORE
        local score
        -- we take the minimum over each keyword
        -- (basically so that each keyword has to match)
        for _, matcher in ipairs(word_matchers) do
            score = quest:score(matcher)
            if score < worst_score then
                score_to_beat = fzy_confidence * (matcher.needle_len - 0.3)
                -- give up if the score sucks too hard
                if score < score_to_beat then
                    worst_score = MIN_SCORE
                    break
                end
                worst_score = score
            end
        end
        log:trace("%q has score = %s", quest.name, worst_score)
        scores[i] = worst_score
    end


    return scores
end

-- Quest_List.score_quests  = hlib.timeit(Quest_List.score_quests, "Quest_List.score_quests")
-- Quest_List.remake_quests  = hlib.timeit(Quest_List.remake_quests, "Quest_List.remake_quests")
-- Quest_List.new  = hlib.timeit(Quest_List.new, "Quest_List.new")


return Quest_List
