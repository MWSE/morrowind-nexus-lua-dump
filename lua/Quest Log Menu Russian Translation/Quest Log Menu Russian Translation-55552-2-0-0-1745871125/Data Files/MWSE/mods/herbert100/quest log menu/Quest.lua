local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
---@diagnostic disable: redundant-return-value
local log = Herbert_Logger()

---@type herbert.QLM.common
local common = hlib.import("common") 
---@cast common herbert.QLM.common

local get_text =  common.get_text
local substitute_info_text = common.substitute_info_text

local TOPIC_PATTERN = "@([^#]+)#"

local Location_Data = hlib.import("location_data") ---@type herbert.QLM.Location_Data

local cfg = hlib.get_mod_config() ---@type herbert.QLM.config

local MIN_SCORE = hlib.import("Fzy_Matcher").MIN_SCORE ---@type number

      
-- takes in the `id` of a `tes3dialogueInfo`, spits out its text.
-- this comes with a very noticeable performance boost since reading the text is quite slow
-- but it's not worth saving everything in player data since that could blow up save sizes, 
-- and it's not a huge deal to load it once each time the game launches

--[[ a chunk of a quest progress `text`. indices are as follows:
1. `string`: a chunk of `text`
2. `boolean`: does this chunk represent a journal topic?
These are used as follows:
- The text of a quest topic is broken up into these tokens.
- Then those tokens are glued back together when rendering the `Quest Progress` section.
- If `token[2] == true`, then the chunk of text in `token[1]` will be rendered as a clickable button.
    - Clicking this button will hide the dialogue in the "More Information" section.

]]
---@alias herbert.QLM.quest_progress_token {[1]: string, [2]: integer}

---@param quest tes3quest
local function get_quest_name(quest)

    for _, dialogue in ipairs(quest.dialogue) do
        if dialogue.journalIndex and dialogue.journalIndex > 0 then
            -- if dialogue.type == tes3.dialogueType.journal and dialogue.journalIndex and dialogue.journalIndex > 0 then
            for _, info in ipairs(dialogue.info) do
                if info.isQuestName then
                    return get_text(info)
                end
            end
        end
    end
    return false
end

---@class herbert.QLM.Quest
---@field is_hidden boolean? Is this quest hidden?
---@field is_finished boolean
---@field name string
---@field quest tes3quest
---@field infos tes3dialogueInfo[]|herbert.Extended_Table A list of dialogue info for this quest. Only stores info currently known by the player.
---@field actor_names string[]
---@field location_datas herbert.QLM.Location_Data[]|herbert.Extended_Table
---@field quest_progress_strs string[]
---@field quest_progress_tokens herbert.QLM.quest_progress_token[][] a list of texts, where each text has been broken up into sequence chunks
---@field protected topic_indices table<string, integer>
-- so that the topics are easily recoverable from the texts.
---@field topics string[]
local Quest = {}

---@type metatable
local Quest_meta = {
    ---@param t1 herbert.QLM.Quest  
    ---@param t2 herbert.QLM.Quest  
    __lt = function (t1, t2)
        if t1.is_hidden ~= t2.is_hidden then
            return t2.is_hidden
        end
        if t1.is_finished ~= t2.is_finished then
            return t2.is_finished
        end
        return t1.name < t2.name
    end,
    __index = Quest,
    __tostring=function (self) ---@param self herbert.QLM.Quest
        return string.format(
            'QLM:Quest(name="%s", is_hidden=%s, is_finished=%s, quest="%s", \z
                dialogues=%s, \z
                infos=[%s]\z
            )',
            self.name, self.is_hidden, self.is_finished, self.quest.id, 
            json.encode(table.map(self.quest.dialogue, function(_, v) return v.id end)),
            self.infos:map(function(info)
                return string.format(
                    '{id="%s", journalIndex=%s, heardFrom="%s"}', 
                    info.id, info.journalIndex, info.firstHeardFrom
                )
            end):concat(", ")
        )
    end
}

---@param quest herbert.QLM.Quest
local function make_quest_progress_strs_meta(quest)
    local meta = {
        -- tried to fetch something before it loaded?
        -- load it and then return that
        __index = function (progress_tokens, i)
            Quest.load_quest_progress(quest, i)
            return rawget(progress_tokens, i)
        end,
        -- make it so you can iterate before the progress is loaded
        -- this will lazy load progress during iteration
        -- one consequence of this is that it means a search
        -- can complete early without loading all the text
        __pairs = function(tbl)
            local num_infos = #quest.infos
            return
                function(progress_tokens, index)
                    index = index + 1
                    if index > num_infos then return end
                    return index, progress_tokens[index]
                end,
                tbl,
                0
        end
    }
    meta.__ipairs = meta.__pairs
    return meta
