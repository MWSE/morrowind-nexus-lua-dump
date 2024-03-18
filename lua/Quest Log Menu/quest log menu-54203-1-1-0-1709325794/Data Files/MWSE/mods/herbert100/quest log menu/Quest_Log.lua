

-- local fzy = require("fzy")
local log = Herbert_Logger.new()
local cfg = require("herbert100.quest log menu.config")
local Quest = require("herbert100.quest log menu.Quest")


---@class herbert.QLM.Quest_Log : herbert.Class
---@field quests herbert.QLM.Quest[]
---@field index integer
---@field search_bar tes3uiElement
---@field search_timer mwseTimer
---@field quest_list_blk tes3uiElement
---@field ui_base tes3uiElement
local Quest_Log = Herbert_Class.new{
	fields = {
        {"quests", tostring=Herbert_Class_utils.premade.array_tostring},
        {"index", default=0},
        {"quest_list_blk"},
    },
    ---@param self herbert.QLM.Quest_Log
    init=function(self)
        self.search_timer = timer.start{duration=0.1, type=timer.real, callback=function(e)
            local text = self.search_bar.text
            -- log("search timer firing on %q", text)

            if text == "Search..." then 
                self:clear_search()
            elseif #text > 1 then
                -- log("len is > 1, doing search")
                self:filter_shown_quests(self.search_bar.text)
            else
                -- log("len is <= 2, so clearing search")
                self:clear_search()
            end
        end}
        self.search_timer:cancel()
        self:update_quests()

    end,
    ---@param self herbert.QLM.Quest_Log
    post_init=function(self) 
        self:make()
        
        if not tes3.player or not tes3.player.data then return end
        -- log("player data exists")
        local id = tes3.player.data.herbert_QL_id
        if id then
            -- log("searching for %q")
            for i, q in ipairs(self.quests) do
                for _, dialogue in ipairs(q.dialogues) do
                    if dialogue.id == id then
                        -- log("found quest with id %s", q.id)
                        self:set_active_quest(i)
                        return
                    end
                end

            end
        end
        log("no id found, setting it to 1")
        self:set_active_quest()
    end,
}

local UID_strs = {
    menu = "QL:menu",
    main_menu_close_btn = "MenuOptions_Return_container",
    quest_list = "QL:quest_list",
    main_block = "QL:main_block",
    search_block = "QL:search_block",
    search_bar = "QL:search_bar",
    quest_container = "QL:quest_container",
    quest_info = "QL:quest_info",
    bottom_button_bar = "QL:bottom_button_bar",
    close_button = "QL:close_button",
    quest = "QL:quest",
}
---@type table<string, integer|string>
local UIDS = {
    menu = "QL:menu",
    main_menu_close_btn = "MenuOptions_Return_container",
    quest_list = "QL:quest_list",
    main_block = "QL:main_block",
    search_block = "QL:search_block",
    search_bar = "QL:search_bar",
    quest_container = "QL:quest_container",
    quest_info = "QL:quest_info",
    bottom_button_bar = "QL:bottom_button_bar",
    close_button = "QL:close_button",
    quest = "QL:quest",
}
Quest_Log.UIDS = UIDS

---@param e uiActivatedEventData
local function close_options_menu(e)
    local close_btn = e.element:findChild("MenuOptions_Return_container")
    if close_btn then
        close_btn:triggerEvent("mouseClick")
    end
end


function Quest_Log.close(block_next_options_menu)
    local menu = tes3ui.findMenu(UIDS.menu)
    if not menu then return end
    log("menu found")
    menu:destroy()
    local topmenu = tes3ui.getMenuOnTop()
    log("topmenu is %q", topmenu.name)
    if topmenu.name == "MenuMulti" then
        tes3ui.leaveMenuMode()
    end
    if block_next_options_menu == true then
        event.register("uiActivated", close_options_menu, {filter="MenuOptions", doOnce=true})
    end
    return false
end



