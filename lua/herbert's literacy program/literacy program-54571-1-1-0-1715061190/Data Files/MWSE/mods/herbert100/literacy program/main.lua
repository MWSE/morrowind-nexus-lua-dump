local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local upd_reg = hlib.update_registration
local log = Herbert_Logger()

local cfg = hlib.import("config") ---@type herbert.HLP.config

local common = hlib.import("common") ---@type herbert.HLP.common

local knowledge_manager = hlib.import("knowledge_manager") ---@type herbert.HLP.Knowledge_Manager

hlib.import("data.knowledge_bonuses") -- register the default bonuses

local skill_books = common.skill_books


---@param e uiSkillTooltipEventData
local function skill_tooltip_callback(e)
    local skill_id = e.skill
    log("in skill tooltip for %q", tes3.skillName[e.skill])
    
    local header_color =  tes3ui.getPalette(tes3.palette.headerColor)

    local knowledge = knowledge_manager:get_skill_knowledge(skill_id)
    if knowledge <= 0 then return end

    local content = e.tooltip:getContentElement()
    local book_blk = content:createBlock()
    book_blk.autoHeight = true
    book_blk.autoWidth = true
    book_blk.widthProportional = 1
    book_blk.flowDirection = tes3.flowDirection.topToBottom

    book_blk.childAlignX = 0.5
    book_blk.borderTop = 10
    book_blk.borderBottom = 10

    local div = book_blk:createDivider()
    div.borderTop = 10
    div.borderBottom = 10

    do -- bonuses block

        local bonuses_blk = book_blk:createBlock()
        bonuses_blk.autoHeight = true
        bonuses_blk.autoWidth = true
        bonuses_blk.widthProportional = 1
        bonuses_blk.flowDirection = tes3.flowDirection.topToBottom
        bonuses_blk.childAlignX = 0.5

        local bonuses_header = bonuses_blk:createLabel{text="Skill Book Bonuses"}
        bonuses_header.color = header_color
        bonuses_header.borderBottom = 5


        log("%q knowledge: %s", tes3.skillName[skill_id], knowledge)
        for _, kb in ipairs(knowledge_manager:get_skill_knowledge_bonuses(skill_id, true)) do
            local bonus_disp_str = kb:get_display_string(skill_id)
            if bonus_disp_str then
                log:trace("added bonus: %s", bonus_disp_str)
                bonuses_blk:createLabel{text = bonus_disp_str}
            end
        end
    end

    local books = knowledge_manager:get_books_read(skill_id, true)

    log("books_read = %s", function ()
        return json.encode(tbl_ext.map(books, function(b) return b.name end))
    end)

    -- book progress block
    if next(books) ~= nil then
        knowledge_manager:update_progress_limits()
        local progress_blk = book_blk:createBlock()
        progress_blk.autoHeight = true
        progress_blk.autoWidth = true
        progress_blk.widthProportional = 1
        progress_blk.flowDirection = tes3.flowDirection.topToBottom
        progress_blk.childAlignX = 0.5
        progress_blk.borderTop = 20
        
        local progress_header = progress_blk:createLabel{text="Skill Book Progress"}
        progress_header.borderBottom = 5
        progress_header.borderBottom = 5
        progress_header.color = header_color
        
        for _, book in ipairs(books) do
            log("adding progress for book = %q (id = %q)", book.name, book.id)
            progress_blk:createLabel{text=book.name}.borderBottom = 5
            progress_blk:createFillBar{
                current = math.round(knowledge_manager:get_book_progress(book.id)), 
                max = math.round(knowledge_manager:get_book_progress_limit(book.id))
            }.borderBottom = 5
        end
    end

    do -- total knowledge block
        local total_knowledge_blk = book_blk:createBlock()
        total_knowledge_blk.autoHeight = true
        total_knowledge_blk.autoWidth = true
        total_knowledge_blk.flowDirection = tes3.flowDirection.leftToRight
        total_knowledge_blk.borderTop = 15
        
        local total_knowledge_header = total_knowledge_blk:createLabel{text="Total Knowledge:"}
        total_knowledge_header.color = header_color
        total_knowledge_header.borderRight = 4

        total_knowledge_blk:createLabel{text=tostring(math.round(knowledge))}

    end

    content:updateLayout()
