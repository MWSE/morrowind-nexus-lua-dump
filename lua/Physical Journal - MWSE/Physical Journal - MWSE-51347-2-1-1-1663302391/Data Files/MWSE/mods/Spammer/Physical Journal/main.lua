local mod = {
    name = "Physical Journal",
    ver = "2.1.1",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local tool = false
local skip = false
local journal
local newGame = false
local exclude = include("Spammer\\Physical Journal\\interop")
--local soundskip = false
local cf = mwse.loadConfig(mod.name, mod.cf)

---@param e loadedEventData
event.register("loaded", function(e)
    if e.newGame then
        newGame = true
        return
    end
    if not tes3.player then
        return
    end
    journal.name = tes3.player.object.name:sub(1, 20).."'s Journal"
    if (#tes3.player.object.name > 20) then tool = true end
    if tes3.player.data.spa_IJ_alreadyGaveYou then
        return
    end
    local pcInventory = tes3.player.object.inventory
    for _,stack in pairs(pcInventory) do
        if stack.object == journal then
            return
        end
    end
    tes3.addItem({reference = tes3.player, item = journal, playSound = false})
    tes3.player.data.spa_IJ_alreadyGaveYou = true
end)

event.register("uiObjectTooltip", function(e)
    if not tool then return end
    if not tes3.player then return end
    if e.object ~= journal then return end
    local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = tes3.player.object.name.."'s Journal"
end)

---@param e equipEventData
event.register("equip", function(e)
    if e.reference ~= tes3.player then return end
    if e.item == journal then
		if tes3.player.data.NCN_knownIDs then
			tes3.player.data.NCN_knownIDs[journal.id] = true
		end
        skip = true
---@diagnostic disable-next-line: undefined-field
        tes3ui.showJournal()
        return false
    end
end)

---@param e activateEventData
event.register("activate", function(e)
    if e.activator ~= tes3.player then return end
    if tes3ui.menuMode() then
        return
    end
    if e.target.id == journal.id then
        skip = true
    if tes3.player.data.NCN_knownIDs then
        tes3.player.data.NCN_knownIDs[journal.id] = true
     end
---@diagnostic disable-next-line: undefined-field
        tes3ui.showJournal()
        return false
    end
end)

---@param e keybindTestedEventData
event.register("keybindTested", function(e)
    if e.transition ~= tes3.keyTransition.down then
        return
    end
    if not (e.result) then
        return
    end
    if not skip then
        if cf.onOff and (tes3.getItemCount{item = "spa_IJ_Journal", reference = "player"} ~= 0) then
            return
        end
        if cf.onOff then
            tes3.messageBox("You don't have your Journal!")
        end
        e.result = false
    end
end, {filter = tes3.keybind.journal, priority = 100})


local function takes(page)
    local bookmark = page:findChild("MenuJournal_bookmark")
    local take = page:createImageButton({id = "spa_takeJournal", idle = "Textures\\tx_menubook_take_idle.tga", over = "Textures\\tx_menubook_take_over.tga", pressed = "Textures\\tx_menubook_take_pressed.tga"})
    take.absolutePosAlignY = 0.97
    take.absolutePosAlignX = 0.07
    take.visible = false
            page:register(tes3.uiEvent.update, function()
                take.visible = bookmark.visible
            end)
    take:register("mouseClick", function()
        tes3.addItem({reference = tes3.player, item = "spa_IJ_Journal", playSound = false})
        tes3.getReference("spa_IJ_Journal"):delete()
        tes3ui.closeJournal()
    end)
end



---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    if (tes3.getItemCount{reference = tes3.player, item = "spa_IJ_Journal"} ~= 0) and cf.onOff then
        skip = true
    end
    if skip then
        if tes3.getItemCount{reference = tes3.player, item = "spa_IJ_Journal"} == 0 then
            takes(e.element)
        end

        if tes3.isLuaModActive("Spammer\\The Bibliophile") and not table.find(tes3.player.data.spammer_booklist,"spa_IJ_Journal") then
            table.insert(tes3.player.data.spammer_booklist,"spa_IJ_Journal")
        end

        if tes3.isLuaModActive("mer\\BookWorm") then
            for _, book in pairs(tes3.player.data.bookIndicator.booksRead) do
                if book.id == "spa_IJ_Journal" then
                    skip = false
                    return
                end
            end
            table.insert(tes3.player.data.bookIndicator.booksRead,{name = "Journal", id = "spa_IJ_Journal"})
        end
        skip = false
        return
    end
end, {filter = "MenuJournal", priority = 100})

event.register("journal", function()
    if tes3.isLuaModActive("Spammer\\The Bibliophile") then
        table.removevalue(tes3.player.data.spammer_booklist,"spa_IJ_Journal")
    end

    if tes3.isLuaModActive("mer\\BookWorm") then
        for i, book in pairs(tes3.player.data.bookIndicator.booksRead) do
            if book.id == "spa_IJ_Journal" then
                table.remove(tes3.player.data.bookIndicator.booksRead, i)
            end
        end
    end
end)


event.register("enterFrame", function()
    if not newGame then
        return
    end
    if #exclude.esp ~= 0 then
        for _,esp in ipairs(exclude.esp) do
            if tes3.isModActive(esp) then
                print(string.format("Mod %s found! Aborting Physical Journal Chargen!", esp))
                tes3.player.data.spa_IJ_alreadyGaveYou = true
                newGame = false
                break
            end
        end
    end

    if #exclude.lua ~= 0 then
        for _,lua in ipairs(exclude.lua) do
            if tes3.isLuaModActive(lua) then
                print(string.format("Mod %s found! Aborting Physical Journal Chargen!", lua))
                tes3.player.data.spa_IJ_alreadyGaveYou = true
                newGame = false
                break
            end
        end
    end

    if tes3.player.data.spa_IJ_alreadyGaveYou then
        return
    end

    if tes3.getItemCount{reference = "player", item = "spa_IJ_Journal"} > 0 then
        return
    end

    if tes3.getItemCount{reference = "player", item = "bk_a1_1_caiuspackage"} == 0 then
        return
    end
    tes3.addItem({reference = "player", item = journal})
    journal.name = tes3.player.object.name:sub(1,20).."'s Journal"
    if (#tes3.player.object.name > 20) then tool = true end
    tes3.player.data.spa_IJ_alreadyGaveYou = true
    newGame = false
end)


event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Enable the use of the Journal KeyBind?")
    category0:createOnOffButton{label = "Yes/No", description = "If turned of, pressing the Journal keybind won't do anything at all, even if you have the Journal in your inventory. If you need that key for something else...", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}
end)

event.register("initialized", function()
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
journal = tes3.createObject({
    objectType = tes3.objectType.book,
    getIfExists = true,
    id = "spa_IJ_Journal",
    mesh = "KO_Book15.nif",
    icon = "Book15.tga",
    weight = 3,
    value = 100,
    name = "Journal",
	scale = 0.5})
end, {priority = -1000})