function Quest_Log:make()
    local menu = tes3ui.findMenu(UIDS.menu)
	if menu then
        menu.visible = true
        self.ui_base = menu
        self.quest_list_blk = menu:findChild(UIDS.quest_list)
	    tes3ui.enterMenuMode(menu.id)
        return
    end
    -- Create the main menu frame.
    menu = tes3ui.createMenu{ id = UIDS.menu, dragFrame = true}
    self.ui_base = menu
    menu.text = "Quest List"
    menu.minWidth = 600
    menu.minHeight = 500
    menu.width = 1200
    menu.height = 800
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2

    -- Create the left-right flow.
    local main_block = menu:createBlock{ id = UIDS.main_block }
    main_block.flowDirection = "left_to_right"
    main_block.widthProportional = 1.0
    main_block.heightProportional = 1.0

    local quest_list_block = main_block:createBlock({ id = UIDS.quest_list })
    quest_list_block.flowDirection = "top_to_bottom"
    quest_list_block.width = 400
    quest_list_block.minWidth = 400
    quest_list_block.maxWidth = 400
    quest_list_block.widthProportional = -1.0
    quest_list_block.heightProportional = 1.0

    
    local search_block = quest_list_block:createThinBorder({ id = UIDS.search_block })
    search_block.widthProportional = 1.0
    search_block.autoHeight = true

    local search_bar = search_block:createTextInput{ id = UIDS.search_bar, placeholderText = "Search...", autoFocus = true}
    search_bar.borderLeft = 5
    search_bar.borderRight = 5
    search_bar.borderTop = 3
    search_bar.borderBottom = 5
    
    search_bar:registerAfter("textUpdated", function(e) 
        self.search_timer:reset()
        -- log("text updated fired on %q", e.source.text)
    end)
    search_bar:registerAfter("textCleared", function() self:clear_search() end)
    self.search_bar = search_bar

    -- Make clicking on the block focus the search input.
    search_block:register("mouseClick", function() self:focus_search_bar() end)

    -- Create the mod list.
    local quest_list = quest_list_block:createVerticalScrollPane{ id = UIDS.quest_list }
    quest_list.widthProportional = 1.0
    quest_list.heightProportional = 1.0
    -- quest_list:setPropertyBool("PartScrollPane_hide_if_unneeded", true)
    self.quest_list_blk = quest_list
    log("made quest list block. filling it....")
    self:create_quests_list()
    
    local quest_container = main_block:createBlock{ id = UIDS.quest_container }
    quest_container.flowDirection = "top_to_bottom"
    quest_container.widthProportional = 1.0
    quest_container.heightProportional = 1.0
    quest_container.paddingLeft = 4
    self.quest_container = quest_container

    local quest_info = quest_container:createThinBorder{ id = UIDS.quest_info }
    quest_info.widthProportional = 1.0
    quest_info.heightProportional = 1.0
    quest_info.paddingAllSides = 12
    quest_info.flowDirection = "top_to_bottom"


    -- Create bottom button block.
    local button_bar_blk = menu:createBlock{ id = UIDS.bottom_button_bar }

    button_bar_blk.widthProportional = 1.0
    -- button_bar_blk.heightProportional = 0.01
    button_bar_blk.childAlignY = 0.5
    button_bar_blk.autoHeight = true
    button_bar_blk.paddingTop = 3
    button_bar_blk.flowDirection = tes3.flowDirection.leftToRight
    button_bar_blk.widthProportional = 1.0
    button_bar_blk.autoHeight = true
    
    local function make_btn(text, cfg_key, callback)
        callback = callback or function() end
        local btn = button_bar_blk:createButton{text=tes3.findGMST(cfg[cfg_key] and tes3.gmst.sYes or tes3.gmst.sNo).value}
        btn.borderRight = 7.5
        btn:register(tes3.uiEvent.mouseClick, function (e)
            local src = e.source
            cfg[cfg_key] = not cfg[cfg_key]
            src.text = tes3.findGMST(cfg[cfg_key] and tes3.gmst.sYes or tes3.gmst.sNo).value
            callback()
            self:update_quests()
            self:create_quests_list()
            ---@diagnostic disable-next-line: missing-parameter
            self.search_timer.callback()
        end)
        local btn_label = button_bar_blk:createLabel{text=text}
        -- btn_label.borderRight = 12 + 15
        btn_label.borderRight = 12
        local rect = button_bar_blk:createRect{}
        rect.heightProportional = 1.5
        rect.width = 1
        rect.color = btn_label.color
        -- rect.borderRight = 10 + 15
        rect.borderRight = 10
        rect.alpha = 0.6
        return btn, btn_label, rect
    end

    
    local _, _, rect = make_btn("Show completed", "show_completed", function() self:update_quests(); self:create_quests_list() end)
    
    _, _, rect = make_btn("Show hidden", "show_hidden", function() self:update_quests(); self:create_quests_list() end)

    _, _, rect = make_btn("Search quest progress", "search_quest_text")
    -- rect
    _, _, rect = make_btn("Fuzzy search everything", "all_fzy")

    _, _, rect = make_btn("Keyword search", "keyword_search")
    rect.visible = false




    local close_button = button_bar_blk:createButton({
        id = UIDS.close_button,
        text = tes3.findGMST(tes3.gmst.sClose).value --[[@as string]]
    })
    close_button:register("mouseClick", Quest_Log.close)
    close_button.absolutePosAlignX = 1.0
    close_button.absolutePosAlignY = 0.6
    -- event.register("keyDown", onClickCloseButton, { filter = tes3.scanCode.escape })

    -- Cause the menu to refresh itself.
    menu:updateLayout()
    quest_list.widget:contentsChanged()

	tes3ui.enterMenuMode(menu.id)