end

---@param quest herbert.QLM.Quest
local function make_topics_meta(quest)
    local meta = {
        -- make it so you can iterate before the progress is loaded
        -- this will lazy load progress during iteration
        -- one consequence of this is that it means a search
        -- can complete early without loading all the text
        -- this one is more complicated because topics don't correspond exactly with the infos
        -- so, we just keep loading infos until the index is high enough
        __pairs = function(tbl)
            local num_infos = #quest.infos
            return
                function(topics, index)
                    index = index + 1
                    local val = topics[index]
                    while val == nil and #quest.quest_progress_strs < num_infos do
                        Quest.load_quest_progress(quest, #quest.quest_progress_strs + 1)
                        val = topics[index]
                    end
                    if val == nil then return end
                    return index, val
                end,
                tbl, -- table to iterate
                0 -- initial index
        end
    }
    -- make the iteration work with ipairs too
    meta.__ipairs = meta.__pairs
    return meta
end

-- make_quest_progress_strs_meta(Quest)
-- make_topics_meta(Quest)

---@param quest tes3quest
---@return herbert.QLM.Quest?
function Quest.new(quest)
    local name = get_quest_name(quest)
    if not name then return end

    local actor_names = tbl_ext.new()
    local location_datas = tbl_ext.new()
    local infos = tbl_ext.new()

    local i = 0
    for _, dialogue in ipairs(quest.dialogue) do
        for _, info in ipairs(dialogue.info) do
            local actor = info.firstHeardFrom
            if actor then
                i = i + 1
                actor_names[i] = actor.name
                location_datas[i] = common.get_actor_location_data(actor)
                infos[i] = info
            end
        end
    end

    local self = {
        name = name,
        quest = quest,
        infos = infos,
        dialogues = quest.dialogue,
        location_datas = location_datas,
        topics = {},
        actor_names = actor_names,
        topic_indices = {},
        quest_progress_tokens = {},
    }
    setmetatable(self, Quest_meta)
    -- need the `self` reference before we can make the metatables
    self.quest_progress_strs = setmetatable({}, make_quest_progress_strs_meta(self))
    self.topics = setmetatable({}, make_topics_meta(self))


    return self
end

function Quest:get_display_name()
    local suffix = self.is_hidden and " (hidden)" or self.is_finished and " (completed)"
    return suffix and (self.name .. suffix) or self.name
end

-- load the stored infos and properly intialize the object.
-- this involves reading a few files and can be a bit slow, so it's not done automatically
-- although, caching is used so that each line of text only needs to be loaded once
-- lazy load quest progres
---@param self herbert.QLM.Quest
---@param index integer? Load progress up to this index. Default: load all progress
function Quest:load_quest_progress(index)
    if index then
        if index > #self.infos then return end
    else
        index = #self.infos
    end
    local num_loaded = #self.quest_progress_tokens
    if index < num_loaded + 1 then return end
    -- if index > #self.infos then return end

    -- keeps track of the index of a topic
    -- this is so we only insert the `topic` once, but keep track of which topic it is in the token list
    -- this will be equal to `table.invert(self.tokens)`, but it's being built
    -- in real time so that it also acts as a set
    -- and so that we can use it when constructing `quest_progress_tokens[i]`
    
    local topic_indices = self.topic_indices
    local quest_topics = self.topics

    for i = num_loaded + 1, index do
       
        
        -- build the progress string and progress token list for this info
        -- local text = get_text(info)
        
        local info = self.infos[i]

        
        local progress_strs_builder = tbl_ext.new{}
        local token_list = tbl_ext.new()

        
        local j = 0 -- index of the current token
        local text = substitute_info_text(info)
        local next_start = 1
        local s, e, topic = text:find(TOPIC_PATTERN, next_start) ---@cast topic string?

        
        while topic do 
            -- log:trace("found %q in %q", w, text)

            local before_topic = text:sub(next_start, s - 1)

            if before_topic:len() > 0 then
                -- table.insert(token_list, {before_topic, -1})
                -- progress_strs:insert(before_topic)
                j = j + 1
                token_list[j] = {before_topic, -1}
                progress_strs_builder[j] = before_topic
            end

            local topic_index = topic_indices[topic]
            if not topic_index then
                topic_index = #quest_topics + 1

                quest_topics[topic_index] = topic
                topic_indices[topic] = topic_index
            end
            j = j + 1
            token_list[j] = {topic, topic_index}
            progress_strs_builder[j] = topic
            next_start = e + 1
            s, e, topic = text:find(TOPIC_PATTERN, next_start)
        end

        if next_start < text:len() then
            local rest_of_text = text:sub(next_start)
            j = j + 1
            token_list[j] = {rest_of_text, -1}
            progress_strs_builder[j] = rest_of_text
        end

        self.quest_progress_strs[i] = progress_strs_builder:concat()
        self.quest_progress_tokens[i] = token_list
    end
end



function Quest:load_topics()
    if true then return end
    local quest_topics = tbl_ext.new()
    self.topics = quest_topics
    
    -- build the progress string and progress token list for this info
    for _, info in ipairs(self.infos) do
        local text = get_text(info)
        for topic in text:gmatch(TOPIC_PATTERN) do

            local topic_text = substitute_info_text(info, topic)
            table.insert(quest_topics, topic_text)
        end
    end
end



---@return table<string, tes3dialogue>
function Quest:get_topic_dialogues()
    self:load_quest_progress()
    local topics_set  = hlib.math.Set(self.topics)
    log:trace("loading topic dialogues for \"%s\"\n\ttopics = %s", self.name, topics_set)
    local dialogues_by_topic = {} ---@type table<string, tes3dialogue>

    for _, dialogue in ipairs(tes3.mobilePlayer.dialogueList) do
        -- only insert a topic if we've progressed far enough in the quest to have seen the topic
        -- and if we've heard at least one info in the dialogue from somebody
        if topics_set:contains(dialogue.id) then
            for _, info in ipairs(dialogue.info) do
                if info.firstHeardFrom then
                    dialogues_by_topic[dialogue.id] = dialogue
                    break
                end
            end
        end
    end
    log:trace("\tloaded topics = %s", function ()
        return json.encode(tbl_ext.keys(dialogues_by_topic))
    end)
    return dialogues_by_topic
end

function Quest:load_tokens()
    self:load_quest_progress()
end

---@param dialogue tes3dialogue
---@return {[1]: tes3actor|tes3npc, [2]: string}[]
function Quest:load_topic_dialogue(dialogue)

    local by_topic = {}
    for _, info in ipairs(dialogue.info) do
        if info.firstHeardFrom then
            local text = substitute_info_text(info):gsub(TOPIC_PATTERN, "%1")

            table.insert(by_topic, {info.firstHeardFrom, text})
        end
    end
    table.sort(by_topic, function (a, b) return a[1].name < b[1].name end)
    return by_topic
end

local sw = cfg.search.weights


---@param matcher herbert.QLM.Fzy_Matcher
---@return integer score
function Quest:score(matcher)

    local name_score = MIN_SCORE
    local actor_names_score = MIN_SCORE
    local loc_score = MIN_SCORE
    local region_score = MIN_SCORE
    local topics_score = MIN_SCORE
    local progress_score = MIN_SCORE

    if sw.quest_name > 0 then
        name_score = sw.quest_name * matcher:score(self.name)
    end

    if sw.actor_names > 0 then
        actor_names_score = sw.actor_names * matcher:get_highest_score(self.actor_names)
    end

    if sw.location_data > 0 then
        local location_names = self.location_datas:map(Location_Data.format_as_address)
        loc_score = sw.location_data * matcher:get_highest_score(location_names)
    end
    if sw.region_names > 0 then
        local highest = MIN_SCORE
        for _, loc_data in ipairs(self.location_datas) do
            local ext = loc_data.path[#loc_data.path]
            if ext and ext.region then
                local score = matcher:score(ext.region.name)
                if score > highest then
                    highest = score
                end
            end
        end

        region_score = sw.region_names * highest
    end

    if sw.topics > 0 then
        topics_score = sw.topics * matcher:get_highest_score(self.topics)
    end

    if sw.quest_progress > 0 then
        progress_score = sw.quest_progress * matcher:get_highest_score(self.quest_progress_strs)
    end

    -- final score is the maximum, taking over all fields
    return math.max(
        name_score,
        actor_names_score,
        loc_score,
        region_score,
        topics_score,
        progress_score
    )

end


return Quest