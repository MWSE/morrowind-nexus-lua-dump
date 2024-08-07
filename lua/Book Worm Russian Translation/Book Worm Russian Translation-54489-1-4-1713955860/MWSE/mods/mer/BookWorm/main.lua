
--Initialise tables
local function onLoad()
    tes3.player.data.bookIndicator = tes3.player.data.bookIndicator or { enableMod = true }
    tes3.player.data.bookIndicator.booksRead = tes3.player.data.bookIndicator.booksRead or {}
end
event.register("loaded", onLoad)

local currentBook

local function getData()
    if tes3.player then
        return tes3.player.data.bookIndicator
    end
end

local function bookAlreadyRead()
    local hasRead
    for _, val in ipairs(getData().booksRead) do
        if val.id == currentBook.id then
            hasRead = true
        end
    end
    return hasRead
end

--Add books to list when activated
local function checkBookActivate(e)
    if currentBook then
        local readList = getData().booksRead
        local nextButton = e.element:findChild(tes3ui.registerID("MenuBook_button_next"))

        if nextButton.visible == false then
            
            if not bookAlreadyRead() then
                table.insert(readList, { id = currentBook.id, name = currentBook.name })
            end
        else
            e.element:register("update", function(event)
                timer.frame.delayOneFrame(
                    function()
                        e.element:forwardEvent(event)
                        checkBookActivate(e)
                    end
                )
            end)
        end
    end
end
event.register("uiActivated", checkBookActivate, { filter = "MenuBook"})


local function updateCurrentBook(e)
    currentBook = e.book
end
event.register("bookGetText", updateCurrentBook)

--Add tooltip
local function addTooltip(tooltip)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = label.text .. " (прочитано)"
end

local function onTooltip(e)
    if e.object.objectType == tes3.objectType.book then
        if getData().enableMod then
            local booksList = getData().booksRead
            for _, book in ipairs(booksList) do
                if book.id == e.object.id then
                    addTooltip(e.tooltip)
                    break
                end
            end
        end
    end
end
event.register("uiObjectTooltip", onTooltip)


--------------------------------------
--MCM
--------------------------------------

local function registerMCM()
--Initilaise MCM

    local sideBarDefault = (
        "Этот мод добавляет метку \"(прочитано)\" рядом с названием " ..
        "книг, которые вы уже прочитали. " ..
        "Это относится только к тем книгам, которые были прочитаны после установки мода. " ..
        "Необходимо дочитать (долистать) книгу до последней страницы, чтобы появилась отметка. "
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Автор: Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }
    end


    local template = mwse.mcm:createTemplate("Книжный червь")
    template:register()
    local page = template:createSideBarPage()
    addSideBar(page)
    local enableButton = page:createOnOffButton{
        label = "Индикатор прочитанных книг",
        description = "Включает отображение метки о прочтении книги во всплывающей подсказке. ",
        variable = mwse.mcm.createPlayerData{
            id = "enableMod",
            path = "bookIndicator",
        }
    }
    local category = page:createCategory("Прочитанные книги:")
    local bookList = category:createInfo{
        text = "",
        inGameOnly = true,
        postCreate = function(self)
            local callMessage = (
                tes3.player and
                tes3.player.data.bookIndicator and 
                getData().booksRead
            )
            if callMessage then
                local list = ""
                local readList = getData().booksRead
                if #readList == 0 then
                    self.elements.info.text = "Отсутствуют"
                else
                    local sort_func = function(a, b)
                        return string.lower(a.name) > string.lower(b.name)
                    end
                    table.sort(readList, sort_func)
                    for _, book in ipairs(readList) do
                        list = book.name .. "\n" .. list
                    end
                    self.elements.info.text = list
                end
            end
        end
    }
end
event.register("modConfigReady", registerMCM)