local renameMenu = tes3ui.registerID("Renamer_KNDI:Menu")
local renameInputer = tes3ui.registerID("Rename_KNDI:Inputer")
local colorTable
local junk = {
    ["1095062083"] = "Crea",
    ["1598246990"] = "NPC_",
    ["1380929348"] = "Door",
    ["1414418243"] = "Cont",
    ["1230259009"] = "Acti"
}
local torename = ""
local target
local config
local dial = {}
local X
local Y
local function cMen(k)
    if not config.allowHotkey or not config.modActive then
        return
    end
    if not tes3.worldController.inputController:isKeyDown(config.modiHotkey.keyCode) and config.allowModi then
        return
    end
    if not tes3.worldController.inputController:isKeyDown(config.mainHotkey.keyCode) then
        return
    end
    local isActiveMenu = tes3ui.findMenu(renameMenu)
    local info
    if isActiveMenu then
        torename = tes3ui.findMenu(renameMenu):findChild(renameInputer).text
        if torename:startswith("!info:") then
            info = torename:gsub("!info:", "")
            if not target.data.rename_new_name then
                torename = target.baseObject.name
            else
                torename = target.data.rename_new_name[tostring(target)][1]
            end
        else
            if not target.data.rename_new_name then
                info = ""
            else
                info = target.data.rename_new_name[tostring(target)][2]
            end
        end
    end
    if target and target.data then
        if not info then
            if target.data.rename_new_name then
                info = target.data.rename_new_name[tostring(target)][2]
            else
                info = ""
            end
        end

        target.data.rename_new_name = {[tostring(target)] = {torename, info, target.baseObject.name}}

        target.modified = true
    end
    target = nil
    target = tes3.getPlayerTarget() --if in menu this wont get anything
    if target and target.stackSize > 1 then
        tes3.messageBox("Cannot rename stack of items")
        target = nil
        return
    elseif target and string.startswith(target.object.id, "Gold_") then
        tes3.messageBox("Cannot rename gold")
        target = nil
        return
    end
    if tes3.onMainMenu() then
        return
    end
    if not target then
        if isActiveMenu then
            X = isActiveMenu.positionX
            Y = isActiveMenu.positionY
            isActiveMenu:destroy()
            tes3ui.leaveMenuMode()
        end
        return
    end

    local defName
    if target and target.data and target.data.rename_new_name then
        defName = target.data.rename_new_name[tostring(target)][1]
    else
        defName = target.object.name
    end

    local menu = tes3ui.createMenu {id = renameMenu, dragFrame = true, fixedFrame = false}
    menu.text = string.format("Rename Window")
    menu.width = 290
    menu.height = 410
    menu.minWidth = 290
    menu.minHeight = 410
    menu.maxWidth = 290
    menu.maxHeight = 410
    menu.positionX = X or menu.width * -2
    menu.positionY = Y or menu.height - 100
    menu.alpha = tes3.worldController.menuAlpha
    menu.flowDirection = "top_to_bottom"

    local blockBar = menu:createBlock {}
    --blockBar.autoWidth = true
    blockBar.width = 290
    blockBar.autoHeight = true
    blockBar.flowDirection = "top_to_bottom"
    blockBar.widthProportional = 1.0
    blockBar.borderAllSides = 1

    local input = blockBar:createParagraphInput {id = renameInputer}
    input.font = 1
    input.widget.lengthLimit = nil
    --input.widget.eraseOnFirstKey = true
    input.text = defName or target.object.name
    input.wrapText = true
    input:register(
        "keyPress",
        function(e)
            input:forwardEvent(e)
            local key = e.data0
            --tes3.messageBox(input.text)
        end
    )

    blockBar:register(
        "mouseClick",
        function()
            tes3ui.acquireTextInput(input)
        end
    )

    input.consumeMouseEvents = false
    menu.repeatKeys = true

    local buttonBar = menu:createBlock {}
    buttonBar.flowDirection = "left_to_right"
    buttonBar.autoHeight = true
    buttonBar.width = 290
    buttonBar.widthProportional = 1.0
    buttonBar.borderAllSides = 1

    local button = buttonBar:createButton {}
    button.text = "Clear"
    button.widget.state = 1
    button:register(
        "mouseClick",
        function()
            input.text = ""
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Clear text from input/Rename object"
        end
    )

    local button2 = buttonBar:createButton {}
    button2.text = "Paste"
    button2.widget.state = 1
    button2:register(
        "mouseClick",
        function()
            input.text = input.text .. os.getClipboardText()
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button2:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Paste clipboard text to input"
        end
    )

    local button3 = buttonBar:createButton {}
    button3.text = "Reset"
    button3.widget.state = 1
    button3:register(
        "mouseClick",
        function()
            if input.text:startswith("!info:") and target.data.rename_new_name then
                target.data.rename_new_name[tostring(target)][2] = ""
                input.text = "!info:"
            elseif target.data.rename_new_name then
                target.data.rename_new_name[tostring(target)][1] = target.data.rename_new_name[tostring(target)][3]
                input.text = target.baseObject.name
            else
                input.text = ""
            end
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button3:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Reset object name\nRemoves info if input starts with !info:"
        end
    )

    local button4 = buttonBar:createButton {}
    button4.text = "Info"
    button4.widget.state = 1
    button4:register(
        "mouseClick",
        function()
            if not target.data.rename_new_name then
                input.text = "!info:"
            else
                input.text = "!info:" .. target.data.rename_new_name[tostring(target)][2]
            end
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button4:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Create/edit info for object"
        end
    )

    local buttonBar2 = menu:createBlock {}
    buttonBar2.flowDirection = "left_to_right"
    buttonBar2.autoHeight = true
    buttonBar2.width = 290
    buttonBar2.widthProportional = 1.0
    buttonBar2.borderAllSides = 1

    local button5 = buttonBar2:createButton {}
    button5.text = "Copy"
    button5.widget.state = 1
    button5:register(
        "mouseClick",
        function()
            os.setClipboardText(input.text)
            tes3.messageBox("Copied to Clipboard")
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button5:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Copy text to clipboard"
        end
    )

    local button6 = buttonBar2:createButton {}
    button6.text = "Date1"
    button6.widget.state = 1
    button6:register(
        "mouseClick",
        function()
            input.text =
                input.text ..
                tes3.findGlobal("Day").value ..
                    "-" .. tes3.findGMST(tes3.findGlobal("Month").value).value .. "-" .. tes3.findGlobal("Year").value
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button6:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Paste current date (game)"
        end
    )

    local button7 = buttonBar2:createButton {}
    button7.text = "Date2"
    button7.widget.state = 1
    button7:register(
        "mouseClick",
        function()
            input.text = input.text .. os.date("%d-%b-%Y")
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button7:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Paste current date (real)"
        end
    )

    local button8 = buttonBar2:createButton {}
    button8.text = "Time1"
    button8.widget.state = 1
    button8:register(
        "mouseClick",
        function()
            local h, m, ap =
                math.floor(tes3.findGlobal("GameHour").value),
                math.floor(60 * (tes3.findGlobal("GameHour").value - math.floor(tes3.findGlobal("GameHour").value))),
                "AM"
            if h > 12 then
                h = h - 12
                ap = "PM"
            end
            h = tostring(h)
            m = tostring(m)
            if #h == 1 then
                h = "0" .. h
            end
            if #m == 1 then
                m = "0" .. m
            end
            input.text = input.text .. h .. ":" .. m .. " " .. ap
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button8:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Paste current time (game)"
        end
    )

    local buttonBar3 = menu:createBlock {}
    buttonBar3.flowDirection = "left_to_right"
    buttonBar3.autoHeight = true
    buttonBar3.width = 290
    buttonBar3.widthProportional = 1.0
    buttonBar3.borderAllSides = 1

    local button9 = buttonBar3:createButton {}
    button9.text = "Time2"
    button9.widget.state = 1
    button9:register(
        "mouseClick",
        function()
            input.text = input.text .. os.date("%I:%M %p")
            menu:updateLayout()
            tes3.getSound("book page2"):play()
        end
    )
    button9:register(
        "mouseOver",
        function()
            local tip = tes3ui.createTooltipMenu()
            tip.autoWidth = true
            tip.autoHeight = true
            tip.maxWidth = 440
            tip.flowDirection = "top_to_bottom"
            local tooltiptext = tip:createLabel {}
            tooltiptext.text = "Paste current time (real)"
        end
    )

    tes3ui.enterMenuMode(renameMenu)
    menu:updateLayout()
    tes3ui.acquireTextInput(input)
