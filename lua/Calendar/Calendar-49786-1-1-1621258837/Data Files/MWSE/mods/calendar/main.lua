--[[
    Calendar
    v1.1
    by JaceyS

    Puts a calendar in your journal. Access by opening your journal, and clicking "Options". It opens to the current day.
    You can click on another day, and write a note for it, which you can see again whenever you access that day.

    New in v1.1
    -Interoperability functions, so that other MWSE mods can interact with the calendar notes. See calendar.interop for details.

    New in v1.0
    -Magic code from Hrnchamd fixes the issue with the journal keybind. You can now type notes containing the letter "j".byte(
    -Image buttons now behave as expected, because I just hid the default ones and made my own.
    -The bookmark menu now remembers if had the calendar open when you last closed it, if reopened during the same journal session,
     reopens the calendar, though always to the current date.

    Credit: The functions to disable and reenable the journal keybinds were written by Hrnchamd specifically for this mod.
    )
]]
local init = {
}
local journalKeybindDisabled = false

-- some magic code from Hrn. I don't know how it works, but it does the trick!
-- the first function disables the JournalCloseKeybind, which is the one keybind not caught by tes3ui.acquireTextInput(element)
-- the second function reenables that keybind. If you use this in your own mod, make sure to reenable the keybind when you are done
local function disableJournalCloseKeybind()
    mwse.memory.writeByte{address=0x41AF6D, byte=0xEB}
end
local function enableJournalCloseKeybind()
    mwse.memory.writeByte{address=0x41AF6D, byte=0x74}
end

local emptyMonths = {}
for i = 0, 11, 1 do
    emptyMonths[tostring(i)] = {}
end

-- when this mod was released, tes3.getCumulativeDaysForMonth() was broken, and thus so was tes3.getSimulationTimestamp()
local function getCumulativeDaysForMonth(m)
    local cumulativeDaysForMonth = {}
        cumulativeDaysForMonth[0] = 0
    for i= 1, 11, 1 do
        cumulativeDaysForMonth[i] = cumulativeDaysForMonth[i-1] + tes3.getDaysInMonth(i-1)
    end
    return cumulativeDaysForMonth[m]
end

local lastDate = {}
local dayNames = {"Sundas", "Morndas", "Tirdas", "Middas", "Turdas", "Fredas", "Loredas"}

local function makeDateTable(date)
    -- outputs a table with a bunch of date information. If given a SimulationTimestamp value, it is for that day,
    -- if given just a day, it is that day out of the whole era,
    -- if given day, month, and year it will calculate for that day, parsing day as day of the month
    -- if given nothing, it uses the global variables
    local day
    if (date.timestamp ~= nil) then
        day = math.floor(date.timeStamp / 24) -- this would give the wrong date, since tes3.getSimulationTimestamp() uses the incorrect data behind tes3.getCumulativeDaysForMonth()
    elseif(date.day ~= nil and date.month == nil) then
        day = date.day
    elseif( date.day ~=nil and date.month ~= nil and date.year ~= nil) then
        day = date.year * 365 + getCumulativeDaysForMonth(date.month) + date.day -1
    else
        day = tes3.findGlobal("year").value *365 + getCumulativeDaysForMonth(tes3.findGlobal("month").value) + tes3.findGlobal("day").value -1 -- Globals to the rescue?
    end
    local dayOfTheWeek = ((day + 1)% 7) + 1
    local year = math.floor(day / 365)
    local dayOfTheYear = day % 365
    local month
    for i=0, 11, 1 do
        if (dayOfTheYear < getCumulativeDaysForMonth(i)) then
            month = i-1
            break
        else
            month = 11
        end
    end
    local dayOfTheMonth = dayOfTheYear - getCumulativeDaysForMonth(month) + 1
    local firstDayOfTheMonth = day - (dayOfTheMonth)
    local dayOfTheWeekOfTheFirstOfTheMonth = ((firstDayOfTheMonth + 1) % 7) + 1
    local startOfTheFirstWeek = firstDayOfTheMonth - (dayOfTheWeekOfTheFirstOfTheMonth)
    local daysBefore = firstDayOfTheMonth - startOfTheFirstWeek
    local dayOfTheMonthOrdinal
    if (dayOfTheMonth == 1 or dayOfTheMonth == 21 or dayOfTheMonth == 31) then
        dayOfTheMonthOrdinal = "st"
    elseif (dayOfTheMonth == 2 or dayOfTheMonth == 22) then
        dayOfTheMonthOrdinal = "nd"
    elseif(dayOfTheMonth == 3 or dayOfTheMonth == 23) then
        dayOfTheMonthOrdinal = "rd"
    else
        dayOfTheMonthOrdinal = "th"
    end
    local output = {
        day = day,
        dayOfTheWeek = dayOfTheWeek,
        year = year,
        dayOfTheYear = dayOfTheYear,
        month = month,
        dayOfTheMonth = dayOfTheMonth,
        firstDayOfTheMonth = firstDayOfTheMonth,
        startOfTheFirstWeek = startOfTheFirstWeek,
        daysBefore = daysBefore,
        dayOfTheMonthOrdinal = dayOfTheMonthOrdinal
    }
    lastDate = output
    return output