end
local active_color
-- local active_color = {0.35, 0.35, 0.8}


---@param blk tes3uiElement
---@param string_pairs {[1|2]:string}[]
---@param border_between number? amount of border to put between table entries
---@return tes3uiElement tbl_blk 
local function make_ui_table(blk, string_pairs, border_between)
        local tbl_blk = blk:createBlock()
        tbl_blk.flowDirection = tes3.flowDirection.leftToRight
        tbl_blk.autoHeight = true
        tbl_blk.widthProportional = 1.0
        local left_label, right_label

        local left_col = tbl_blk:createBlock()
        left_col.autoHeight = true
        left_col.autoWidth = true
        left_col.childAlignX = 1.0
        left_col.flowDirection = tes3.flowDirection.topToBottom

        local right_col = tbl_blk:createBlock()
        right_col.autoHeight = true
        right_col.widthProportional = 1.0
        right_col.flowDirection = tes3.flowDirection.topToBottom

        for _, p in ipairs(string_pairs) do 
            -- left_label = left_col:createTextSelect{text=p[1], state=tes3.uiState.active}
            left_label = left_col:createLabel{text=p[1]}
            left_label.color = active_color
            -- left_label.alpha = 1.0
            left_label.borderRight = 6
            left_label.borderBottom = border_between or 6

            right_label = right_col:createLabel{text=p[2]}
            right_label.wrapText = true
            right_label.justifyText = tes3.justifyText.left
            right_label.widthProportional = 1.0
            right_label.borderBottom = border_between or 6
        end
        left_label.borderBottom = 0
        right_label.borderBottom = 0
        
        blk:getTopLevelMenu():updateLayout()

        for i, left_label in ipairs(left_col.children) do 
            left_label.height = right_col.children[i].height
        end

        -- blk:getTopLevelMenu():updateLayout()
    return tbl_blk
end
--- make a title header
---@param blk tes3uiElement container for the header
---@param text string text of the header
---@param border_bottom number? spacing between this and the next thing
local function make_title(blk, text, border_bottom)
    -- local title = blk:createTextSelect{text=text, state=tes3.uiState.active}
    local title = blk:createLabel{text=text}
    title.color = tes3ui.getPalette(tes3.palette.whiteColor)
    -- title.widget.idleActive = niColor.new()
    title.wrapText = true
    title.justifyText = tes3.justifyText.center
    title.borderBottom = border_bottom or 7.5
    return title
end

-- =============================================================================
-- UPDATE ACTIVE QUEST (set index)
-- =============================================================================

