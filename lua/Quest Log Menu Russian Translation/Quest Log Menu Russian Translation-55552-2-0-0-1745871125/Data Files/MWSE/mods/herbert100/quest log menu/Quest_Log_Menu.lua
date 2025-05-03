local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local log = hlib.Logger.new()

local cfg = hlib.get_mod_config() ---@type herbert.QLM.config

local common = hlib.import("common") ---@type herbert.QLM.common
local interop = hlib.import("interop") ---@type herbert.QLM.interop
local Quest_List = hlib.import("quest_list") ---@type herbert.QLM.Quest_List

local register_event = event.register

local MENU_ALPHA = 1
local TOOLTIP_HIGHLIGHT_COLOR
local ACTIVE_COLOR -- not currently used, but i don't remember what i wanted to use it for
local TITLE_COLOR
local LABEL_COLOR
local TEXT_SELECT_COLOR
local BG_COLOR

do -- make sure the color palette stays up to date
    -- update from light mode to dark mode
    -- happens during game launch, or whenever the config is reloaded
    local function update_color_palette()
        TOOLTIP_HIGHLIGHT_COLOR = tes3ui.getPalette(tes3.palette.linkColor)
        -- ACTIVE_COLOR = tes3ui.getPalette(tes3.palette.journalTopicPressedColor)
        if cfg.ui.light_mode then
            TITLE_COLOR = tes3ui.getPalette(tes3.palette.healthColor)
            LABEL_COLOR = tes3ui.getPalette(tes3.palette.blackColor)
            BG_COLOR = tes3ui.getPalette(tes3.palette.notifyColor)
            
            TEXT_SELECT_COLOR = {
                idleActive = tes3ui.getPalette(tes3.palette.journalLinkColor),
                overActive = tes3ui.getPalette(tes3.palette.journalLinkOverColor),
                pressedActive = tes3ui.getPalette(tes3.palette.journalLinkPressedColor),
            
                -- idle = tes3ui.getPalette(tes3.palette.blackColor),
                -- over = tes3ui.getPalette(tes3.palette.focusColor),
                -- pressed = tes3ui.getPalette(tes3.palette.whiteColor),
                idle = tes3ui.getPalette(tes3.palette.journalTopicColor),
                over = tes3ui.getPalette(tes3.palette.journalTopicOverColor),
                pressed = tes3ui.getPalette(tes3.palette.journalTopicPressedColor),
            
                idleDisabled = tes3ui.getPalette(tes3.palette.journalFinishedQuestColor),
                overDisabled = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor),
                pressedDisabled = tes3ui.getPalette(tes3.palette.journalFinishedQuestPressedColor),
            }
        else
            TITLE_COLOR = tes3ui.getPalette(tes3.palette.whiteColor)
            LABEL_COLOR = tes3ui.getPalette(tes3.palette.normalColor)
            BG_COLOR = tes3ui.getPalette(tes3.palette.blackColor)
            -- BG_COLOR = {0, 0, 0}
            TEXT_SELECT_COLOR = {
                idleActive = tes3ui.getPalette(tes3.palette.activeColor),
                overActive = tes3ui.getPalette(tes3.palette.activeOverColor),
                pressedActive = tes3ui.getPalette(tes3.palette.activePressedColor),
            } -- use default
        end
        log("updated color palette! light mode? %s", cfg.ui.light_mode)
    end

    register_event("herbert:QLM:MCM_closed", update_color_palette, {filter=hlib.get_mod_name()})
    register_event(tes3.event.initialized, update_color_palette)

    if tes3.isInitialized() then
        update_color_palette()
    end
end

---@class herbert.QLM.Quest_Log
---@field ui_index integer UI index of the current quest
---@field search_bar tes3uiElement
---@field search_timer mwseTimer
---@field quest_list_blk tes3uiElement
---@field ui_base tes3uiElement
---@field menu_destroyed boolean
local Quest_Log = {}
local Quest_Log_meta = {__index = Quest_Log}


---@return herbert.QLM.Quest_Log
function Quest_Log.new()
    local self = {}
    self.search_timer = timer.start{duration=0.15, type=timer.real, callback=function()
        local search_text = self.search_bar.text
        if search_text:len() > 1 and search_text ~= "Поиск..." then
            self:filter_shown_quests(search_text)
        else
            self:clear_search()
        end
    end}
    self.search_timer:cancel()

    self.menu_destroyed = false
    
    if Quest_List.outdated then
        Quest_List.remake_quests()
    end

    setmetatable(self, Quest_Log_meta)

    self:make_ui()
    
    return self
end

-- the indentation of this table definition matches the UI structure
---@class UID_strs 
---@field [string] integer|string
local uid_strs = {
    menu = "QLM:menu",
        left_blk = "QLM:left_blk",
            quest_list_frame = "QLM:quest_list_frame",
                search_bar = "QLM:search_bar",
                    search_bar_text = "QLM:search_bar_text",

                quest_list_pane = "QLM:quest_list_pane",

            left_button_bar = "QLM:left_button_bar",
                left_button_bar_frame = "QLM:left_button_bar_frame",

        right_blk = "QLM:right_blk",
            quest_container_rect =  "QLM:quest_container_rect",
                quest_container_pane = "QLM:quest_container_pane",
                    title = "QLM:title",
                    quest_header_blk = "QLM:quest_header_blk",
                    quest_progress_blk = "QLM:quest_progress_blk",
                    relevant_info_blk = "QLM:relevant_info_blk",
                    technical_info_blk = "QLM:technical_info_blk",
                    divider = "QLM:divider",

    
    quest_container = "QLM:quest_container",
    quest_info = "QLM:quest_info",
    bottom_button_bar = "QLM:bottom_button_bar",
    close_button = "QLM:close_button",
    quest = "QLM:quest",

    
    
    right_button_bar = "QLM:right_button_bar",
    set_hidden_btn = "QLM:set_hidden_btn",

    -- off in a whole other galaxy
    main_menu_close_btn = "MenuOptions_Return_container",
}
local uids = tbl_ext.map(uid_strs, tes3ui.registerID)




-- add compatibility with right click menu exit
local rightclick_interop = include("mer.RightClickMenuExit")
if rightclick_interop then
    rightclick_interop.registerMenu{buttonId=uid_strs.close_button, menuId=uid_strs.menu}
end


---@param e uiActivatedEventData
local function close_options_menu(e)
    local close_btn = e.element:findChild("MenuOptions_Return_container")
    if close_btn then
        close_btn:triggerEvent("mouseClick")
    end
end


function Quest_Log.close(block_next_options_menu)
    local menu = tes3ui.findMenu(uid_strs.menu)
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

---@type string, string, string
local gmst_yes, gmst_no, gmst_close = "Yes", "No", "Close"
register_event(tes3.event.initialized, function (e)
    gmst_yes = tes3.findGMST(tes3.gmst.sYes).value
    gmst_no = tes3.findGMST(tes3.gmst.sNo).value
    gmst_close = tes3.findGMST(tes3.gmst.sClose).value
end, {doOnce=true})

local function get_button_text(tbl, key)
    return tbl[key] and gmst_yes or gmst_no
end

---@param quest_index integer
---@return integer? ui_index
function Quest_Log:get_ui_index(quest_index)
    local contents = self.quest_list_pane:getContentElement()
    for i, blk in ipairs(contents.children) do
        if quest_index == blk:getPropertyInt("QLM:quest_index") then
            return i
        end
    end
end