end

local function saveNotes()
    if(journalKeybindDisabled == true) then
        enableJournalCloseKeybind()
        journalKeybindDisabled = false
    end
    local menuJournal = tes3ui.findMenu(init.menuJournalID)
    local calendarPane = menuJournal:findChild(init.calendarPaneID)
    if (calendarPane == nil) then return end
    local notesPane = calendarPane:findChild(init.notesPaneID)
    if (notesPane.text == nil) then return end
    if (tes3.player.data.JaceyS == nil) then
        tes3.player.data.JaceyS = {}
    end
    if (tes3.player.data.JaceyS.Calendar == nil) then
        tes3.player.data.JaceyS.Calendar = {}
    end
    if tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)] == nil then
        tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)] = emptyMonths
    end
    if tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)][tostring(lastDate.month)] == nil then
        tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)][tostring(lastDate.month)] = {}
    end
    tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)][tostring(lastDate.month)][tostring(lastDate.dayOfTheMonth)] = notesPane.text
    if (notesPane.text == "") then
        tes3.player.data.JaceyS.Calendar[tostring(lastDate.year)][tostring(lastDate.month)][tostring(lastDate.dayOfTheMonth)] = nil
    end
end

local function createCalendarPane(input)
    saveNotes()
    local date = makeDateTable(input)
    local menuJournal = tes3ui.findMenu(init.menuJournalID)

    local calendarButton = menuJournal:findChild(init.calendarButtonID)
    local calendarButtonChildren = calendarButton.children
    local calendarButtonIdle = calendarButtonChildren[1]
    local calendarButtonOver = calendarButtonChildren[2]
    local calendarButtonPressed = calendarButtonChildren[3]
    calendarButtonIdle.visible = false
    calendarButtonPressed.visible = true
    calendarButton.disabled = true

    local topicsButtonReplacement = menuJournal:findChild(init.menuTopicsReplacementID)
    topicsButtonReplacement.disabled = false
    topicsButtonReplacement.children[1].visible = true
    topicsButtonReplacement.children[3].visible = false


    local questsButtonReplacement = menuJournal:findChild(init.menuQuestsReplacementID)
    questsButtonReplacement.disabled = false
    questsButtonReplacement.children[1].visible = true
    questsButtonReplacement.children[3].visible = false

    local questsActiveButton = menuJournal:findChild(init.questsActiveButtonID)
    for _, child in ipairs(questsActiveButton.children) do
        child.visible = false
    end
    local questsAllButton = menuJournal:findChild(init.questsAllButtonID)
    for _, child in ipairs(questsAllButton.children) do
        child.visible = false
    end

    local bookmarkLayout = menuJournal:findChild(init.menuBookmarkLayoutID)
    bookmarkLayout:destroyChildren()
    local calendarPane = bookmarkLayout:createBlock({id = init.calendarPaneID})
    calendarPane.autoHeight = true
    calendarPane.widthProportional = 1
    calendarPane.heightProportional = 1
    calendarPane.flowDirection = "top_to_bottom"
    calendarPane.childAlignX = 0.5
    local labelMonth = tes3.findGMST(date.month).value
    local labelYear = " " .. date.year .. " 3E"
    local monthLabel = calendarPane:createLabel({text = labelMonth .. labelYear})
    monthLabel.color = {0.624, 0.000, 0.000}

    local calendarBlock = calendarPane:createBlock({id = init.calendarBlockID})
    calendarBlock.paddingTop = 12
    calendarBlock.paddingBottom = 12
    calendarBlock.autoHeight = true
    calendarBlock.widthProportional = .8
    calendarBlock.flowDirection = "top_to_bottom"
    calendarBlock.childAlignX = 0.5



    if (tes3.player.data.JaceyS == nil) then
        tes3.player.data.JaceyS = {}
    end
    if (tes3.player.data.JaceyS.Calendar == nil) then
        tes3.player.data.JaceyS.Calendar = {}
    end
    if tes3.player.data.JaceyS.Calendar[tostring(date.year)] == nil then
        tes3.player.data.JaceyS.Calendar[tostring(date.year)] = emptyMonths
    end

    for w, week in ipairs(init.weeks) do
        local weekBlock = calendarBlock:createBlock({id = week})
        weekBlock.autoHeight = true
        weekBlock.autoWidth = true
        weekBlock.flowDirection = "left_to_right"
        for d, day in ipairs(init.days) do
            local dayBlock = weekBlock:createBlock({id = day})
            dayBlock.width = 18
            dayBlock.height = 18
            dayBlock.childAlignX = 0.5
            local dayLabelText
            local outOfMonth = false
            local beforeMonth = false
            local lastYear = false
            local nextYear = false
            local cumulativeDays = ((w-1) * 7) + d - date.daysBefore
            if (cumulativeDays <= 0) then
                outOfMonth = true
                beforeMonth = true
                if (date.month == 0) then
                    lastYear = true
                end
                dayLabelText = tes3.getDaysInMonth((date.month - 1) % 12) + cumulativeDays
            elseif (cumulativeDays > tes3.getDaysInMonth(date.month)) then
                outOfMonth = true
                if (date.month == 11) then
                    nextYear = true
                end
                dayLabelText = cumulativeDays - tes3.getDaysInMonth(date.month)
            else
                dayLabelText = cumulativeDays
            end
            local dayLabel = dayBlock:createLabel({text = tostring(dayLabelText)})
            local color
            if (outOfMonth == true ) then
                color = {0.250, 0.250, 0.250}
                if (beforeMonth == true) then
                    local year = date.year
                    if (lastYear) then
                    year =  date.year - 1
                    end
                    dayBlock:register("mouseClick", function () createCalendarPane({day = dayLabelText, month = (date.month - 1) % 12, year = year })end)
                else
                    local year = date.year
                    if (nextYear) then
                        year = date.year + 1
                    end
                    dayBlock:register("mouseClick", function () createCalendarPane({day = dayLabelText, month = (date.month +1) % 12, year = year})end)
                end
            elseif (dayLabelText == date.dayOfTheMonth) then
                color = {0.624, 0.000, 0.000}
            elseif(tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(dayLabelText)] ~= nil) then
                color = {0.000, 0.000, 0.624}
                dayBlock:register("mouseClick", function() createCalendarPane({day = dayLabelText, month = date.month, year = date.year})end)
            else
                color = {0.000, 0.000, 0.000}
                dayBlock:register("mouseClick", function () createCalendarPane({day = dayLabelText, month = date.month, year = date.year})end)
            end
            dayLabel.color = color
            dayLabel.wrapText = true
            dayLabel.justifyText = "center"
        end
    end
    local dayLabel = calendarPane:createLabel({text = dayNames[date.dayOfTheWeek] .. " the " .. date.dayOfTheMonth .. date.dayOfTheMonthOrdinal })
    dayLabel.color = {0.624, 0.000, 0.000}
    local notesPane = calendarPane:createParagraphInput({id = init.notesPaneID})
    notesPane.autoHeight = false
    notesPane.heightProportional = 1
    notesPane.autoWidth = false
    notesPane.widthProportional = 1
    local textInput = notesPane:findChild(init.textInputID)
    textInput.color = {0.000, 0.000, 0.000}
    textInput.wrapText = true
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.dayOfTheMonth)] ~= nil) then
        notesPane.text = tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.dayOfTheMonth)]
    end
    notesPane:register("mouseClick", function()
        tes3ui.acquireTextInput(notesPane)
        journalKeybindDisabled = true
        disableJournalCloseKeybind()
    end)
    menuJournal:updateLayout()