-- set the active quest to this index and build all the ui elements
-- this function is borderline unreadable. the implementation will hopefully be changed
-- in the future, once i find a better way to do these things. but this is just the 
-- first version
function Quest_Log:set_active_quest(index)
    if self.index == nil or index == nil then 
        index = 1
    elseif index == nil or index == self.index then
        return
    end

    local quest = self.quests[index]
    if not quest then 
        log("couldn't find quest with index %s", index)
        return 
    end


    log("setting active quest to %s", quest.name)
    
    do -- update button colors
        local content = self.quest_list_blk:getContentElement()

        if self.index ~= nil then   
            local last_elem = content.children[self.index]
            if last_elem and last_elem.widget then
                local last_quest = self.quests[self.index]
                if last_quest then
                    if last_quest.is_finished or last_quest.hidden then
                        last_elem.widget.state = tes3.uiState.disabled
                    else
                        last_elem.widget.state = tes3.uiState.normal
                    end
                end

            end
        end

        self.index = index
        content.children[self.index].widget.state = tes3.uiState.active
    end
    
    self.ui_base.text = string.format("Quest: %q", quest.name)
    local container = self.quest_container

    container:destroyChildren()

    local pane = container:getContentElement():createVerticalScrollPane()
    container.widthProportional = 1.0
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.autoHeight = true
    pane.autoWidth = true
    -- container:updateLayout()
    
    local cont = pane:getContentElement()

    ---@class herbert.QLM.make_subcontainer_params
    ---@field parent tes3uiElement? default: `cont`
    ---@field border_bottom number?
    ---@field child_align_x number?
    ---@field width_proportional number?
    ---@field border_all_sides number|false?

    ---@param p herbert.QLM.make_subcontainer_params?
    ---@return tes3uiElement subcomponent
    local function make_subcontainer(p)
        p = p or {}
        local sub = (p.parent or cont):createBlock()
        sub.widthProportional = p.width_proportional or 1.0
        sub.autoHeight = true
        sub.flowDirection = tes3.flowDirection.topToBottom
        sub.borderBottom = p.border_bottom or 2.5
        if p.child_align_x then
            sub.childAlignX = p.child_align_x
        end
        if p.border_all_sides ~= false then
            sub.borderAllSides = p.border_all_sides or 5
        end

        return sub
    end


    -- =========================================================================
    -- QUEST HEADER
    -- =========================================================================
    do
        local preamble_blk = make_subcontainer{border_bottom=5}
        -- cont:updateLayout()

        local function get_cell_name(cell)
            return cell.region and string.format("%s (%s)", cell.displayName, cell.region.name)
                or cell.displayName
        end
        -- preamble_blk:updateLayout()
        make_title(preamble_blk, quest.name, 10).borderTop = 5   
        -- preamble_blk:getTopLevelMenu():updateLayout()

        local num_actors = #quest.actor_names
        if num_actors > 0 then
            do -- make the table
                local tbl_blk = preamble_blk:createBlock()
                tbl_blk.flowDirection = tes3.flowDirection.leftToRight
                tbl_blk.autoHeight = true
                tbl_blk.widthProportional = 1.0
                local left_label, right_label

                local left_col = tbl_blk:createBlock()
                left_col.autoHeight = true
                left_col.autoWidth = true
                -- left_col.childAlignX = 1.0
                left_col.flowDirection = tes3.flowDirection.topToBottom

                local right_col = tbl_blk:createBlock()
                right_col.autoHeight = true
                right_col.widthProportional = 1.0
                right_col.flowDirection = tes3.flowDirection.topToBottom
                local actors_and_cells = {
                    {"First heard from:  ", quest.actor_names[1], get_cell_name(quest.cells[1])}
                }
                if num_actors > 1 then
                    actors_and_cells[2] = {"Last heard from:  ", quest.actor_names[num_actors], get_cell_name(quest.cells[num_actors])}
                end
                if num_actors == 1 then actors_and_cells[2] = nil end
                -- preamble_blk:updateLayout()

                for _, p in ipairs(actors_and_cells) do 
                    left_label = left_col:createLabel{text=p[1]}
                    left_label.borderLeft = 20
                    left_label.borderBottom = 5

                    local right_sub_col = right_col:createBlock()
                    right_sub_col.autoHeight = true
                    right_sub_col.widthProportional = 1.0
                    right_sub_col.flowDirection = tes3.flowDirection.topToBottom
                    right_sub_col.borderBottom = 5

                    -- right_col:updateLayout()
                    local right_row
                    local word_label
                    right_row = right_sub_col:createBlock()
                    right_row.autoHeight = true
                    right_row.autoWidth = true
                    right_row.flowDirection = tes3.flowDirection.leftToRight
                    for j, blue_text in ipairs{p[2], p[3]} do
                        -- right_label = right_row:createTextSelect{text=p[2], state=tes3.uiState.active}
                        for word in blue_text:gmatch("%S+") do
                            -- log("word = %q", word)
                            -- word_label = right_row:createTextSelect{text=word, state=tes3.uiState.active}
                            word_label = right_row:createLabel{text=word}
                            word_label.color = active_color
                            word_label.borderRight = 6
                            -- right_row:updateLayout()
                            right_col:getTopLevelMenu():updateLayout()

                            -- tbl_blk:updateLayout()
                            if right_row.width > right_col.width then
                                right_row = right_sub_col:createBlock()
                                right_row.autoHeight = true
                                right_row.autoWidth = true
                                right_row.flowDirection = tes3.flowDirection.leftToRight

                                word_label.visible = false
                                -- word_label = right_row:createTextSelect{text=word, state=tes3.uiState.active}
                                word_label = right_row:createLabel{text=word}
                                word_label.color = active_color
                                word_label.borderRight = 6
                                -- right_col:updateLayout()
                            end
                        end
                        if j == 1 then  
                            right_label = right_row:createLabel{text="in"}
                            right_label.borderRight = 6
                            right_col:getTopLevelMenu():updateLayout()

                            -- tbl_blk:updateLayout()
        
                            if right_row.width > right_col.width then
                                right_row = right_sub_col:createBlock()
                                right_row.autoHeight = true
                                right_row.autoWidth = true
                                right_row.flowDirection = tes3.flowDirection.leftToRight

                                right_label.visible = false
                                right_label = right_row:createLabel{text="in"}
                                right_label.borderRight = 6
                                -- right_col:updateLayout()
                            end
                        end
                    end
                end
                preamble_blk:getTopLevelMenu():updateLayout()
                -- cont:updateLayout()
                
                for i=1, #actors_and_cells do 
                    left_col.children[i].height = right_col.children[i].height
                end
                -- preamble_blk:getTopLevelMenu():updateLayout()
            end

        end
        cont:createDivider()
        -- cont:updateLayout()

    end
    

    -- =========================================================================
    -- QUEST PROGRESS
    -- =========================================================================
    do
        local progress_blk = make_subcontainer{width_proportional=1}
        
        -- cont:updateLayout()
        local topic_index = 1
        local topic = quest.topics[topic_index]
        
        local topic_index_offset = 0
        local row, word_label
        -- Direction = tes3.flowDirection.topToBottom

        
        make_title(progress_blk, "Quest Progress")
        progress_blk:getTopLevelMenu():updateLayout()

        for i, text in ipairs(quest.texts) do
            --TODO : SKIP THIS WHEN TOPIC IS NIL
            -- EARLY VERSION
            if not topic then
                local lbl = progress_blk:createLabel{text= string.format("%4i)  %s", i, text)}
                lbl.wrapText = true
                lbl.borderBottom = 15
                goto next_text
            end
            -- END EARLY VERSION
            local text_blk = progress_blk:createBlock()
            text_blk.widthProportional = 1.0
            text_blk.autoHeight = true
            text_blk.flowDirection = tes3.flowDirection.topToBottom
            progress_blk:updateLayout()
            row = text_blk:createBlock()
            row.autoHeight=true
            row.autoWidth=true
            row.flowDirection=tes3.flowDirection.leftToRight

            -- blk = make_left_to_right_blk(progress_blk)
            local is_first_blk = true
            
            word_label = row:createLabel{text = string.format("%4i)  ", i)}
            
            local parts = {}
            local s, e = string.find(text, topic, 1, true)
            local old_end = 1

            -- split up the string based on the topics inside it
            while s ~= nil and topic ~= nil do -- split as long as we have a match and a topic
                -- `text:sub(old_end, s - 1)` = the part of `text` between the last value of `e` and this value of `s` (not including `s` and `e`)
                table.insert(parts, text:sub(old_end, s - 1))
                old_end = e + 1
                topic_index = topic_index + 1
                topic = quest.topics[topic_index]
                if topic then
                    s, e = string.find(text, topic, old_end, true)
                end
            end
            
            table.insert(parts, text:sub(old_end))
            for j, part in ipairs(parts) do
                -- log("(%i, %i) iterating part %q", i, j, part)
                for word in part:gmatch("(%s-%S+%s-)") do
                    word_label = row:createLabel{text=word}
                    word_label.autoWidth = true
                    text_blk:updateLayout()
                    if row.width > text_blk.width then
                        is_first_blk = false
                        word_label.visible = false
                        row = text_blk:createBlock()
                        row.autoHeight=true
                        row.autoWidth=true
                        row.flowDirection=tes3.flowDirection.leftToRight
                        word_label = row:createLabel{text=word}
                    end
                end
                local topic = quest.topics[j+topic_index_offset]
                if topic and j < #parts then
                    -- check if it's the first block, and if only the numbering prefix is in it
                    if is_first_blk and #row.children == 1 then
                        -- log("%q is the first entry, so not padding", topic)
                        -- word_label = row:createTextSelect{text=topic}
                        word_label = row:createLabel{text=topic}
                        word_label.color = active_color
                    else
                        -- elem = blk:createTextSelect{text=" " .. topic}
                        -- word_label = row:createTextSelect{text=topic}
                        word_label = row:createLabel{text=topic}
                        word_label.color = active_color
                        word_label.borderLeft = 6
                    end
                    -- word_label.widget.state = tes3.uiState.active
                    -- elem.wrapText = true
                    -- t.autoHeight = true
                    word_label.autoWidth = true
                    -- blk:updateLayout()
                    text_blk:updateLayout()
                    if row.width > text_blk.width then
                        is_first_blk = false
                        word_label.visible = false
                        -- blk = make_left_to_right_blk(progress_blk)

                        row = text_blk:createBlock{}
                        row.autoHeight=true
                        row.autoWidth=true
                        row.flowDirection=tes3.flowDirection.leftToRight


                        -- word_label = blk:createTextSelect{text=" " .. topic, state=tes3.uiState.active}
                        -- word_label = row:createTextSelect{text=topic, state=tes3.uiState.active}
                        word_label = row:createLabel{text=topic}
                        word_label.color = active_color
                        word_label.borderLeft = 6

                        word_label.wrapText = true
                        word_label.autoWidth = true
                        -- blk:updateLayout()
                    end
                end
            end
            topic_index_offset = topic_index - 1
            row.borderBottom = 15
            -- row:updateLayout()
            ::next_text::
        end
        -- last one gets a bigger border
        row.borderBottom = 5
        progress_blk:getTopLevelMenu():updateLayout()

    end
    
    local div = cont:createDivider()
    div.borderBottom = 5


    

    -- =========================================================================
    -- RELEVANT INFORMATION
    -- =========================================================================
    do
        local info_by_topic = quest:get_topic_texts()


        local relevant_information = make_subcontainer()

        -- cont:updateLayout()
        
        make_title(relevant_information, "Relevant Information")

        -- cont:updateLayout()

        -- iterate each topic
        local added_topics = {}
        for _, topic_id in ipairs(quest.topics) do
            local topic_info = info_by_topic[topic_id]
            if not topic_info or next(topic_info) == nil or added_topics[topic_id] then
                goto next_id
            end
            added_topics[topic_id] = true

            local topic_container = relevant_information:createBlock()
            topic_container.paddingAllSides = 5
            topic_container.flowDirection = tes3.flowDirection.topToBottom
            topic_container.widthProportional = 1.0
            -- topic_container.heightProportional = 1.0
            topic_container.autoHeight = true
            -- topic_container.autoWidth = true

            -- local topic_name = topic_container:createTextSelect{text=topic_id}
            local topic_name = topic_container:createLabel{text=topic_id}
            topic_name.color = active_color
            -- topic_name.widget.state = tes3.uiState.active
            -- local topic_name = topic_container:createLabel{text=string.format("topic: %q", topic_id)}
            topic_name.widthProportional = 1.0
            topic_name.wrapText = true
            topic_name.justifyText = tes3.justifyText.center
            topic_name.borderBottom = 7.5

            -- topic_container:updateLayout()
            -- make_ui_table(topic_container, info_by_topic[topic_id])
            do -- make the table 
                local tbl_blk = topic_container:createBlock()
                tbl_blk.flowDirection = tes3.flowDirection.leftToRight
                tbl_blk.autoHeight = true
                tbl_blk.widthProportional = 1.0
                local left_label, right_label

                local left_col = tbl_blk:createBlock()
                left_col.autoHeight = true
                left_col.autoWidth = true
                left_col.childAlignX = 1.0
                left_col.flowDirection = tes3.flowDirection.topToBottom

                local right_col = tbl_blk:createBlock()
                right_col.autoHeight = true
                right_col.widthProportional = 1.0
                right_col.flowDirection = tes3.flowDirection.topToBottom
                for _, p in ipairs(info_by_topic[topic_id]) do 
                    -- left_label = left_col:createTextSelect{text=p[1] .. ":", state=tes3.uiState.active}
                    left_label = left_col:createLabel{text=p[1] .. ":"}
                    left_label.color = active_color
                    left_label.borderRight = 6
                    left_label.borderBottom = 6

                    right_label = right_col:createLabel{text=string.format('"%s"',p[2])}
                    right_label.wrapText = true
                    right_label.justifyText = tes3.justifyText.left
                    right_label.widthProportional = 1.0
                    right_label.borderBottom = 6

                end
                left_label.borderBottom = 0
                right_label.borderBottom = 0
                
                tbl_blk:getTopLevelMenu():updateLayout()

                for i, left_label in ipairs(left_col.children) do 
                    left_label.height = right_col.children[i].height
                end

                tbl_blk:getTopLevelMenu():updateLayout()
            end
            -- cont:updateLayout()
            ::next_id::
        end

        if next(added_topics) == nil then
            local lbl = cont:createLabel{text="You don't know anything."}
            lbl.wrapText = true
            lbl.justifyText = tes3.justifyText.center
            lbl.borderBottom = 7.5
        end
    end

    -- ======================================================================
    -- MISCELLANEOUS INFORMATION
    -- ====================================================================== 
    do
        cont:createDivider()
        local footer_blk = make_subcontainer()
        cont:updateLayout()
        make_title(footer_blk, "Miscellaneous Information")
        local ids = quest:get_quest_ids()
        local sources = quest:get_sources()
        local indices = quest:get_indices()
        local footer_info = {
            {"Faction:  ", quest.faction and string.format('"%s"', quest.faction.name) or "N/A"},
        }
        if #ids > 1 then
            footer_info[2] = {"Quest IDs:  ", table.concat(ids, ", ")}
        else
            footer_info[2] = {"Quest ID:  ", ids[1]}
        end
        if #sources > 1 then
            footer_info[3] = {"Sources:  ",table.concat(sources, ", ")}
        else
            footer_info[3] = {"Source:  ", sources[1]}
        end
        if #indices > 1 then
            footer_info[4] = {"Journal Indices:  ", table.concat(indices, ", ")}
        else
            footer_info[4] = {"Journal Index:  ", indices[1] and tostring(indices[1]) or "N/A"}
        end


        local tbl_blk = make_ui_table(footer_blk, footer_info, 5)

        -- tblk_blk.children[1].widthProportional = 1.0
        -- local offset = -0.02
        -- tblk_blk.children[1].widthProportional = 1.0 - offset
        -- tblk_blk.children[2].widthProportional = 1.0 + offset

        -- local blk
        -- for _, p in ipairs(footer_info) do
        --     blk = footer_blk:createBlock()
        --     blk.autoHeight=true
        --     blk.autoWidth=true
        --     blk.flowDirection=tes3.flowDirection.leftToRight
        --     blk.borderBottom = 2.5
        --     -- blk.absolutePosAlignX = 0.5
        --     blk.childAlignX = 0.5

        --     blk:createTextSelect{text=p[1],state=tes3.uiState.active}.autoWidth = true
        --     blk:createLabel{text=p[2]}.autoWidth = true
        --     blk:updateLayout()
        -- end
        footer_blk:getTopLevelMenu():updateLayout()

        -- cont:createDivider()
        -- local lbl2 = cont:createLabel{text=string.format("Source: %q", quest.source)}
        -- lbl2.wrapText = true
        -- lbl2.justifyText = tes3.justifyText.center
        -- -- lbl2.wrapText = true
        -- -- lbl2.autoHeight = true

        local set_hidden_btn = footer_blk:createButton{id="QL:set_hidden_btn", text="Hide Quest"}
        set_hidden_btn:register(tes3.uiEvent.mouseClick, function (e)
            local hidden_quests = tes3.player.data.herbert_QL.hidden_ids
            local is_hidden = not hidden_quests[quest.quest.id] or nil
            hidden_quests[quest.quest.id] = is_hidden
            quest.hidden = is_hidden or false
            if is_hidden then
                e.source.text = "Unhide Quest."
            else
                e.source.text = "Hide Quest."
            end
            self:update_quests()
            self:create_quests_list()
        end)
        set_hidden_btn.absolutePosAlignX = 0.5
    end
    cont:updateLayout()
    pane.widget:contentsChanged()
    pane:updateLayout()

    self.ui_base:updateLayout()
    -- self.quest_list_blk.widget:contentsChanged()
    log("setting tes3.player.data.herbert_QL_id = %q", quest.dialogues[1].id)
    tes3.player.data.herbert_QL_id = quest.dialogues[1].id
