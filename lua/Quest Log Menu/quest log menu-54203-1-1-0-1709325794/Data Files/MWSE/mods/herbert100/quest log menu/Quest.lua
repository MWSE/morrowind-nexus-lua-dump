---@diagnostic disable: redundant-return-value
local log = Herbert_Logger.new()

local fzy = require("herbert100.quest log menu.fzy_lua")
local get_text = require("herbert100.quest log menu.common").get_text
-- takes in the `id` of a `tes3dialogueInfo`, spits out its text.
-- this comes with a very noticeable performance boost since reading the text is quite slow
-- but it's not worth saving everything in player data since that could blow up save sizes, 
-- and it's not a huge deal to load it once each time the game launches

---@class herbert.QLM.Quest : herbert.Class
---@field new fun(q: tes3quest): herbert.QLM.Quest
---@field is_finished boolean
---@field name string
---@field faction tes3faction?
---@field actor_names string[]
---@field cells tes3cell[] cell the quest is currently in 
---@field dialogues tes3dialogue[]
---@field quest tes3quest
---@field hidden boolean?
---@field search_str string
---@field info tes3dialogueInfo[]
---@field texts string[]
---@field topics string[]
local Quest = Herbert_Class.new{
    fields={ 
        -- finished quests show up earlier
        {"is_finished", eq=true, comp=function (v) return v and 1 or 0 end},
        {"hidden", eq=true, comp=function (v) return v and 1 or 0 end},

        {"name", eq=true, comp=true},
        {"quest" },

        {"search_str"},

        -- {"dialogue", tostring=function(d) return string.format("id=%q, source=%q", d.id, d.sourceMod) end, eq=function (v) return v.id end},
        {"dialogues",
            tostring=function(d) 
                return Herbert_Class_utils.premade.array_tostring(table.map(d, function(_, v) return v.id end))
            end, 
        },

        {"info", tostring=false, factory=function(self)
            local infos = {}
            for _, dialogue in ipairs(self.dialogues) do
                for _, info in ipairs(dialogue.info) do
                    if info.firstHeardFrom then
                        table.insert(infos, info)
                    end
                end
            end
            return infos
        end},
        {"actor_names", tostring=Herbert_Class_utils.premade.array_tostring},
        {"cells", tostring=Herbert_Class_utils.premade.array_tostring},
        {"topics", tostring=Herbert_Class_utils.premade.array_tostring},
    },

    ---@param quest tes3quest
    new_obj_func=function(quest)
        for _, dialogue in ipairs(quest.dialogue) do
            if dialogue.type == tes3.dialogueType.journal and dialogue.journalIndex and dialogue.journalIndex > 0 then
                for _, info in ipairs(dialogue.info) do
                    if info.isQuestName then
                        log:trace("found quest name! making new quest: %q", get_text, info)
                        return {quest=quest, name=get_text(info)}
                    end
                end
            end
        end
    end,
    ---@param self herbert.QLM.Quest
    init=function (self)
        self.dialogues = self.quest.dialogue
        self.is_finished = self:check_is_finished()
        if rawget(self, "hidden") == nil then
            self.hidden = tes3.player.data.herbert_QL.hidden_ids[self.quest.id]
        end
        if self.hidden then
            self.name = self.name .. " (hidden)"
        end
    end,
}