end

---@param e uiObjectTooltipEventData
local function object_tooltip(e)
    if not e.tooltip then return end
    local skill_id = common.get_skill_id(e.object)
    if not skill_id then return end -- not a skill book? bail
    local book = e.object ---@type tes3book
    
    -- update the maximum amount of progress we can earn
    knowledge_manager:update_progress_limits() 

    log:trace("editing tooltip for book %q (id=%q; skill = %q)", book.name, book.id, tes3.skillName[skill_id])


    local content = e.tooltip:getContentElement() ---@type tes3uiElement

    local blk = content:createBlock()
    blk.paddingAllSides = 6
    blk.flowDirection = tes3.flowDirection.topToBottom
    blk.widthProportional = 1.0
    blk.autoHeight = true
    blk.autoWidth = true

    do -- header 
        local header_row = blk:createBlock()
        header_row.flowDirection = tes3.flowDirection.leftToRight
        header_row.widthProportional = 1.0
        header_row.autoHeight = true
        header_row.autoWidth = true
        header_row.childAlignX = 0.5
        header_row.childAlignY = 0.5
        header_row.borderBottom = 20

        local skill_icon = header_row:createImage{path=tes3.getSkill(skill_id).iconPath}
        skill_icon.borderRight = 10

        header_row:updateLayout()
        header_row.paddingRight = math.floor(skill_icon.width/2)

        local header = header_row:createLabel{text=tes3.getSkillName(skill_id) .. " Skill Book"}
        header.color = tes3ui.getPalette(tes3.palette.headerColor)
    end

    do -- info
        local info_blk = blk:createBlock()
        info_blk.flowDirection = tes3.flowDirection.topToBottom
        info_blk.widthProportional = 1.0
        info_blk.childAlignX = 0.5
        info_blk.autoHeight = true
        info_blk.autoWidth = true

        local learned_label = info_blk:createLabel{text="Information Learned"}
        learned_label.color = tes3ui.getPalette(tes3.palette.headerColor)
        learned_label.borderBottom = 10
        info_blk:createFillBar{
            current=math.round(knowledge_manager:get_book_progress(book.id)),
            max=math.round(knowledge_manager:get_book_progress_limit(book.id)), 
        }
    end
    content:updateLayout()
end



---@param e activateEventData
local function activate_callback(e)
    local book = e.target and e.target.object
    if common.get_skill_id(book) then ---@cast book tes3book
        book.skill = -1
    end
end


---@param e equipEventData
local function equip(e)
    if e.reference ~= tes3.player then return end

    local skill_id = common.get_skill_id(e.item)
    if not skill_id then return end

    local book = e.item ---@type tes3book
    
    book.skill = -1
    book.modified = true

    log("skill book equipped! %s", book.name)

    tes3ui.showMessageMenu{header="What would you like to do?",
        buttons={ 
            {text="Study", callback=function()
                knowledge_manager:study_book{book=book, skill_id=skill_id, show_msg=true}
            end}, 
            {text="Open", callback=function()
                tes3.mobilePlayer:equip{item=book}
            end}, 
        },
        cancels=true,
        cancelText="Nothing.",
        leaveMenuMode=false
    }
    return false
end



local last_book_weight

local function update_book_weights()
    last_book_weight = last_book_weight or tbl_ext.first2(skill_books, function(book_id)
        local obj = tes3.getObject(book_id)
        return obj and obj.weight
    end)

    if last_book_weight == cfg.skill_book_weight then return end

    for book_id in pairs(skill_books) do
        local book = tes3.getObject(book_id)
        if book then
            book.weight = cfg.skill_book_weight
        end
    end
    last_book_weight = cfg.skill_book_weight
end

local function mcm_closed()
    update_book_weights()
end

