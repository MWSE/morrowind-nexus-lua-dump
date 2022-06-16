local mod = {
    name = "MWSE Logger",
    ver = "1.3",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false, isSuperDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield2 = "10000", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local myTimer

local function createMenu()
	local parent = tes3ui.createMenu{id = "spa_loggerMenu", fixedFrame = true, modal = false}
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	parent.width = viewportWidth/3
	parent.height = viewportHeight/3
	parent.disabled = true
	local rect = parent:createRect{id = "spa_logger"}
    parent.absolutePosAlignX = cf.slider/100
    parent.absolutePosAlignY = cf.sliderpercent/100
	rect.autoHeight = true
	rect.width = viewportWidth/3
	rect.maxHeight = viewportHeight/3
	rect.flowDirection = "top_to_bottom"
	local scrollPane = rect:createVerticalScrollPane({ id = "ScrollContents" })
	scrollPane.autoHeight = true
	scrollPane.autoWidth = true
	scrollPane.maxHeight = rect.maxHeight-25
	scrollPane.maxWidth = rect.width
	scrollPane.minHeight = rect.maxHeight-25
	local label = scrollPane:createLabel{id = "spa_mwselog", text = ""}
	label.wrapText = true
	local text = rect:createTextInput{placeholderText = "Search..."}
	text.height = 25
	text.width = rect.width
	text:registerAfter("textUpdated", function(e)
		if myTimer then myTimer:pause() end
		local search = e.source.text:lower()
		local t = {}
    	for line in io.lines("mwse.log") do
			if line and string.find(line:lower(), search) then
        	t[#t+1] = line.."\n"
			end
    	end
		label.text = table.concat(t)
		scrollPane.widget.positionY = 0
	end)
	text:registerAfter("textCleared", function()
		if myTimer then myTimer:resume() end
		local scrollContents = scrollPane:getContentElement()
		scrollPane.widget.positionY = scrollContents.height
	end)
	parent.visible = false
end


event.register("initialized", function()
	createMenu()
end)

event.register("loaded", function()
	local menu = tes3ui.findMenu("spa_loggerMenu")
	if not menu then
		createMenu()
	end
end)
---comment
---@param e table|keyDownEventData
event.register("keyDown", function(e)
	if not (tes3.isKeyEqual{actual = {keyCode = e.keyCode, isShiftDown = e.isShiftDown, isAltDown = e.isAltDown, isControlDown = e.isControlDown, isSuperDown = e.isSuperDown}, expected = {keyCode = cf.key.keyCode, isShiftDown = cf.key.isShiftDown, isAltDown = cf.key.isAltDown, isSuperDown = cf.key.isSuperDown, isControlDown = cf.key.isControlDown}}) then
        return
    end
	local menu = tes3ui.findMenu("spa_loggerMenu")
	if not menu then return end
	local rect = menu:findChild("spa_logger")
	if not rect then return end
	menu.visible = not menu.visible
	if menu.visible then
		tes3ui.moveMenuToFront(menu)
		local label = rect:findChild("spa_mwselog")
		myTimer = timer.start{type = timer.real, duration = 0.5, iterations = -1, callback = function()
            menu.absolutePosAlignX = cf.slider/100
            menu.absolutePosAlignY = cf.sliderpercent/100
			local file = io.open("mwse.log", "r")
			if not file then label.text = "MWSE.log not found!" return end
			io.input(file)
			local limit = tonumber(cf.textfield2)
			file:seek("end", -limit)
			label.text = io.read("*a")
			io.close(file)
			local scrollPane = menu:findChild("ScrollContents")
			local scrollContents = scrollPane:getContentElement()
			local height = scrollContents.height
			menu:updateLayout()
			scrollPane.widget:contentsChanged()
			if scrollContents.height > height then
				scrollPane.widget.positionY = scrollContents.height
			end
		end}
	elseif myTimer then
		myTimer:cancel()
		myTimer = nil
	end
end)


event.register("mouseButtonDown", function()
	local menu = tes3ui.findMenu("spa_loggerMenu")
	if not menu then return end
	if not menu.visible then return end
	if not tes3ui.menuMode() then return end
	menu.visible = false
	if myTimer then
		myTimer:cancel()
		myTimer = nil
	end
end, {filter = 1})

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Key Binder:")

    category0:createKeyBinder{label = "", description = "Configure the key press needed to show the menu.", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false, isSuperDown = false}}}

	local category = page:createCategory("Maximum number of characters displayed:")
	category:createTextField{
        label = " ",description = "Unfortunately, if the file is too long, the menu doesn't work well. So it will only display the last x characters - You got to chose the value of x here.", variable = mwse.mcm.createTableVariable{id = "textfield2", table = cf, numbersOnly = true,}}
    local category2 = page:createCategory("Menu Position:")
    category2:createSlider{label = "Horizontal Position : %s%%", description = "Horizontal position of the menu.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    category2:createSlider{label = "Vertical Position : %s%%", description = "Vertical position of the menu", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}


end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