end



local function onMenuJournalCreated(e)
    if (e.newlyCreated ~= true) then
        return
    end
    local menuJournal = e.element
    local menuOptionsButton = menuJournal:findChild(init.menuOptionsButtonID)
    local menuTopics = menuJournal:findChild(init.menuTopicsID)
    local menuQuests = menuJournal:findChild(init.menuQuestsID)
    local menuCancel = menuJournal:findChild(init.menuCancelID)
    local buttonContainer = menuTopics.parent
    local menuTopicsReplacement
    local menuQuestsReplacement
    local calendarButton
    local tabActive = "topics"

    menuOptionsButton:register("mouseClick", function(eventData)
        eventData.source:forwardEvent(eventData)
        if (tabActive == "calendar") then
            createCalendarPane({})
        end
    end)
    menuTopics.visible = false
    menuTopics.disabled = true
    menuTopicsReplacement = buttonContainer:createImageButton({id = init.menuTopicsReplacementID,
        idle = "textures/Tx_menubook_topics_idle.tga",
        over = "textures/Tx_menubook_topics_over.tga",
        pressed = "textures/Tx_menubook_topics_pressed.tga"
    })
    menuTopicsReplacement.children[1].autoWidth = false
    menuTopicsReplacement.children[1].width = 50
    menuTopicsReplacement.children[2].autoWidth = false
    menuTopicsReplacement.children[2].width = 50
    menuTopicsReplacement.children[3].autoWidth = false
    menuTopicsReplacement.children[3].width = 50
    menuTopicsReplacement.autoWidth = false
    menuTopicsReplacement.widthProportional = 1
    menuTopicsReplacement.childAlignX = 0.5
    menuTopicsReplacement.disabled = true
    menuTopicsReplacement.children[1].visible = false
    menuTopicsReplacement.children[3].visible = true
    menuTopicsReplacement:register("mouseClick", function(eventData)
        tabActive = "topics"
        calendarButton.disabled = false
        menuQuestsReplacement.disabled = false
        calendarButton.children[1].visible = true
        calendarButton.children[3].visible = false
        menuQuestsReplacement.children[1].visible = true
        menuQuestsReplacement.children[3].visible = false

        saveNotes()
        menuTopicsReplacement.children[1].visible = false
        menuTopicsReplacement.children[3].visible = true
        menuTopicsReplacement.disabled = true
        menuTopics:triggerEvent("mouseClick")
    end)

    calendarButton = buttonContainer:createImageButton({id = init.calendarButtonID,
    idle = "textures/calendar/Calendar_Button_Idle.dds",
    over = "textures/calendar/Calendar_Button_Over.dds",
    pressed = "textures/calendar/Calendar_Button_Pressed.dds",})
    calendarButton.children[1].autoWidth = false
    calendarButton.children[1].width = 74
    calendarButton.children[2].autoWidth = false
    calendarButton.children[2].width = 74
    calendarButton.children[3].autoWidth = false
    calendarButton.children[3].width = 74
    calendarButton.autoWidth = false
    calendarButton.widthProportional = 1
    calendarButton.childAlignX = 0.5
    calendarButton:register("mouseClick", function() tabActive = "calendar" createCalendarPane({})end)

    menuQuests.visible = false
    menuQuests.disabled = true
    menuQuestsReplacement = buttonContainer:createImageButton({id = init.menuQuestsReplacementID,
        idle = "textures/Tx_menubook_quests_idle.dds",
        over = "textures/Tx_menubook_quests_over.dds",
        pressed ='textures/Tx_menubook_quests_pressed.dds'
    })
    menuQuestsReplacement.children[1].autoWidth = false
    menuQuestsReplacement.children[1].width = 56
    menuQuestsReplacement.children[2].autoWidth = false
    menuQuestsReplacement.children[2].width = 56
    menuQuestsReplacement.children[3].autoWidth = false
    menuQuestsReplacement.children[3].width = 56
    menuQuestsReplacement.autoWidth = false
    menuQuestsReplacement.widthProportional = 1
    menuQuestsReplacement.childAlignX = 0.5
    menuQuestsReplacement:register("mouseClick", function(eventData)
        tabActive = "quests"
        calendarButton.disabled = false
        menuTopicsReplacement.disabled = false
        calendarButton.children[1].visible = true
        calendarButton.children[3].visible = false
        menuTopicsReplacement.children[1].visible = true
        menuTopicsReplacement.children[3].visible = false
        saveNotes()
        menuQuestsReplacement.children[1].visible = false
        menuQuestsReplacement.children[3].visible = true
        menuQuestsReplacement.disabled = true
        menuQuests:triggerEvent("mouseClick")
    end)

    menuCancel.children[1].autoWidth = false
    menuCancel.children[1].width = 58
    menuCancel.children[2].autoWidth = false
    menuCancel.children[2].width = 58
    menuCancel.children[3].autoWidth = false
    menuCancel.children[3].width = 58
    menuCancel:register("mouseClick", function(eventData)
        calendarButton.disabled = false
        calendarButton.children[1].visible = true
        calendarButton.children[3].visible = false
        saveNotes()
        eventData.source:forwardEvent(eventData)
    end)
    menuJournal:updateLayout()