end

function Quest_Log:create_quests_list()
    local quest_list_contents = self.quest_list_blk:getContentElement()
    quest_list_contents:destroyChildren()
    
    for i, quest in ipairs(self.quests) do
        local entry = quest_list_contents:createTextSelect{id=UIDS.quest, text=quest.name}
        if quest.is_finished or quest.hidden then
            entry.widget.state = tes3.uiState.disabled
        end
    
        -- entry:register("mouseClick", function (e) self:select_quest(i) end)
        entry:register("mouseClick", function(e) self:set_active_quest(i) end)
    end
end


function Quest_Log:update_quests()
    self.quests = {}
    local include_finished = cfg.show_completed
    local include_hidden = cfg.show_hidden
    log("iterating quests")
    for _, q in ipairs(tes3.worldController.quests) do
        local quest = Quest.new(q)
        if not quest
        or quest.hidden and not include_hidden
        or quest.is_finished and not include_finished
        then goto next_quest end

        table.insert(self.quests, quest)

        ::next_quest::
    end
    
    log("made %i quests", #self.quests)
    for _, quest in ipairs(self.quests) do
        quest:load_data()
    end
    table.sort(self.quests)
    
end



function Quest_Log:clear_search()
    for _, child in pairs(self.quest_list_blk:getContentElement().children) do
        child.visible = true
    end
    self.quest_list_blk.widget:contentsChanged()
	self.ui_base:updateLayout()
end

function Quest_Log:is_valid()
    return self.ui_base ~= nil
end


function Quest_Log:focus_search_bar()
    if self.search_bar then
        tes3ui.acquireTextInput(self.search_bar)
    end
end

function Quest_Log:next_quest()
    if not self.index then
        self:set_active_quest(1)
        return
    end
    local max_index = #self.quests
    local index = self.index + 1
    local children =  self.quest_list_blk:getContentElement().children
    while index <= max_index do
        if children[index].visible then
            self:set_active_quest(index)
            return
        end
        index = index + 1
    end
end


function Quest_Log:prev_quest()
    if not self.index then
        self:set_active_quest(1)
        return
    end
    local index = self.index - 1 
    local children =  self.quest_list_blk:getContentElement().children
    while index >= 1 do
        if children[index].visible then
            self:set_active_quest(index)
            return
        end
        index = index - 1
    end
end



function Quest_Log:filter_shown_quests(text)
    text = text or self.search_bar and self.search_bar.text
    -- lower stuff if we found no uppercase letter
    local lower = text:find("%u") == nil -- if we found an uppercase letter
    local quests = self.quests

    local words = cfg.keyword_search and text:split() or {text}
    local first_found = 0

    local do_txts = cfg.search_quest_text
    local all_fzy = cfg.all_fzy
    -- log("searching quests with cfg.search_quest_text = %s", cfg.search_quest_text)
    for i, child in ipairs(self.quest_list_blk:getContentElement().children) do
        local vis = true
        -- first search name, then search other stuff if there's no match
        if not quests[i]:search_name(text, lower) then
            for _, word in ipairs(words) do
                if not quests[i]:search(word, all_fzy, do_txts, lower) then
                    vis = false
                    break
                end
            end
        end
        
        child.visible = vis
        if vis and first_found == 0 then 
            first_found = i 
        end
    end
    self.quest_list_blk.widget:contentsChanged()
    if first_found > 0 and cfg.set_first_result_active then
        self:set_active_quest(first_found)
    end
	self.ui_base:updateLayout()
end

-- add compatibility with right click menu exit
local rightclick_interop = include("mer.RightClickMenuExit")
if rightclick_interop then
    rightclick_interop.registerMenu{
        buttonId = UID_strs.close_button,
        menuId = UID_strs.menu,
    }
end


function Quest_Log.initialize()
    active_color = tes3ui.getPalette(tes3.palette.journalTopicPressedColor)
    -- active_color = tes3ui.getPalette(tes3.palette.journalTopicOverColor)
    -- active_color = tes3ui.getPalette(tes3.palette.activeColor)
    for k, v in pairs(UID_strs) do
        UIDS[k] = tes3ui.registerID(v)
    end
    log("registered UIDS: %s", json.encode, UIDS)

end


return Quest_Log