---@param e skillRaisedEventData
local function skill_raised(e)
    local skill_id = e.skill
    local blocked_books = knowledge_manager.player_data.read_at_lvl
    local to_remove = {}
    for book_id in pairs(blocked_books) do
        if skill_books[book_id] == skill_id then
            table.insert(to_remove, book_id)
        end
    end

    for _, book_id in ipairs(to_remove) do
        blocked_books[book_id] = nil
    end
    knowledge_manager:update_progress_limits()
end
-- ---@param e uiExFilterFunction
-- local function filter_inventory(e)
--     e.
-- end

local function initialized()
    upd_reg{tes3.event.equip, equip}
    upd_reg{tes3.event.loaded, function() knowledge_manager:load_player_data() end}
    upd_reg{tes3.event.activate, activate_callback}
    upd_reg{tes3.event.uiObjectTooltip, object_tooltip}
    upd_reg{tes3.event.uiSkillTooltip, skill_tooltip_callback}
    upd_reg{"herbert:MCM_closed", mcm_closed, filter=hlib.get_mod_name()}

    upd_reg{tes3.event.skillRaised,skill_raised}

    update_book_weights()

    log:write_init_message()
end
event.register("initialized", initialized, {priority=-10000})

-- =============================================================================
-- MCM
-- =============================================================================

event.register("modConfigReady", function (e)
    local MCM = hlib.MCM.new(); MCM:register()

    local page = MCM:new_sidebar_page{label="Settings"}

    page:new_slider{id="skill_book_weight",
        label="Skill book weight", 
        desc="This mod incentivizes holding onto skill books for much longer than the vanilla game. \z
        To make this less punishing, you can reduce the weight of skill books.\n\n\z
        In the vanilla game, skill books weigh 3 units. The default setting of this mod is 1.5 units.",
        min=0.1, max=4, dp=1, step=0.1, jump=0.3,
    }

    
    page:new_button{id="blk_until_lvled",
    label="Block book progress until skill is leveled?", 
    desc="If enabled, you will only be able to read a book once per skill level. \z
        In other words, after progressing your knowledge of a book, you won't be able to gain additional \z
        progress in that book until the relevant skill is leveled. This is done on a book by book basis."
    }
    page:new_button{id="play_sound",
        label="Play a sound when progressing a skill book?", 
        desc="If enabled, the skill levelup sound will play when reading a skill book.",
    }
    page:new_slider{id="fade_to_black_time",
        label="Fade to black when reading skill books? %s seconds", 
        desc="Controls the number of (real world) seconds that the game will fade to black for when reading skill books.\n\n\z
            Set to 0 to disable.",
        min=0, max=3, dp=2
    }
    page:new_slider{id="study_pass_time",
        label="In-game time to pass when studying books? %s hours", 
        desc="Controls the number of (in-game) that should pass when reading a skill book.\n\n\z
            Set to 0 to disable.",
        min=0, max=6, dp=0
    }
    

    page:add_log_settings()

    do -- make exclusions page
        local function fmt_book_id(book_id)
            return string.format("%s (id = \"%s\")", 
                (tes3.getObject(book_id) or {}).name or "Error", book_id
            )
        end

        local function get_id(str)
            return select(3, str:find("%(id = \"(.-)\"%)")) or "invalid"
        end

        local filter_cfg = setmetatable({}, {
            __index=function (_, k) return cfg.blacklist[get_id(k)] end,
            __newindex=function (_, k, v) cfg.blacklist[get_id(k)] = v end,
            __pairs = function()
                return coroutine.wrap(function()
                    for book_id, TRUE in pairs(cfg.blacklist) do
                        coroutine.yield(fmt_book_id(book_id), TRUE)
                    end
                end) 
            end
        })

        MCM.template:createExclusionsPage{label="Book blacklist",
            description="Blacklisted books will behave the same way as in the base game.", 
            filters={{label="Books", callback=function()
                return skill_books:map2(fmt_book_id):values(true)
            end}},
		    -- `createExclusionsPage` wants a table, so we make yet another table to store the filter wrapper in
            variable=mwse.mcm.createTableVariable{id=1, table={filter_cfg}},
            leftListLabel="Not Allowed",
            rightListLabel="Allowed",
        }
    end
end)