end
event.register("keyDown", cMen)

local function leave()
    local mn = tes3ui.findMenu(renameMenu)
    if mn then
        mn:destroy()
        tes3ui.leaveMenuMode()
        if target.data.rename_new_name then
            torename = target.data.rename_new_name[tostring(target)][1]
        else
            torename = target.object.name
        end
    end
end
event.register("menuExit", leave)

local function hackTooltip(e)
    if not config.modActive then
        return
    end
    local info
    local t = e.tooltip
    local ref = e.reference or e.object
    local references = e.reference
    ref = tostring(ref)
    local itemdata = e.itemData
    local daname

    if itemdata and itemdata.data and itemdata.data.rename_new_name then
        daname = itemdata.data.rename_new_name[ref]
    elseif references and references.data and references.data.rename_new_name then
        daname = references.data.rename_new_name[tostring(references)]
    else
        return
    end

    if not daname then
        return
    end
    local count = 0
    local add = 1
    for name in table.traverse(t.children) do
        if name.name == "HelpMenu_icon" then
            count = count + add
        end
        if name.text and #name.text > 0 and name.name == "HelpMenu_name" then
            if daname[2] and #daname[2] > 0 then
                info = daname[2]
                name.parent.flowDirection = "top_to_bottom"
                if info then
                    for w in info:gmatch("[^\n]*%S+") do
                        count = count + 1
                        local i, f = w:find("^![,%w%.]+[%p]")
                        local tab = {}
                        local color
                        if i and f then
                            for n in (w:sub(i + 1, f - 1):gsub(",", " ")):gmatch("%S+") do
                                table.insert(tab, tonumber(n))
                            end
                            color = w:sub(i + 1, f - 1)
                            color = colorTable[color]
                            if color then
                                w = w:sub(f + 1, #w)
                            elseif type(tab[1]) == "number" and #tab == 3 then
                                color = tab
                                w = w:sub(f + 1, #w)
                            else
                                color = colorTable["normal"]
                            end
                        else
                            color = colorTable["normal"]
                        end

                        local b = name.parent:createBlock {}
                        b.borderAllSides = 3
                        b.width = name.parent.width
                        b.height = name.parent.height
                        b.minWidth = name.parent.minWidth
                        b.minHeight = name.parent.minHeight
                        b.maxWidth = name.parent.maxWidth
                        b.maxHeight = name.parent.maxHeight
                        b.autoHeight = true
                        b.autoWidth = true
                        local l = b:createLabel {}
                        l.wrapText = true
                        l.justifyText = "center"
                        l.color = color
                        l.text = w
                        if e.object and e.object.objectType and not junk[tostring(e.object.objectType)] then
                            t:getContentElement():reorderChildren(0 + count, b, -1)
                        end
                    end
                end
            end

            local newName = daname[1]
            local i, f = newName:find("^![,%w%.]+[%p]")
            local tab = {}
            local colorH
            if i and f then
                for n in (newName:sub(i + 1, f - 1):gsub(",", " ")):gmatch("%S+") do
                    table.insert(tab, tonumber(n))
                end
                colorH = newName:sub(i + 1, f - 1)
                colorH = colorTable[colorH]
                if colorH then
                    newName = newName:sub(f + 1, #newName)
                elseif type(tab[1]) == "number" and #tab == 3 then
                    colorH = tab
                    newName = newName:sub(f + 1, #newName)
                else
                    colorH = colorTable["header"]
                end
            else
                colorH = colorTable["header"]
            end

            name.color = colorH
            name.text = newName
            name:getTopLevelMenu():updateLayout()
        end
    end
end
event.register("uiObjectTooltip", hackTooltip)

local function hackDialog(e)
    if not config.modActive then
        return
    end
    local element = e.element or tes3ui.findMenu("MenuDialog")
    local actor = tes3ui.getServiceActor().reference
    if not actor.data.rename_new_name then
        return
    end
    local data = actor.data.rename_new_name[tostring(actor)]
    if not actor then
        return
    end
    if not (element):findChild("PartDragMenu_title") then
        return
    end

    local function hackInfo()
        if not tes3ui.findMenu("MenuDialog") then
            event.unregister("enterFrame", hackInfo)
        end
        --if element and (element):findChild("PartDragMenu_title") then
        for name in table.traverse(element.children) do
            if name.text == data[3] then
                local _, f = data[1]:find("^![,%w%.]+[%p]")
                if _ and f then
                    name.text = data[1]:sub(f + 1, #data[1])
                else
                    name.text = data[1]
                end
            end
        end
        --end
    end

    event.register("enterFrame", hackInfo)
end
event.register("uiActivated", hackDialog, {filter = "MenuDialog"})

local function hackText(e)
    if not tes3ui.findMenu("MenuDialog") then
        return
    end
    local references = tes3ui.getServiceActor().reference
    local newName
    local backup
    if dial[e.info.id] and references and references.data and references.data.rename_new_name then
        newName = references.data.rename_new_name[tostring(references)][1]
        local i, f = newName:find("^![,%w%.]+[%p]")
        if i and f then
            newName = newName:sub(f + 1, #newName)
        end
        backup = dial[e.info.id]
        dial[e.info.id] = dial[e.info.id]:gsub("%%[nN]ame", newName)
        e.text = dial[e.info.id]
        dial[e.info.id] = backup
    end
end
event.register("infoGetText", hackText)

local function getText()
    colorTable = {
        ["red"] = tes3ui.getPalette("health_color"),
        ["header"] = tes3ui.getPalette("header_color"),
        ["normal"] = tes3ui.getPalette("normal_color"),
        ["blue"] = tes3ui.getPalette("magic_color"),
        ["green"] = tes3ui.getPalette("fatigue_color"),
        ["yellow"] = {1, 1, 0},
        ["skyblue"] = {0, 1, 1},
        ["black"] = {0, 0, 0},
        ["white"] = {1, 1, 1},
        ["orange"] = {1, 0.5, 0},
        ["purple"] = {0.5, 0, 1}
    }
    for k, v in pairs(tes3.dataHandler.nonDynamicData.dialogues) do
        if v.type == 0 and v.id == "Background" then
            for i = 1, #v.info do
                if (v.info[i].text):match("%%name") or (v.info[i].text):match("%%Name") then
                    dial[v.info[i].id] = (v.info[i].text)
                end
            end
        end
    end
end
event.register("initialized", getText)

event.register(
    "modConfigReady",
    function()
        require("kindi.simple renamer and coloring.mcm")
        config = require("kindi.simple renamer and coloring.config")
    end
)
