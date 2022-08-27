local mod = {
    name = "Reading Is Good",
    ver = "2.0",
    cf = {slider = "5", sliderpercent = 4, blocked = {}, dropDown = 0}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local ori = {}

---@param book any
---@return string
local function name(book)
    return string.format("%s (%s)", book.name, tes3.skillName[book.skill])
end

---@param skillBooksRead number
---@return number
local function bonus(skillBooksRead)
    local cap = tonumber(cf.slider)
    if (skillBooksRead <= cap) then
        return (skillBooksRead*(cf.sliderpercent))
    else
        if (cf.dropDown == 1) then
            return ((cap*(cf.sliderpercent))+((skillBooksRead-cap)*(cf.sliderpercent)/2))
        else
            return (cap*(cf.sliderpercent))
        end
    end
end

event.register("loaded", function()
    tes3.player.data.spammer_publicoBooks = tes3.player.data.spammer_publicoBooks or {}
    tes3.player.data.spammer_publicoRead = tes3.player.data.spammer_publicoRead or {}
    for i, v in pairs (tes3.skillName) do
        if (tes3.player.data.spammer_publicoBooks[v] == nil) then
            local old = tes3.player.data.spammer_publicoBooks[i] or tes3.player.data.spammer_publicoBooks[tostring(i)]
            tes3.player.data.spammer_publicoBooks[v] = old or 0
            tes3.player.data.spammer_publicoBooks[tostring(i)] = nil
            tes3.player.data.spammer_publicoBooks[i] = nil
        end
    end
end)

---comment
---@param e table|equipEventData
event.register("equip", function(e)
    if e.reference ~= tes3.player then return end
    local book = e.item
    if book.objectType ~= tes3.objectType.book then return end
    if cf.blocked[name(book)] then return end
    if book.skill ~= -1 then
        local cap = tonumber(cf.slider)
        if tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]] >= cap then
            if (cf.dropDown == 0) then
                e.item.skill = -1
                return
            elseif (cf.dropDown == 2) then
                return
            end
        end
        tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]] = (tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]])+1
        tes3.messageBox{message = string.format("You gained knowledge from this book. Your %s skill will now improve %s%% faster.", tes3.skillName[book.skill], bonus(tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]]))}
        tes3.playSound{reference = tes3.player, sound = "skillraise"}
        tes3.player.data.spammer_publicoRead[book.id] = true
        e.item.skill = -1
        e.item.modified = true
    end

end)


---comment
---@param e table|activateEventData
event.register("activate", function(e)
    if e.activator ~= tes3.player then return end
    if tes3ui.menuMode() then return end
    local book = e.target.object
    if book.objectType ~= tes3.objectType.book then return end
    if cf.blocked[name(book)] then return end
    if book.skill ~= -1 then
        local cap = tonumber(cf.slider)
        if tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]] >= cap then
            if (cf.dropDown == 0) then
                e.item.skill = -1
                return
            elseif (cf.dropDown == 2) then
                return
            end
        end
        tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]] = (tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]])+1
        tes3.messageBox{message = string.format("You gained knowledge from this book. Your %s skill will now improve %s%% faster.", tes3.skillName[book.skill], bonus(tes3.player.data.spammer_publicoBooks[tes3.skillName[book.skill]]))}
        tes3.playSound{reference = tes3.player, sound = "skillraise"}
        tes3.player.data.spammer_publicoRead[book.id] = true
        e.target.object.skill = -1
        e.target.object.modified = true
    end
end)

---comment
---@param e table|exerciseSkillEventData
event.register("exerciseSkill", function(e)
    e.progress = e.progress*(1+(bonus(tes3.player.data.spammer_publicoBooks[tes3.skillName[e.skill]])/100))
end, {priority = -10})


local function getExclusionList()
    local fullbooklist = {}
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if book.skill ~= -1 then
            table.insert(fullbooklist, name(book))
        end
    end
    table.sort(fullbooklist)
    return fullbooklist
end



---comment
---@param skill number
---@return number[]
local function color(skill)
    local list = {
        [tes3.specialization.combat] = tes3ui.getPalette("health_color"),
        [tes3.specialization.magic] = tes3ui.getPalette("misc_color"),
        [tes3.specialization.stealth] = tes3ui.getPalette("normal_color")
    }
    local skillType = tes3.getSkill(skill).specialization
    return list[skillType]
end

---comment
---@param category2 tes3uiElement
---@param i string
---@param v number
---@param limit number
---@return number
local function separate(category2, i, v, limit)
    local skill = table.find(tes3.skillName, i)
    local skillType = tes3.mobilePlayer:getSkillStatistic(skill).type
    if skillType == limit then
    local label = category2:createLabel{text = i..": "..(bonus(v)).."%"}
    label.color = color(skill)
        label:register("mouseOver", function()
        if table.size(tes3.player.data.spammer_publicoRead) == 0 then return end
        local tool = tes3ui.createTooltipMenu()
            for book in tes3.iterateObjects(tes3.objectType.book) do
            if (ori[book.id] == skill) and tes3.player.data.spammer_publicoRead[book.id] then
            local block = tool:createBlock{}
            block.flowDirection = "left_to_right"
            block.autoHeight = true
            block.autoWidth = true
            local icon = block:createImage{path = "Icons\\"..book.icon}
            icon.scaleMode = true
            icon.height = 16
            icon.width = 16
            block:createLabel{text = " "..book.name} end
            end
        end)
        return 1
    end
    return 0