--- make the bottom button bar that holds all the buttons
---@param parent tes3uiElement the lucky UI element that gets to house all these buttons
function Quest_Log:make_right_button_bar(parent)
    local button_bar_blk = parent:createRect{color = BG_COLOR, id=uids.right_button_bar}
    button_bar_blk.borderTop = 10
    button_bar_blk.widthProportional = 1.0
    button_bar_blk.childAlignY = 0.5
    -- button_bar_blk.childAlignX = -1.0
    button_bar_blk.autoHeight = true
    -- button_bar_blk.flowDirection = tes3.flowDirection.leftToRight

    local cont = button_bar_blk:createThinBorder()
    cont.widthProportional = 1.0
    cont.childAlignY = 0.5
    cont.autoHeight = true
    -- cont.flowDirection = tes3.flowDirection.leftToRight

    cont.childAlignX = -1
    cont.paddingTop = 5
    cont.paddingBottom = 5
    cont.paddingLeft = 10
    cont.paddingRight = 10

    local utility_blk = cont:createBlock()
    utility_blk.widthProportional = 1.0
    utility_blk.childAlignY = 0.5
    utility_blk.autoHeight = true
    -- utility_blk.flowDirection = tes3.flowDirection.leftToRight

    local function reset_state()
        Quest_List.remake_quests()
        self:create_quests_list()
        ---@diagnostic disable-next-line: missing-parameter
        self.search_timer.callback()
    end

    ---@type {[1]: string, [2]: table, [3]: string, [4]: fun(e:tes3uiEventData?)}[]
    local btns_info = {
        {"Поиск по ключевым словам", cfg.search, "keywords", reset_state},
        -- {"Search quest progress", cfg.search, "quest_progress", reset_state},
        -- {"Fuzzy search everything", cfg.search, "all_fzy", self.search_timer.reset},
        {"Показать техническую информацию о квесте", cfg, "show_technical_info", function()
            local old_index = self.ui_index
            if not old_index then return end
            self.ui_index = nil
            self:set_active_quest(old_index)
        end}
    }

    for _, btn_info in ipairs(btns_info) do
        local name, tbl, key, callback = btn_info[1], btn_info[2], btn_info[3], btn_info[4]
        local button_cont = utility_blk:createBlock()
        -- button_cont.widthProportional = 1
        button_cont.autoWidth = true
        button_cont.childAlignY = 0.5
        button_cont.autoHeight = true
        button_cont.borderRight = 30
        -- button_cont.flowDirection = tes3.flowDirection.leftToRight

        local btn = button_cont:createButton{text=get_button_text(tbl, key)}
        -- btn.borderRight = 7.5

        btn:register(tes3.uiEvent.mouseClick, function(e)
            tbl[key] = not tbl[key]
            e.source.text = get_button_text(tbl, key)
            callback()
        end)

        local widget = btn.widget
        for k,v in pairs(TEXT_SELECT_COLOR) do widget[k] = v end
        btn:triggerEvent("mouseLeave")

        button_cont:createLabel{text=name}.color = LABEL_COLOR
        -- btn_label.borderRight = 10
    end
    -- utility_blk.children[3].borderRight = 12

    local close_button = cont:createButton{id=uid_strs.close_button, text=gmst_close}
    close_button:register("mouseClick", Quest_Log.close)
    close_button.borderLeft = 50

    local widget = close_button.widget
    for k,v in pairs(TEXT_SELECT_COLOR) do widget[k] = v end
    close_button:triggerEvent("mouseLeave")
end

-- make the search bar buttons
---@param parent tes3uiElement
function Quest_Log:make_left_button_bar(parent)
    local left_btn_block = parent:createRect{color = BG_COLOR, id=uids.left_button_bar}
    left_btn_block.borderTop = 10
    left_btn_block.widthProportional = 1.0
    left_btn_block.autoHeight = true
    
    left_btn_block = left_btn_block:createThinBorder{id=uids.left_button_bar_frame}
    left_btn_block.widthProportional = 1.0
    left_btn_block.autoHeight = true
    left_btn_block.childAlignX = -1.0
    -- left_btn_block.flowDirection = tes3.flowDirection.leftToRight
    left_btn_block.paddingTop = 5
    left_btn_block.paddingBottom = 5
    left_btn_block.paddingLeft = 10
    left_btn_block.paddingRight = 10
    left_btn_block.childAlignY = 0.5

    local btn_infos = {
        {"Завершенные", "show_completed", {}},
        {"Скрытые", "show_hidden", {childAlignX = 1}},
    }

    for _, btn_info in ipairs(btn_infos) do
        local name, cfg_key, fmt_params = btn_info[1], btn_info[2], btn_info[3]
        local btn_cont = left_btn_block:createBlock()
        btn_cont.widthProportional = 1.0
        btn_cont.childAlignY = 0.5
        btn_cont.autoHeight = true
        -- btn_cont.flowDirection = tes3.flowDirection.leftToRight
        for k, v in pairs(fmt_params) do
            btn_cont[k] = v
        end

        local btn = btn_cont:createButton{text=get_button_text(cfg.quest_list, cfg_key)}
        btn.borderRight = 7.5
        btn:register(tes3.uiEvent.mouseClick, function(e)
            cfg.quest_list[cfg_key] = not cfg.quest_list[cfg_key]
            e.source.text = get_button_text(cfg.quest_list, cfg_key)
            Quest_List.remake_quests()
            self:create_quests_list()

            ---@diagnostic disable-next-line: missing-parameter
            self.search_timer.callback() -- redo any active search
        end)

        local widget = btn.widget
        for k,v in pairs(TEXT_SELECT_COLOR) do
            widget[k] = v
        end
        btn:triggerEvent("mouseLeave")
        local lbl = btn_cont:createLabel{text=name}
        lbl.color = LABEL_COLOR
    end
    

    -- left_btn_block:getTopLevelMenu():updateLayout()
    parent:updateLayout()
end