-- load the stored infos and properly intialize the object.
-- this involves reading a few files and can be a bit slow, so it's not done automatically
-- although, caching is used so that each line of text only needs to be loaded once
function Quest:load_data()
    self.is_finished = self:check_is_finished()

    self.texts = {}
    local topics = {}
    self.topics = topics
    local function replace(m)
        table.insert(topics, m)
        return m
    end
    local name, faction ---@type string, tes3faction

    local player_name = '"' .. tes3.player.object.name .. '"'

    ---@type string[], string[],tes3cell[]
    local actors, actor_names, cells = {}, {}, {}
    -- local is_finished = false
    for _, info in ipairs(self.info) do
        -- if info.isQuestName then goto next_info end

        -- if it's not a quest name, and we didn't hear it from someone, go to the next one
        faction = info.npcFaction or info.firstHeardFrom and info.firstHeardFrom.faction or faction
        
        table.insert(actors, info.firstHeardFrom)
        table.insert(actors, info.actor)

        local text = get_text(info):gsub("@([%w\'\"%- ]+)#", replace):gsub("%%PCName", player_name)
        if faction then
            local rank_name = faction:getRankName(faction.playerRank)
            text = text:gsub("%%PCRank", rank_name)
        end

        if not name and info.isQuestName then
            name = text
        end
        table.insert(self.texts, text) 
    end
    for _, actor in ipairs(actors) do
        -- tes3.worldController.quests[1].
        local ref = tes3.getReference(actor.id:lower())
        if ref then
            local cell = ref.cell

            table.insert(cells, cell)
            table.insert(actor_names, ref.object.name)
            
        end
    end
    self.faction = faction
    self.cells = cells ---@type tes3cell[]
    self.actor_names = actor_names

    -- generate `search_str`
    local tbl = {}
    local added_values = {}
    local function try_to_insert(v)
        if not v or added_values[v] then return end
        added_values[v] = true
        table.insert(tbl, v)
    end

    try_to_insert(faction and faction.name)
    -- for _, t in ipairs{{self.name, faction and faction.name}, actor_names, cell_names, region_names} do
    for i, cell in ipairs(cells) do
        try_to_insert(actor_names[i])
        try_to_insert(cell.displayName)
        try_to_insert(cell.region and cell.region.name)
    end
    self.search_str = table.concat(tbl, " ")
    -- self.search_str_title = self.search_str:gsub( "(%a)([%w_']*)", function(a,b) return a:upper() .. b end)

    -- log("text size = %s", #self.texts)
end

function Quest:get_indices()
    ---@param d tes3dialogue
    return table.map(self.dialogues, function(_, d) return d.journalIndex end)
end

function Quest:get_sources()
    ---@param d tes3dialogue
    return table.map(self.dialogues, function(_, d) return d.sourceMod end)
end

function Quest:get_quest_ids()
    ---@param d tes3dialogue
    return table.map(self.dialogues, function(_, d) return d.id end)
end


function Quest:get_topic_texts()
    local topics_set  = {}
    for _, v in ipairs(self.topics) do
        topics_set[v] = true
    end
    local info_by_topic = {}
    local text
    local player_name = '"' .. tes3.player.object.name .. '"'
    local rank_name = self.faction and self.faction:getRankName(self.faction.playerRank)
    for _, d in ipairs(tes3.mobilePlayer.dialogueList) do
        if topics_set[d.id] then
            info_by_topic[d.id] = {}
            for _, info in ipairs(d.info) do
                if info.firstHeardFrom then

                    text = get_text(info)


                    -- local sub_topics = {}
                    -- text = text:gsub("@([%w\'\"%- ]+)#", function(m)
                    --     table.insert(sub_topics, m)
                    --     return m
                    -- end):gsub("%%PCName", player_name)
                    -- table.insert(info_by_topic[d.id], {info.firstHeardFrom.name, text, sub_topics})

                    text = text:gsub("@([%w\'\"%- ]+)#", "%1"):gsub("%%PCName", player_name)
                    if rank_name then
                        text = text:gsub("%%PCRank", rank_name)
                    end
                    table.insert(info_by_topic[d.id], {info.firstHeardFrom.name, text})
                    table.sort(info_by_topic[d.id], function (a, b)
                        return a[1] < b[1]
                    end)
                    -- log("found text for topic %q: %q", d.id, text)
                end
            end
        end
    end
    return info_by_topic
end
local str_find = string.find

---@param text string to search for
---@param lower boolean is `text` all lowercase?
---@return boolean matched
function Quest:search_name(text, lower)
    return fzy.has_match(text, self.name, not lower)
end

---@param text string to search for
---@param lower boolean is `text` all lowercase?
---@return boolean matched
function Quest:search(text, all_fzy, texts_too, lower)
    -- only case sensitive if `text` has suppercase letters
    if fzy.has_match(text, self.search_str, not lower) then 
        return true
    end
    if all_fzy then
        for _, cell in ipairs(self.cells) do
            if fzy.has_match(text, cell.displayName, not lower) then 
                return true
            end
        end
        return fzy.filter(text, self.topics, not lower)[1] ~= nil
            or texts_too and fzy.filter(text, self.texts, not lower)[1] ~= nil
    end

    -- lol
    if lower then
        for _, cell in ipairs(self.cells) do
            if str_find(cell.displayName:lower(), text, 1, true) then 
                return true
            end
        end
        for _, topic in ipairs(self.topics) do
            if str_find(topic:lower(), text, 1, true) then 
                return true
            end
        end
        if texts_too then
            -- log("searching quest texts of %q", self.name)
            for _, q_text in ipairs(self.texts) do
                if str_find(q_text:lower(), text, 1, true) then 
                    return true
                end
            end
        end
    else
        for _, cell in ipairs(self.cells) do
            if str_find(cell.displayName, text, 1, true) then 
                return true
            end
        end
        for _, topic in ipairs(self.topics) do
            if str_find(topic, text, 1, true) then 
                return true
            end
        end
        if texts_too then
            -- log("searching quest texts of %q", self.name)
            for _, q_text in ipairs(self.texts) do
                if str_find(q_text, text, 1, true) then 
                    return true
                end
            end
        end
    end

    return false
end


---@param other herbert.QLM.Quest
function Quest:combine(other)
    for _, other_dialogue in ipairs(other.dialogues) do
        table.insert(self.dialogues, other_dialogue)
    end
    for _, other_info in ipairs(other.info) do
        table.insert(self.info, other_info)
    end
    table.sort(self.info, function (a, b)
        if a.journalIndex ~= b.journalIndex then
            return a.journalIndex < b.journalIndex
        end
        return a.id < b.id
    end)
end

function Quest:check_is_finished()
    for _, dialogue in ipairs(self.dialogues) do
        -- for _, info in ipairs(dialogue.info) do
        --     if info.firstHeardFrom and info.isQuestFinished then
        --         return true
        --     end
        -- end
        local journal_info = dialogue:getJournalInfo()
        if journal_info and journal_info.isQuestFinished then
            return true
        end
    end
    return false
end

---@param other herbert.QLM.Quest
function Quest:should_combine(other) return self.name == other.name end
return Quest