end

---comment
---@param here tes3uiElement
local function menuUpdate(here)
    here:destroyChildren()
    local category2 = here:createBlock()
    category2.autoHeight = true
    category2.autoWidth = true
    category2.flowDirection = "top_to_bottom"
    local count = 0
    local keys = table.keys(tes3.player.data.spammer_publicoBooks, true)
    for _,i in pairs(keys) do
        local v = tes3.player.data.spammer_publicoBooks[i]
        if ((v) and (v ~= 0)) then
            count = count+separate(category2, i, v, tes3.skillType.major)
        end
    end
    if count ~= 0 then
        category2:createLabel{text = "---------------"}
    end
    local newCount = count
    for _,i in pairs(keys) do
        local v = tes3.player.data.spammer_publicoBooks[i]
        if ((v) and (v ~= 0)) then
            count = count+separate(category2, i, v, tes3.skillType.minor)
        end
    end
    if count ~= newCount then
        category2:createLabel{text = "---------------"}
    end
    for _,i in pairs(keys) do
        local v = tes3.player.data.spammer_publicoBooks[i]
        if ((v) and (v ~= 0)) then
            count = count+1
            separate(category2, i, v, tes3.skillType.miscellaneous)
        end
    end
    if count == 0 then
        category2:createLabel{text = "None."}
    end
    here:getTopLevelMenu():updateLayout()
end

local done = false
event.register("mouseButtonUp", function()
    if not tes3.player then return end
    if not tes3ui.menuMode() then return end
    local menu = tes3ui.findMenu("MWSE:ModConfigMenu")
    if not menu then return end
    timer.start{type = timer.real, duration = 0.3, callback = function()
        local mark
    for child in table.traverse(menu.children) do
        if child.text == "Current Reading Bonuses:" then
            mark = child.parent.parent
        end
    end
    if not mark then return end
    local here = mark:findChild("InnerContainer")
    if not here then return end
        if here then menuUpdate(here) end end}
    local close = menu:findChild("MWSE:ModConfigMenu_Close")
    close:registerBefore("mouseClick", function()
        done = false
    end)
    menu:updateLayout()
end)

event.register("enterFrame", function()
    if not tes3.player then return end
    if not tes3ui.menuMode() then
        if done then done = false end
        return
    end
    if done then return end
    local menu = tes3ui.findMenu("MWSE:ModConfigMenu")
    if not menu then return end
    local mark
    for child in table.traverse(menu.children) do
        if child.text == "Current Reading Bonuses:" then
            mark = child.parent.parent
        end
    end
    if not mark then return end
    local here = mark:findChild("InnerContainer")
    if not here then return end
    menuUpdate(here)
    local close = menu:findChild("MWSE:ModConfigMenu_Close")
    close:registerBefore("mouseClick", function()
        done = false
    end)
    menu:updateLayout()
    done = true
end)

local function registerModConfig()
    local template = mwse.mcm.createTemplate{name = mod.name, headerImagePath = "textures/mwse/Reading_Is_Good.tga"}
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n "}
    page.sidebar:createInfo{ text = "Skill Books Cap: sets a limit on how many skill books give a training bonus. The base game has five books for each skill; some mods might add more [default: 5]"}
    page.sidebar:createInfo{ text = "- Hard Cap: skill books above the cap have no effect [default]"}
    page.sidebar:createInfo{ text = "- Soft Cap: skill books above the cap give half XP bonus"}
    page.sidebar:createInfo{ text = "- Vanilla Cap: skill books above the cap give one skill point \n "}
    page.sidebar:createInfo{ text = "XP Multiplier: sets the training bonus you receive from reading each skill book [default: 4%] \n "}
    page.sidebar:createInfo{ text = "Current Bonuses: shows the total XP bonus for each skill, sorted both by set (major, minor, miscellaneous) and by specialization: combat (red), magic (blue), stealth (yellow) \n \n "}
    page.sidebar:createInfo{ text = "A mod by Publicola and Spammer"}
    page.sidebar:createHyperLink{ text = "Publicola's Nexus Profile", url = "https://www.nexusmods.com/users/49943436?tab=user+files" }
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Skill Books Cap:")
    category0:createTextField{
        label = "Max:",
        variable = mwse.mcm.createTableVariable{
            id = "slider",
            table = cf,
            numbersOnly = true,
        }
    }
    category0:createDropdown{
        options = {
            { label = "Hard Cap", value = 0, },
            { label = "Soft Cap", value = 1, },
            { label = "Vanilla Cap", value =2},
        },
        variable = mwse.mcm.createTableVariable{id = "dropDown", table = cf}}

    local category = page:createCategory("XP Multiplier:")
    category:createSlider{label = "Multiplier: ".."%s%%", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

    local category2 = page:createCategory("Current Reading Bonuses:")
    category2:createInfo{text = "Load a saved game to see this."}

    template:createExclusionsPage{label = "Book BlackList", description = "Blacklisted books will behave the same way as in Vanilla.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if (book.skill ~= -1) then ori[book.id] = book.skill end
    end
end event.register("initialized", initialized, {priority = -1000})