function Quest_Log:make_ui()
    local root = tes3ui.findMenu(uid_strs.menu)
	if root then
        root.visible = true
        self.ui_base = root
        self.quest_list_pane = root:findChild(uid_strs.quest_list)
	    tes3ui.enterMenuMode(root.id)
        return
    end
    -- Create the main menu frame.
    root = tes3ui.createMenu{ id = uid_strs.menu, fixedFrame=true}
    self.ui_base = root
    root.alpha = 0
    root:destroyChildren()
    root.flowDirection = tes3.flowDirection.topToBottom

    root:updateLayout()

    root:registerAfter(tes3.uiEvent.destroy, function (e)
        event.trigger("herbert.QLM:menu_destroyed")
        self.menu_destroyed = true
        e.source:forwardEvent(e)
    end)


    local width, height = tes3ui.getViewportSize()

    local root_width = width * cfg.ui.x_size
    local root_height = height * cfg.ui.y_size

    root.width = root_width
    root.minWidth =  root_width
    root.maxWidth =  root_width

    root.height = root_height
    root.minHeight = root_height
    root.maxHeight = root_height
    root.text = "Список заданий"

    root.positionX = root.width / -2
    root.positionY = root.height / 2

    root.flowDirection = tes3.flowDirection.leftToRight
    -- root.widthProportional = 1
    -- root.hei

    -- Create the left-right flow.
    -- local main_block = root:createBlock{ id = uid_strs.main_block }
    -- main_block.flowDirection = "left_to_right"
    -- main_block.widthProportional = 1.0
    -- main_block.heightProportional = 1.0
    -- self.main_blk = main_block

    -- actually, lets just make this be the root
    local main_block = root

    local left_blk = main_block:createBlock({ id = uid_strs.left_blk })
    left_blk.flowDirection = "top_to_bottom"
    
    -- left_blk.width = root_width / 4  -- TESTING (used to be 400)
    left_blk.minWidth = root_width / 4  -- TESTING (used to be 400)
    -- left_blk.maxWidth = root_width / 2  -- TESTING (used to be 400)
    left_blk.autoWidth = true
    -- left_blk.widthProportional = -1.0
    left_blk.heightProportional = 1.0
    left_blk.borderRight = 10
    self.left_blk = left_blk


    local right_blk = main_block:createBlock{id = uid_strs.right_blk}
    right_blk.flowDirection = "top_to_bottom"
    right_blk.widthProportional = 1.0
    right_blk.heightProportional = 1.0
    self.right_blk = right_blk
    -- right_block.paddingLeft = 4

    

    do -- fill left block
        local quest_list_block = left_blk:createRect{id=uid_strs.quest_list_frame, color=BG_COLOR}
        quest_list_block.childAlignX = 0.5
        quest_list_block.alpha = MENU_ALPHA
        quest_list_block.widthProportional = 1
        quest_list_block.heightProportional = 1
        quest_list_block.autoWidth = true -- TESTING
        quest_list_block.flowDirection = "top_to_bottom"


        local search_bar = quest_list_block:createThinBorder{id=uids.search_bar}
        search_bar.widthProportional = 1.0
        search_bar.autoHeight = true
        search_bar:register("mouseClick", function() 
            if not self.search_bar then return end
            tes3ui.acquireTextInput(self.search_bar)
        end)

        search_bar.autoWidth = true -- TESTING



        search_bar = search_bar:createTextInput{id=uids.search_bar_text, placeholderText="Поиск...", autoFocus=true}
        search_bar.borderLeft = 5
        search_bar.borderRight = 5
        search_bar.borderTop = 3
        search_bar.color = LABEL_COLOR
        search_bar.borderBottom = 5
        search_bar.autoWidth = true -- TESTING

        
        search_bar:registerAfter("textUpdated", function(e)
            search_bar.color = LABEL_COLOR
            self.search_timer:reset()
        end)
        search_bar:registerAfter("textCleared", function()
            search_bar.color = LABEL_COLOR

            self:clear_search() 
        end)
        self.search_bar = search_bar

        -- Create the mod list.
        local quest_list_pane = quest_list_block:createVerticalScrollPane{id=uids.quest_list_pane}
        quest_list_pane.autoWidth = true -- TESTING
        quest_list_pane.children[1].autoWidth = true


        self.quest_list_pane = quest_list_pane

        local quest_lists_content = quest_list_pane:getContentElement()
        quest_lists_content.autoWidth = true -- TESTING

        quest_lists_content.paddingLeft = 10
        quest_lists_content.paddingRight = 10
        quest_lists_content.paddingTop = 5
        log("made quest list block. filling it....")
        
        self:create_quests_list()
        root:updateLayout()
    end 
    
    do -- fill right block
        local quest_rect = right_blk:createRect{id=uid_strs.quest_container_rect, color=BG_COLOR }
        self.quest_container_rect = quest_rect
        quest_rect.alpha = MENU_ALPHA
        quest_rect.widthProportional = 1.0
        quest_rect.heightProportional = 1.0

        local pane = quest_rect:createVerticalScrollPane{id=uids.quest_container_pane}
        self.quest_container_pane = pane
        pane.widthProportional = 1.0
        pane.heightProportional = 1.0

    end

    self:make_left_button_bar(self.left_blk)
    self:make_right_button_bar(self.right_blk)
	tes3ui.enterMenuMode(root.id)
    root:updateLayout()

    -- set the previous quest as active
    local prev_quest_index = Quest_List.get_active_quest_index()
    if prev_quest_index then
        local ui_index = self:get_ui_index(prev_quest_index)
        self:set_active_quest(ui_index)
        return
    end

    if #Quest_List > 0 then
        self:set_active_quest(1)
        return
    end

    local pane_content = self.quest_container_pane:getContentElement()
    local lbl = pane_content:createLabel{text = "Нет активных заданий :("}
    lbl.absolutePosAlignX = 0.5
    lbl.absolutePosAlignY = 0.5
end

-- makes the UI block that holds one of the core parts of the active quest menu
---@param parent tes3uiElement
---@param id string
---@return tes3uiElement subcomponent
local function make_subcontainer(parent, id)
    local sub = parent:createBlock{id=id}
    sub.widthProportional = 1.0
    sub.autoHeight = true
    sub.flowDirection = tes3.flowDirection.topToBottom
    sub.borderTop = 10
    sub.borderBottom = 5
    sub.paddingLeft = 20
    sub.paddingRight = 20
    return sub
end

--- make a title header
---@param blk tes3uiElement container for the header
---@param text string text of the header
local function make_title(blk, text)
    local title = blk:createLabel{text=text, id=uids.title}
    title.color = TITLE_COLOR
    -- title.widget.idleActive = niColor.new()
    title.wrapText = true
    title.justifyText = tes3.justifyText.center
    title.borderTop = 7.5
    title.borderBottom = 7.5
    -- title.borderBottom = 7.5
    return title
end

---@param str string
---@return boolean
local function starts_with_vowel(str)
    return str:find("^[aeiouAEIOU]") ~= nil
end

---@param actor tes3actor
local function make_actor_heard_from_tooltip(actor)
    local ref = tes3.getReference(actor.id)
    if not ref then return end
   

    local obj = ref.object
    local pronoun = obj.female and "Она" or "Он"
    local tooltip = tes3ui.createTooltipMenu()
    local entries = tooltip:createBlock()
    entries.autoHeight = true
    entries.autoWidth = true
    entries.widthProportional = 1
    entries.flowDirection = tes3.flowDirection.topToBottom

    if ref == tes3.player then
        local bio_entry = entries:createBlock()
        bio_entry.autoHeight = true
        bio_entry.autoWidth = true
        local you_are_lbl = bio_entry:createLabel{text="Вы"}
        you_are_lbl.borderRight = 6
        local name_lbl = bio_entry:createLabel{text=obj.name}
        name_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        bio_entry:createLabel{text="."}
        tooltip:updateLayout() 
        return
    end

    do -- make race/class description
        local class = obj.class
        local race = obj.race
        local bio_entry = entries:createBlock()
        bio_entry.autoHeight = true
        bio_entry.autoWidth = true

        local name_lbl = bio_entry:createLabel{text=obj.name}
        name_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        --name_lbl.borderRight = 6

        if starts_with_vowel(race.name) then
            bio_entry:createLabel{text=","}
        else
            bio_entry:createLabel{text=","}
        end
        local race_lbl = bio_entry:createLabel{text=race.name}
        race_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        race_lbl.borderLeft = 6
        bio_entry:createLabel{text=". Класс:"} --race_lbl.borderRight = 6
        local class_lbl = bio_entry:createLabel{text=" " .. class.name}
        class_lbl.color = TOOLTIP_HIGHLIGHT_COLOR

        bio_entry:createLabel{text="."}
    end

    local faction = obj.faction
    if faction then
        local faction_entry = entries:createBlock()
        faction_entry.autoHeight = true
        faction_entry.autoWidth = true

        local rank_str = faction:getRankName(obj.factionRank)
        if starts_with_vowel(rank_str) then
            faction_entry:createLabel{text=pronoun .. " имеет ранг"}
        else
            faction_entry:createLabel{text=pronoun .. " имеет ранг"}
        end
        local faction_rank_lbl = faction_entry:createLabel{text=rank_str}
        faction_rank_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        faction_rank_lbl.borderLeft = 6
        faction_rank_lbl.borderRight = 6
        faction_entry:createLabel{text="во фракции"}
        local faction_name_lbl = faction_entry:createLabel{text=faction.name}
        faction_name_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        faction_name_lbl.borderLeft = 6
        faction_entry:createLabel{text="."}
    end
    

    local disp_entry = entries:createBlock()
    disp_entry.autoWidth = true
    disp_entry.autoHeight = true
    local disp = obj.disposition or obj.baseDisposition
    local opinion_str = "не очень хорошо вас знает"
    if disp and disp ~= obj.baseDisposition then
        opinion_str =   disp < 10 and "ненавидит вас"
                     or disp < 30 and "относится к вам с подозрением"
                     or disp < 50 and "относится к вам нейтрально"
                     or disp < 80 and "относится к вам положительно"
                     or               "относится к вам очень положительно"
    end
    disp_entry:createLabel{text=string.format("%s %s.", pronoun, opinion_str)}
    tooltip:updateLayout()