end

event.register("uiActivated", onMenuJournalCreated, { filter = "MenuJournal" })


local function onInit()
    init = {
        menuJournalID = tes3ui.registerID("MenuJournal"),
        menuOptionsButtonID = tes3ui.registerID("MenuBook_button_take"),
        bookmarkID = tes3ui.registerID("MenuJournal_bookmark"),
        menuTopicsID = tes3ui.registerID("MenuJournal_button_bookmark_topics"),
        menuTopicsReplacementID = tes3ui.registerID("MenuJournal_button_bookmark_topics_replacement"),
        menuQuestsID = tes3ui.registerID("MenuJournal_button_bookmark_quests"),
        menuQuestsReplacementID = tes3ui.registerID("MenuJournal_button_bookmark_quests_replacement"),
        menuCancelID = tes3ui.registerID("MenuJournal_button_bookmark_cancel"),
        menuBookmarkLayoutID = tes3ui.registerID("MenuJournal_bookmark_layout"),
        topicsButtonIdleID = tes3ui.registerID("MenuJournal_button_bookmark_topics_idle"),
        topicsButtonOverID = tes3ui.registerID("MenuJournal_button_bookmark_topics_over"),
        topicsButtonPressedID = tes3ui.registerID("MenuJournal_button_bookmark_topics_pressed"),
        questsButtonIdleID = tes3ui.registerID("MenuJournal_button_bookmark_quests_idle"),
        questsButtonOverID = tes3ui.registerID("MenuJournal_button_bookmark_quests_over"),
        questsButtonPressedID = tes3ui.registerID("MenuJournal_button_bookmark_quests_pressed"),
        questsActiveButtonID = tes3ui.registerID("MenuJournal_button_bookmark_quests_active"),
        questsAllButtonID = tes3ui.registerID("MenuJournal_button_bookmark_quests_all"),
        calendarButtonID = tes3ui.registerID("MenuJournal_button_bookmark_calendar"),
        calendarPaneID = tes3ui.registerID("MenuJournal_calendar_pane"),
        dateHolderID = tes3ui.registerID("MenuJournal_calendar_dateholder"),
        calendarBlockID = tes3ui.registerID("MenuJournal_calendar_block"),
        notesPaneID = tes3ui.registerID("MenuJournal_calendar_notespane"),
        textInputID = tes3ui.registerID("PartParagraphInput_text_input"),
        weeks = {
            tes3ui.registerID("MenuJournal_calendar_week1"),
            tes3ui.registerID("MenuJournal_calendar_week2"),
            tes3ui.registerID("MenuJournal_calendar_week3"),
            tes3ui.registerID("MenuJournal_calendar_week4"),
            tes3ui.registerID("MenuJournal_calendar_week5"),
            tes3ui.registerID("MenuJournal_calendar_week6")
        },
        days = {
            tes3ui.registerID("MenuJournal_calendar_day1"),
            tes3ui.registerID("MenuJournal_calendar_day2"),
            tes3ui.registerID("MenuJournal_calendar_day3"),
            tes3ui.registerID("MenuJournal_calendar_day4"),
            tes3ui.registerID("MenuJournal_calendar_day5"),
            tes3ui.registerID("MenuJournal_calendar_day6"),
            tes3ui.registerID("MenuJournal_calendar_day7"),
        }
    }
end

event.register("initialized", onInit )