end

---@param loc_data herbert.QLM.Location_Data
local function make_location_data_tooltip(loc_data)
    local tooltip = tes3ui.createTooltipMenu()
    local tbl = tooltip:createBlock()
    tbl.autoHeight = true
    tbl.autoWidth = true
    tbl.widthProportional = 1
    tbl.flowDirection = tes3.flowDirection.leftToRight

    tbl.paddingAllSides = 3
    local left_col = tbl:createBlock()
    -- left_col.widthProportional = 1
    left_col.autoHeight = true
    left_col.autoWidth = true
    left_col.flowDirection = tes3.flowDirection.topToBottom
    left_col.childAlignX = 1
    left_col.borderRight = 6

    local right_col = tbl:createBlock()
    -- right_col.widthProportional = 1
    right_col.autoHeight = true
    right_col.autoWidth = true
    right_col.flowDirection = tes3.flowDirection.topToBottom



    local cellname_prefixes = {"Ячейка:", [#loc_data.path] = "Ближайшая внешняя ячейка:"}

    for j, cell in ipairs(loc_data.path) do
        -- local row = tooltip:createBlock()
        left_col:createLabel{text=cellname_prefixes[j] or "В районе:"}
        right_col:createLabel{text=cell.displayName}.color=TOOLTIP_HIGHLIGHT_COLOR
    end
    local ext_cell = loc_data.path[#loc_data.path]
    if ext_cell and ext_cell.region then
        local region_lbl = left_col:createLabel{text="Регион:"}
        region_lbl.borderTop = 5
        local region_txt = right_col:createLabel{text=ext_cell.region.name}
        region_txt.color=TOOLTIP_HIGHLIGHT_COLOR
        region_txt.borderTop = 5
    end

    tooltip:updateLayout()
end

---@param actor tes3npc
local function make_actor_location_tooltip(actor)
    local loc_data = common.get_actor_location_data(actor)
    if not loc_data then return end
    local tooltip = tes3ui.createTooltipMenu()
    local row = tooltip:createBlock()
    row.borderAllSides = 2
    row.autoWidth = true
    row.autoHeight = true
    row.widthProportional = 1
    -- row:createTextSelect{state=tes3.uiState.active, text=actor.name}
    local actor_name_label = row:createLabel{text=actor.name}
    actor_name_label.color = TOOLTIP_HIGHLIGHT_COLOR

    -- local tokens = loc_data:format_as_tokens(actor)

    -- just do it manually for now
    local tokens
    local filtered_and_flattened = loc_data:get_flattened_and_filtered_parts()
    if #filtered_and_flattened <= 1 then
        local region_name = loc_data.path[#loc_data.path].region.name
        local highlighted_part = filtered_and_flattened[1] or region_name

        if highlighted_part == region_name then
            tokens = {"в", region_name}
        end
    end
    tokens = tokens or {"в", loc_data:format_as_address(cfg.ui.region_names)}
    tokens[1] = "можно найти " .. tokens[1]


    for i, token in ipairs(tokens) do
        local token_lbl = row:createLabel{text=token}
        if i % 2 == 0 then
            token_lbl.color = TOOLTIP_HIGHLIGHT_COLOR
        end
        local is_punctuation = token:find("^[,.;'\"]") ~= nil
        if not is_punctuation then
            token_lbl.borderLeft = 6
        end
    end

    row:createLabel{text="."}
    row.parent:updateLayout()
end



---@param quest herbert.QLM.Quest
function Quest_Log:make_quest_header(quest)
    local num_actors = #quest.actor_names
    if num_actors == 0 then return end

    local preamble_blk = self.quest_header_blk
    -- make the table
    local tbl_blk = preamble_blk:createBlock()
    tbl_blk.flowDirection = tes3.flowDirection.topToBottom
    tbl_blk.autoHeight = true
    tbl_blk.widthProportional = 1
    -- tbl_blk.borderTop = 5

    preamble_blk:updateLayout()

    -- indices of the quests with location datas
    local num_infos = #quest.infos
    local info_indices, prefixes = {}, {}
    info_indices[1] = 1
    prefixes[1] = "Впервые услышал от:"
    -- tooltip_texts[1] = "This is the person that started the quest."
    -- tooltip_texts[2] = "This is the most recent person that progressed the quest."
    if num_infos > 1 then
        info_indices[2] = num_infos
        prefixes[2] =  "Последнее сообщение от:"
    end
    local min_size = 0
    for i, info_index in ipairs(info_indices) do
        local actor_name = quest.actor_names[info_index]
        local loc_data = quest.location_datas[info_index]
        local prefix = prefixes[i]

        local info_blk = tbl_blk:createBlock()
        info_blk.flowDirection = tes3.flowDirection.leftToRight
        info_blk.autoHeight = true
        info_blk.widthProportional = 1
        info_blk.borderBottom = 5

        local left_label = info_blk:createLabel{text=prefix}
        left_label.color = LABEL_COLOR
        left_label.borderRight = 10

        info_blk:updateLayout()
        min_size = math.max(min_size, left_label.width)


        left_label.maxWidth = min_size
        left_label.minWidth = min_size
        left_label.width = min_size
        left_label.autoWidth = false
        left_label.widthProportional = nil

        local name_label = info_blk:createTextSelect{text = actor_name, state=tes3.uiState.active}
        name_label.widget.idleActive = TEXT_SELECT_COLOR.idleActive
        name_label.widget.overActive = TEXT_SELECT_COLOR.overActive
        name_label.widget.pressedActive = TEXT_SELECT_COLOR.pressedActive
        name_label:triggerEvent("mouseLeave")

        name_label:register(tes3.uiEvent.help, function()
            make_actor_heard_from_tooltip(quest.infos[info_index].firstHeardFrom)
        end)

        if loc_data then
            local in_sep = info_blk:createLabel{ text = "в" }
            in_sep.borderLeft = 5
            in_sep.color = LABEL_COLOR
            in_sep.borderRight = 5
            local loc_label = info_blk:createTextSelect{
                state = tes3.uiState.active, 
                text = loc_data:format_as_address(cfg.ui.region_names)
            }
            
            loc_label.widget.idleActive = TEXT_SELECT_COLOR.idleActive
            loc_label.widget.overActive = TEXT_SELECT_COLOR.overActive
            loc_label.widget.pressedActive = TEXT_SELECT_COLOR.pressedActive
            loc_label:triggerEvent("mouseLeave")
            
            loc_label:register(tes3.uiEvent.help, function ()
                make_location_data_tooltip(loc_data)
            end)
            
        end
    end

end


---@param quest herbert.QLM.Quest
function Quest_Log:make_quest_progress(quest)

    local progress_blk = self.quest_progress_blk

    if #quest.infos == 0 then
        local dummy_lbl = progress_blk:createLabel{text="Прогресс отсутствует."}
        dummy_lbl.absolutePosAlignX = 0.5
        dummy_lbl.borderBottom = 10
        return
    end

    ---@param e tes3uiEventData
    local function click_topic_callback(e)
        
        local relevant_information = self.relevant_info_blk
        if not relevant_information then 
            log:error("could not find relevant information!")
            return
        end

        local topic_index = e.source:getPropertyInt("QLM:topic_index")
        local topic_text = quest.topics[topic_index]

        log("topic clicked! %q", topic_text)

        for i, topic_cont in ipairs(relevant_information.children) do
            
            if  i > 1 and topic_index == topic_cont:getPropertyInt("QLM:topic_index") then
                log:trace("\found topic! clicking it...")
                topic_cont:triggerEvent("mouseClick")

                return
            end
        end
        log:trace("\tcouldnt find topic!")
    end

    ---@type tes3uiElement, tes3uiElement, tes3uiElement, tes3uiElement
    local entry_blk, row_blk, description_blk, txt_blk

    local new_row = true


    local function remake_row_blk()
        log:trace("----- making a new row block")
        -- row_blk:getTopLevelMenu():updateLayout()
        entry_blk:updateLayout()
        row_blk = description_blk:createBlock()
        -- row_blk.flowDirection = tes3.flowDirection.leftToRight
        row_blk.autoWidth = true
        row_blk.autoHeight = true
        new_row = true
    end

    ---@param txt string
    ---@param topic_index integer
    local function make_txt_blk(txt, topic_index)
        if topic_index > 0 then
            txt_blk = row_blk:createTextSelect{text=txt, state=tes3.uiState.active}
            txt_blk.widget.idleActive = TEXT_SELECT_COLOR.idleActive
            txt_blk.widget.overActive = TEXT_SELECT_COLOR.overActive
            txt_blk.widget.pressedActive = TEXT_SELECT_COLOR.pressedActive
            txt_blk:setPropertyInt("QLM:topic_index", topic_index)
            txt_blk:registerAfter(tes3.uiEvent.mouseClick, click_topic_callback)
            -- elem.borderLeft = 2
        else
            txt_blk = row_blk:createLabel{text=txt}
            txt_blk.color = LABEL_COLOR
        end
        description_blk:updateLayout()
        new_row = false
    end


    -- progress_blk:getTopLevelMenu():updateLayout()
    -- progress_blk:updateLayout()

    quest:load_tokens()
    -- fill out the quest progress block
    -- this is a complicated process, because we're goign to be adding clickable buttons in the middle of regular text
    -- so it requires using a custom text layout and quite a bit of logic
    for i, token_list in ipairs(quest.quest_progress_tokens) do

        entry_blk = progress_blk:createBlock()
        entry_blk.widthProportional = 1
        entry_blk.autoHeight = true
        entry_blk.borderBottom = 8
        entry_blk.borderRight = 10
        -- entry_blk.flowDirection = tes3.flowDirection.leftToRight
        
        local enum_lbl = entry_blk:createLabel{text = i .. ")"}
        enum_lbl.borderRight = 5
        enum_lbl.color = LABEL_COLOR
        
        description_blk = entry_blk:createBlock()
        description_blk.widthProportional = 1
        description_blk.autoHeight = true
        description_blk.flowDirection = tes3.flowDirection.topToBottom
        
        -- progress_blk:getTopLevelMenu():updateLayout()
        progress_blk:updateLayout()

        local desc_width = description_blk.width

        if #token_list == 1 then
            local lbl = description_blk:createLabel{text = token_list[1][1]}
            lbl.wrapText = true
            lbl.color = LABEL_COLOR
            -- lbl.borderBottom = 15
            goto next_text
        end

        row_blk = description_blk:createBlock()
        -- row_blk.flowDirection = tes3.flowDirection.leftToRight
        row_blk.autoWidth = true
        row_blk.autoHeight = true

        log:trace("adding quest progress: %i) %q", i, quest.quest_progress_strs[i])
        for _, token in ipairs(token_list) do
            -- description_blk:updateLayout()

            local token_txt = token[1] ---@type string
            log:trace("\titerating token %q", token_txt)
            local topic_index = token[2]

            local max_width = desc_width - row_blk.width

            if topic_index > 0 then
                token_txt = string.format(" %s ", token_txt)
            end

            log:trace("\t\tmax_width = %s", max_width)
            log:trace("\t\trow_width = %s", row_blk.width)

            -- wrap the text so it fits on the line
            ---@diagnostic disable-next-line: undefined-field
            local wrapped_txt = tes3ui.textLayout.wrapText{text=token_txt, maxWidth=max_width}
            
            
            -- check the wrapped text exceeds the available space
            -- this can happen when there's very little space left
            ---@diagnostic disable-next-line: undefined-field
            if not new_row and tes3ui.textLayout.getTextExtent{text=wrapped_txt, firstLineOnly=true} > max_width then
                -- remake the current row, and re-wrap the txt using the new width
                remake_row_blk()
                max_width = desc_width - row_blk.width
                ---@diagnostic disable-next-line: undefined-field
                wrapped_txt = tes3ui.textLayout.wrapText{text=token_txt, maxWidth=max_width}
            end

            -- if it's not a new row, we need to give the first line some special treatment
            -- this is because the first line will have a smaller width than the rest of the lines should have.
            if not new_row then
                local new_line_pos = wrapped_txt:find("\n", 1, true)
                -- local s, e, first_line = wrapped_txt:find("([^\n]+)")

                local first_line = wrapped_txt
                if new_line_pos then
                    if new_line_pos <= 1 then
                        log:trace("\t\tfirst line not found! skipping token %q", wrapped_txt)
                        goto next_token 
                    end
                    first_line = wrapped_txt:sub(1, new_line_pos - 1)
                end
    
                log:trace("\t\tfirst line = %q. topic_index = %s", first_line, topic_index)
    
    
    
                make_txt_blk(first_line, topic_index)
    
                if first_line:len() == token_txt:len() then goto next_token end

                -- e + 1 is the new line, so e + 2 is the next character
                wrapped_txt = token_txt:sub(new_line_pos)

                max_width = desc_width
    
                wrapped_txt = tes3ui.textLayout.wrapText{text=wrapped_txt, maxWidth=max_width}
                log:trace("\t\trest of text =%q. topic_index = %s", wrapped_txt, topic_index)
            end
            -- add the remaining topics
            -- if topic_index <= 0 then
            -- not a topic, so add it normally
            for line in wrapped_txt:gmatch("[^\n]+") do
                remake_row_blk()
                make_txt_blk(line, topic_index)
            end

            ::next_token::
        end
        ::next_text::
        -- description_blk:updateLayout()
        -- entry_blk:getTopLevelMenu():updateLayout()
    end
    -- progress_blk:updateLayout()
        
    -- progress_blk:getTopLevelMenu():updateLayout()
end

---@param quest herbert.QLM.Quest
function Quest_Log:make_relevant_info(quest)

    local relevant_information = self.relevant_info_blk
    -- this is a table indexed by `topic_id`
    -- if you give it a `topic_id`, you get a `tes3dialogue` that stores a bunch of info about that topic
    local dialogues_by_topic = quest:get_topic_dialogues()

    -- make this info block
    -- holds all the things we've heard about a certain topic
    -- speaker is stored in left column 
    -- what they said is stored in the right column
    ---@param info_blk tes3uiElement
    ---@param dialogue tes3dialogue
    local function make(info_blk, dialogue)
        

        local topic_entry_blk = info_blk:createBlock()
        -- topic_entry_blk.flowDirection = tes3.flowDirection.leftToRight
        topic_entry_blk.autoHeight = true
        topic_entry_blk.widthProportional = 1.0

        local left_col = topic_entry_blk:createBlock()
        left_col.autoHeight = true
        left_col.autoWidth = true
        left_col.childAlignX = 1.0
        left_col.flowDirection = tes3.flowDirection.topToBottom
        left_col.paddingRight = 6

        local right_col = topic_entry_blk:createBlock()
        right_col.autoHeight = true
        right_col.widthProportional = 1.0
        right_col.flowDirection = tes3.flowDirection.topToBottom

        local added_texts = {}
        for _, data in ipairs(quest:load_topic_dialogue(dialogue)) do
            if not added_texts[data[2]] then
                local actor, progress_text = data[1], data[2]

                local left_label = left_col:createTextSelect{state = tes3.uiState.active, text = actor.name .. ":"}
                left_label.widget.idleActive = TEXT_SELECT_COLOR.idleActive
                left_label.widget.overActive = TEXT_SELECT_COLOR.overActive
                left_label.widget.pressedActive = TEXT_SELECT_COLOR.pressedActive
                -- left_label.borderRight = 6
                left_label.borderTop = 6

                -- show where somebody is when you click their name
                left_label:registerAfter(tes3.uiEvent.help, function()
                    make_actor_location_tooltip(actor)
                end)

                local right_label = right_col:createLabel{text = string.format('"%s"', progress_text)}
                right_label.wrapText = true
                right_label.justifyText = tes3.justifyText.left
                right_label.widthProportional = 1.0
                right_label.borderTop = 6
                right_label.color = LABEL_COLOR

                added_texts[data[2]] = true
            end
        end

        -- make sure the layout is right, and then update the heights so the columns line up
        -- right_col:updateLayout()
        added_texts = nil
        info_blk.parent:updateLayout()
        

        for i, left_label in ipairs(left_col.children) do 
            left_label.height = right_col.children[i].height
        end
    end

    ---@param e tes3uiEventData
    local function on_click_topic_name(e)
        local container = e.source.parent
        local info_blk = container.children[2]
        local dots = container.children[3]

        info_blk.visible = not info_blk.visible
        dots.visible = not dots.visible

        -- make the block if necessary
        -- we're only making it when it gets clicked on for performance reasons,
        -- since making the block can mean loading a bunch of dialogue files
        if info_blk.visible and #info_blk.children == 0 then
            local topic_index = container:getPropertyInt("QLM:topic_index")
            local topic_id = quest.topics[topic_index]
            local dialogue = dialogues_by_topic[topic_id]
            make(info_blk, dialogue)
        end

        local pane = self.quest_container_pane
        if pane then
            pane:updateLayout()
            pane.widget:contentsChanged()
        end

        -- info_blk:getTopLevelMenu():updateLayout()
    end

    -- clicking on the box makes the label think it got clicked
    ---@param e tes3uiEventData
    local function on_click_topic_container(e)
        e.source.children[1]:triggerEvent(e)
    end


    -- iterate each topic
    local added_topics = {}

    local clicked_topics = 0
    local dialogue
    local light_mode = cfg.ui.light_mode

    -- this is where we add all the boxes
    for i, topic_id in ipairs(quest.topics) do
        if added_topics[topic_id] then goto next_id end
        
        dialogue = rawget(dialogues_by_topic, topic_id)
        if not dialogue then goto next_id end

        added_topics[topic_id] = true

        -- the big container that holds the topic label, along with the information or the (click to expand) label
        local topic_container

        if light_mode then
            topic_container = relevant_information:createRect{color = tes3ui.getPalette(tes3.palette.blackColor)}
            topic_container.alpha = 0.1
        else
            topic_container = relevant_information:createThinBorder()
            -- topic_container.borderLeft = 15
            -- topic_container.borderRight = 15
        end

        topic_container.paddingAllSides = 10
        -- topic_container.borderAllSides = 5
        topic_container.borderTop = 5
        topic_container.borderBottom = 5
        topic_container.flowDirection = tes3.flowDirection.topToBottom
        topic_container.widthProportional = 1.0
        topic_container.autoHeight = true
        topic_container.borderBottom = 10
        topic_container.childAlignX = 0.5
        topic_container.consumeMouseEvents = true
        topic_container:setPropertyInt("QLM:topic_index", i)
        topic_container:registerAfter(tes3.uiEvent.mouseClick, on_click_topic_container)
        
        local topic_name = topic_container:createTextSelect{text=topic_id, state=tes3.uiState.active}
        topic_name.widget.idleActive = TEXT_SELECT_COLOR.idleActive
        topic_name.widget.overActive = TEXT_SELECT_COLOR.overActive
        topic_name.widget.pressedActive = TEXT_SELECT_COLOR.pressedActive
        topic_name.borderBottom = 2

        -- holds all the information we know about a topic
        local information_blk = topic_container:createBlock()
        information_blk.flowDirection = tes3.flowDirection.topToBottom
        information_blk.widthProportional = 1.0
        information_blk.autoHeight = true
        information_blk.visible = false
        information_blk:setPropertyInt("QLM:topic_index", i)

        local dotdotdot_lbl = topic_container:createLabel{text="(Нажмите, чтобы развернуть)"}
        dotdotdot_lbl.color = LABEL_COLOR
        dotdotdot_lbl.visible = true
        dotdotdot_lbl.consumeMouseEvents = false

        topic_name:registerAfter(tes3.uiEvent.mouseClick, on_click_topic_name)

        -- open up the first five topics that have fewer than 10 entries
        if clicked_topics < 5 then

            local num_heard = 0

            local MAX_NUM_HEARD = 10

            for _, info in ipairs(dialogue.info) do
                if info.firstHeardFrom then
                    num_heard = num_heard + 1
                    if num_heard > MAX_NUM_HEARD then break end
                end
            end
            if num_heard <= MAX_NUM_HEARD then
                clicked_topics = clicked_topics + 1

                information_blk.visible = true
                dotdotdot_lbl.visible = false

                -- we'll actually open them later, so that the sub menus can be formatted first
                -- this saves on "expensive" ui updates later
                -- make(information_blk, dialogue)

            end
        end
        ::next_id::
    end


    -- no topics added? that's cool too
    if next(added_topics) == nil then
        local lbl = relevant_information:createLabel{text="Информация отсутствует."}
        lbl.wrapText = true
        lbl.justifyText = tes3.justifyText.center
        lbl.borderBottom = 7.5
        relevant_information:updateLayout()
        return
    end

    relevant_information:updateLayout()

    for _, child in ipairs(relevant_information.children) do
        -- children[2] is the clickable box, children[1] is the topic id
        if child.children[2].visible then
            make(child.children[2], dialogues_by_topic[child.children[1].text])
        end
    end
end

local vanilla_sources = {
    ["Bloodmoon.esm"] = true, 
    ["Morrowind.esm"] = true, 
    ["Tribunal.esm"] = true
}

---@param quest herbert.QLM.Quest
function Quest_Log:make_technical_info(quest)

    local technical_info_blk = self.technical_info_blk
    local ids, sources, indices = tbl_ext.new(), tbl_ext.new(), tbl_ext.new()
    for _, d in ipairs(quest.quest.dialogue) do
        ids:insert(d.id)
        indices:insert(d.journalIndex)
        if not vanilla_sources[d.sourceMod] then
            sources:insert(d.sourceMod)
        end
    end


    local faction
    for _, info in ipairs(quest.infos) do
        if info.firstHeardFrom.faction then 
            faction = info.firstHeardFrom.faction
            break
        end
    end
    local footer_info = {
        {"Фракция:", faction and string.format('"%s"', faction.name) or "Нет"}
    }
    if #ids == 1 then
        footer_info[2] = {"ID диалога:", ids[1]}
    else
        footer_info[2] = {"IDs диалогов:", table.concat(ids, ", ")}
    end
    if #indices == 1 then
        footer_info[3] = {"Индекс журнала:", tostring(indices[1] or "Нет")}
    else
        footer_info[3] = {"Индексы журнала:", table.concat(indices, ", ")}
    end
    if #sources > 0 then
        footer_info[4] = {"Изменено:", table.concat(sources, ", ")}
    else
        footer_info[4] = {"Изменено:", "Нет"}
    end

    footer_info[1][3] = "Фракция, к которой принадлежит квестодатель."
    footer_info[2][3] = "Список ID диалогов, связанных с этим квестом."
    footer_info[3][3] = "Журнальный индекс каждого диалога, связанного с этим квестом."
    footer_info[4][3] = "Список модов, которые изменили диалог, связанный с этим квестом.\n\z
        \"Нет\" означает, что этот квест не был изменен модом."



    local blk, string_pairs, border_between = technical_info_blk, footer_info, 5

    for _, p in ipairs(string_pairs) do 
        local row = technical_info_blk:createBlock()
        row.flowDirection = tes3.flowDirection.leftToRight
        row.widthProportional = 1
        row.autoHeight = true
        local title = row:createTextSelect{state=tes3.uiState.active, text=p[1]}
        for k,v in pairs(TEXT_SELECT_COLOR) do title.widget[k] = v end
        title:register(tes3.uiEvent.help, function (e)
            local tooltip = tes3ui.createTooltipMenu()
            tooltip:createLabel{text=p[3]}
        end)

        title.borderRight = 10
        title.borderBottom = 6

        local info_lbl = row:createLabel{text=p[2]}
        info_lbl.wrapText = true
        info_lbl.color = LABEL_COLOR
        info_lbl.justifyText = tes3.justifyText.left
        info_lbl.widthProportional = 1.0
        info_lbl.borderBottom = 6
    end
    -- left_label.borderBottom = 0
    -- right_label.borderBottom = 0
    
    technical_info_blk:updateLayout()
    -- blk:getTopLevelMenu():updateLayout()


    -- technical_info_blk:getTopLevelMenu():updateLayout()
end

---@param quest herbert.QLM.Quest
function Quest_Log:make_hidden_btn(quest)
    local btn_container = self.quest_container_pane:getContentElement()
    local set_hidden_btn = btn_container:createButton{
        id =uids.set_hidden_btn, 
        text = quest.is_hidden and "Отобразить задание" or "Скрыть задание"
    }
    -- what happens when somebody clicks the hiden button?
    set_hidden_btn:register(tes3.uiEvent.mouseClick, function (e)

        Quest_List.toggle_hidden_flag(quest)
        e.source.text = quest.is_hidden and "Отобразить задание" or "Скрыть задание"
        -- update the quests the next time the menu is open
        -- this way, newly hidden quests are still in the menu, so you can more easily undo your actions
        event.register("herbert.QLM:menu_destroyed", function()
            Quest_List.clear()
        end, {doOnce=true})
        e.source:updateLayout()
        Quest_List.quests:sort()
        self:create_quests_list()
        ---@diagnostic disable-next-line: missing-parameter
        self.search_timer.callback()
    end)
    local widget = set_hidden_btn.widget
    for k, v in pairs(TEXT_SELECT_COLOR) do
        widget[k] = v
    end
    set_hidden_btn:triggerEvent("mouseLeave")
    set_hidden_btn.color = LABEL_COLOR

    set_hidden_btn.absolutePosAlignX = 0.5
end

---@param parent tes3uiElement
---@return tes3uiElement
local function make_divider(parent)
    local div = parent:createDivider{id=uids.divider}
    div.borderAllSides = 6
    return div
end

-- =============================================================================
-- UPDATE ACTIVE QUEST (set index)
-- =============================================================================

-- set the active quest to this index and build all the ui elements
-- this function is borderline unreadable. the implementation will hopefully be changed
-- in the future, once i find a better way to do these things. but this is just the 
-- first version
function Quest_Log:set_active_quest(ui_index)
    if ui_index == nil then
        ui_index = 1
    elseif ui_index == self.ui_index then
        return
    end

    local quest = self:get_quest(ui_index)
    if not quest then 
        log("couldn't find quest with index %s", ui_index)
        return 
    end
    quest:load_quest_progress()

    
    log("setting active quest to %q", quest.name)

    if self.ui_index then
        self:update_quest_button(self.ui_index, false)
    end
    self:update_quest_button(ui_index, true)
    self.ui_index = ui_index
    
    self.ui_base.text = string.format("Квест: %q", quest.name)

    local pane_content = self.quest_container_pane:getContentElement()
    pane_content:destroyChildren()


    -- =========================================================================
    -- BUILD SKELETON
    -- =========================================================================
    -- building the skeleton before filling it means we don't have to make as
    -- many calls to `updateLayout`, saving on precious nanoseconds

    pane_content.paddingTop = 10
    pane_content.paddingBottom = 10
    make_title(pane_content, quest.name)
    self.quest_header_blk = make_subcontainer(pane_content, uids.quest_header_blk)
    make_divider(pane_content)

    make_title(pane_content, "Прогресс задания")
    self.quest_progress_blk = make_subcontainer(pane_content, uids.quest_progress_blk)
    make_divider(pane_content)

    
    make_title(pane_content, "Полезная информация")
    self.relevant_info_blk = make_subcontainer(pane_content, uids.relevant_info_blk)

    if cfg.show_technical_info then 
        make_divider(pane_content)
        make_title(pane_content, "Техническая информация")
        self.technical_info_blk = make_subcontainer(pane_content, uids.technical_info_blk)
    end



    -- =========================================================================
    -- FILL SKELETON
    -- =========================================================================

    pane_content:updateLayout()

    self:make_quest_header(quest)
    self:make_quest_progress(quest)
    self:make_relevant_info(quest)
    if cfg.show_technical_info then 
        self:make_technical_info(quest)
    end


    pane_content:createDivider()
    self:make_hidden_btn(quest)

    pane_content:updateLayout()
    -- self.right_blk:updateLayout()
    self.quest_container_pane.children[2]:setPropertyInt("PartScrollBar_current", 0)
    -- self.quest_container_pane:updateLayout()
    self.quest_container_pane.widget:contentsChanged()

    Quest_List.set_active_quest(quest)

end

---@param ui_index integer? index of the UI element. Default: `self.ui_index`
---@return herbert.QLM.Quest? quest if it exists
---@return tes3uiElement? quest_blk the ui element that holds the quest
function Quest_Log:get_quest(ui_index)
    ui_index = ui_index or self.ui_index
    if not ui_index then return end
    local quest_blk = self.quest_list_pane:getContentElement().children[ui_index]
    return quest_blk and Quest_List.quests[quest_blk:getPropertyInt("QLM:quest_index")]
end

---@param ui_index integer? index of the UI element. Default: `self.ui_index`
---@return herbert.QLM.Quest? quest if it exists
---@return tes3uiElement? quest_blk the ui element that holds the quest
function Quest_Log:get_quest_and_quest_blk(ui_index)
    ui_index = ui_index or self.ui_index
    if not ui_index then return end
    local quest_blk = self.quest_list_pane:getContentElement().children[ui_index]
    local quest = quest_blk and Quest_List.quests[quest_blk:getPropertyInt("QLM:quest_index")]
    if quest then
        return quest, quest_blk
    end
end


---@param ui_index integer index of the quest to update
---@param set_active boolean mark this quest as selected?
function Quest_Log:update_quest_button(ui_index, set_active)
    local quest, quest_blk = self:get_quest_and_quest_blk(ui_index)
    -- local quest_blk = quest_list_children[ui_index]
    -- local quest = quest_blk and self.quest_list[quest_blk:getPropertyInt("QLM:quest_index")]
    if not quest or not quest_blk then return end

    -- handle the case where there are UI buttons
    local quest_label = quest_blk.children and quest_blk.children[2] or quest_blk

    if not quest_label.widget then return end


    if set_active then
        quest_label.widget.state = tes3.uiState.active
    else
        -- should the label be greyed out?
        quest_label.widget.state = (quest.is_finished or quest.is_hidden) and tes3.uiState.disabled
                                    or tes3.uiState.normal
            
    end
    quest_blk:updateLayout()
    log:trace("updated widget for quest %q\n\tstate = %s", quest.name, quest_label.widget.state)


end

---@param e tes3uiEventData
local function trigger_child_event(e)
    e.source.children[2]:triggerEvent(e)
end


function Quest_Log:create_quests_list()
    local quest_list_contents = self.quest_list_pane:getContentElement()
    quest_list_contents:destroyChildren()

    -- this implementation is a bit awkward
    -- the reason we look up the ui index each time a button gets clicked is because
    -- the ui index can change at any moment (and it will change when searching)
    ---@param e tes3uiEventData
    local function on_click_quest_name(e)
        local quest_index = e.source.parent:getPropertyInt("QLM:quest_index")
        local ui_index = self:get_ui_index(quest_index)
        if ui_index then
            self:set_active_quest(ui_index)
        end
        -- self.quest_container_pane.widget:contentsChanged()
    end


    local get_quest_icon_path = cfg.ui.show_icons and interop.get_quest_icon_path
                               or function() end
    for i, quest in ipairs(Quest_List.quests) do
        local blk = quest_list_contents:createBlock()
        blk.childAlignY = 0.5
        blk.autoHeight = true
        blk.widthProportional = 1
        blk.borderBottom = 10
        blk.autoWidth = true    -- TESTING
        -- blk.flowDirection = tes3.flowDirection.leftToRight
        blk:setPropertyInt("QLM:quest_index", i)

        local quest_icon_path = get_quest_icon_path(quest.quest)

        ---@type tes3uiElement, tes3uiElement
        local image_blk, entry
        if quest_icon_path then
            image_blk = blk:createImage{path=quest_icon_path}
            image_blk.scaleMode = true
            image_blk.width = 30
            image_blk.height = 30
            image_blk.borderRight = 7.5
            -- image_blk.borderLeft = 10

            entry = blk:createTextSelect{id=uid_strs.quest, text=quest.name}
            entry.absolutePosAlignY = 0.35
        else
            --- super hacky. something still has to exist so that the UI structure is the same in both cases
            -- (otherwise, `entry` would be accessed by `children[1]` instead of `children[2]`)
            image_blk = blk:createBlock()
            entry = blk:createTextSelect{id=uid_strs.quest, text=quest.name}
            -- entry.borderLeft = 10
        end
        local widget = entry.widget
        for k, v in pairs(TEXT_SELECT_COLOR) do 
            widget[k] = v
        end

        if quest.is_finished or quest.is_hidden then
            entry.widget.state = tes3.uiState.disabled
        end

        blk:register(tes3.uiEvent.mouseClick, trigger_child_event)
        blk:register(tes3.uiEvent.mouseOver, trigger_child_event)
        blk:register(tes3.uiEvent.mouseLeave, trigger_child_event)
        entry:register(tes3.uiEvent.mouseClick, on_click_quest_name)
    end
    if #quest_list_contents.children > 0 then
        quest_list_contents.children[#quest_list_contents.children].borderBottom = nil 
    end

    self.quest_list_pane:updateLayout()
    self.quest_list_pane.widget:contentsChanged()

    -- update the index, if appropriate
    if self.ui_index then 
        -- make sure it's within a valid range now that the number of quests has changed
        local old_ui_index = math.min(self.ui_index, #quest_list_contents.children)
        
        self.ui_index = nil -- dont do the button update logic
        if old_ui_index > 0 then
            self:set_active_quest(old_ui_index)
        end
    end
end



function Quest_Log:clear_search()
    local content = self.quest_list_pane:getContentElement()
    for _, child in pairs(content.children) do
        child.visible = true
    end
    self:sort_quests()
    self.left_blk:updateLayout()
    -- self.ui_base:updateLayout()
end


function Quest_Log:next_quest()
    local num_quests = #Quest_List
    if num_quests < 0 then
        log("can't set next quest because there are no quests!")
        return
    end
    if not self.ui_index then
        log("no next quest, setting active quest to 1")
        self:set_active_quest(1)
        return
    end
    if num_quests == 1 then
        log("can't set next quest because there's only one quest and it's already active!")
        return
    end

    local contents_children =  self.quest_list_pane:getContentElement().children

    -- index can get messed up when quests are hidden and stuff
    local start_index = self.ui_index + 1

    if start_index < 1 then
        start_index = 1
    elseif start_index > #contents_children then
        start_index = #contents_children
    end

    for ui_index = start_index, num_quests do
        if contents_children[ui_index].visible then
            self:set_active_quest(ui_index)
            return
        end
    end
end

function Quest_Log:prev_quest()
    local num_quests = #Quest_List
    if num_quests < 0 then
        log("can't set previous quest because there are no quests!")
        return
    end
    if not self.ui_index then
        log("no previous quest, setting active quest to 1")
        self:set_active_quest(1)
        -- self.quest_container_pane.widget:contentsChanged()
        return
    end
    if num_quests == 1 then
        log("can't set previous quest because there's only one quest and it's already active!")
        return
    end

    local contents_children =  self.quest_list_pane:getContentElement().children
    local start_index = self.ui_index - 1

    if start_index < 1 then
        start_index = 1
    elseif start_index > #contents_children then
        start_index = #contents_children
    end

    for ui_index = start_index, 1, -1 do
        if contents_children[ui_index].visible then
            self:set_active_quest(ui_index)
            return
        end
    end
end

---@param scores integer[]? a list of scores to sort by 
function Quest_Log:sort_quests(scores)
    local quests_blk = self.quest_list_pane

    if not quests_blk then return end

    local content = quests_blk:getContentElement()

    local old_quest_index
    if self.ui_index then
        local _, old_quest_blk = self:get_quest_and_quest_blk(self.ui_index)
        if old_quest_blk then
            old_quest_index = old_quest_blk:getPropertyInt("QLM:quest_index")
        end
    end
    
    -- local quests = self.quest_list.quests

    -- well sort things using the index rather than the quests
    -- this is because the `quest_list` shouldn't ever change while this menu is active 
    --      (unless `quest_list_blk` gets recreated immediately after), 
    -- and sorting the quests involves checking flags and comparing strings
    -- so it's much cheaper to just compare the indices, which correspond to sorted quests

    if scores then
        content:sortChildren(function(q1, q2)
            -- if something is invisible, don't even bother checking anything else
            if q1.visible ~= q2.visible then
                return q1.visible -- means `a < b` if `a` is visible and `b` isn't
            end
            local i1 = q1:getPropertyInt("QLM:quest_index")
            local i2 = q2:getPropertyInt("QLM:quest_index")
            if scores[i1] ~= scores[i2] then
                return scores[i1] > scores[i2]
            end

            -- return quests[i1] < quests[i2]
            return i1 < i2
        end)
    else
        content:sortChildren(function(q1, q2)
            if q1.visible ~= q2.visible then
                return q1.visible
            end
            -- return quests[a:getPropertyInt("QLM:quest_index")] < quests[b:getPropertyInt("QLM:quest_index")]
            return q1:getPropertyInt("QLM:quest_index") < q2:getPropertyInt("QLM:quest_index")
        end)
    end
    
    self.quest_list_pane:updateLayout()
    self.quest_list_pane.widget:contentsChanged()

    if old_quest_index then
        for i, child in ipairs(self.quest_list_pane:getContentElement().children) do
            if child:getPropertyInt("QLM:quest_index") == old_quest_index then
                self.ui_index = i
                break
            end
        end
    end
    
end

function Quest_Log:filter_shown_quests(text)
    text = text or self.search_bar and self.search_bar.text

    local scores = Quest_List.score_quests(text)
    -- local threshold = cfg.search.fzy_threshold
    local MIN_SCORE = -math.huge
    local content =  self.quest_list_pane:getContentElement()
    local content_children = content.children
    for _, child in ipairs(content_children) do
        -- if a quest's score sucks then we hide it
        local quest_index = child:getPropertyInt("QLM:quest_index")
        child.visible = scores[quest_index] > MIN_SCORE
    end

    self:sort_quests(scores)
    -- self.right_blk:updateLayout()

    local first_quest_blk = self.quest_list_pane:getContentElement().children[1]
    if first_quest_blk then
        log("sorted quests. first quest = \"%s\". visible = %s", function() 
            return table.get(self:get_quest(1), "name"), first_quest_blk.visible
        end)

        if first_quest_blk.visible then
            self:set_active_quest(1)
        end
    end
    -- self.right_blk:updateLayout()
end



local function time_function(name)
    Quest_Log[name] = hlib.timeit(Quest_Log[name], "Quest_Log." .. name)
end
-- time_function("set_active_quest")
-- time_function("make_quest_progress")
-- time_function("make_relevant_info")
time_function("new")
-- time_function("make_quest_header")
-- time_function("make_technical_info")

return Quest_Log