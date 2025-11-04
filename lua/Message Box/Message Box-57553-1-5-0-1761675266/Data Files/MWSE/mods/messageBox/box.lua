local func = require("messageBox.common")
local log = mwse.Logger.new()


local box = {}

box.config = require("messageBox.config") --Message Box config vars


--Creates the message box.
function box.createBox()
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	local width = tonumber(box.config.width)
	local height = tonumber(box.config.height)

	local menu = tes3ui.createMenu({ id = "kl_msgBox_menu", dragFrame = true })
	menu.minHeight = 87
	menu.minWidth = 237
	if box.config.minSize then
		menu.minHeight = height
		menu.minWidth = width
	end
	menu.height = height
	menu.width = width
	menu.text = box.config.titleText
	menu.positionY = (viewportHeight * 0.5)
	menu.positionX = (menu.width / 2) * -1
	if box.config.position == "bottom" then
		menu.positionY = (viewportHeight * -0.5) + menu.height
	elseif box.config.position == "tLeft" then
		menu.positionX = menu.positionX + (viewportWidth * -0.5) + (menu.width / 2)
	elseif box.config.position == "tRight" then
		menu.positionX = menu.positionX + (viewportWidth * 0.5) - (menu.width / 2)
	end
	menu.alpha = box.config.alpha

	local pane = menu:createVerticalScrollPane({})
	pane.autoHeight = true
	pane.width = width - 97 --100 less than menu width
	pane.height = height - 47 --50 less than menu height
	pane.minHeight = 37

	box.menu = menu
	box.pane = pane
	box.num = 1
	box.time = 0
 
	local label = pane:createTextSelect({text = box.ascii[math.random(1, #box.ascii)]})
	label.widget.idle = box.colors[math.random(1, #box.colors)]

	box.modData = func.getModDataP()
	label.widget.over = box.colors[math.random(1, #box.colors)]

	local day = func.i18n(string.format("msgBox.weekDay.%d", (tes3.worldController.daysPassed.value + 3) % 7 + 1))
	local abb = func.i18n(string.format("msgBox.dayAbb.%d", tes3.worldController.day.value))
	local dateMsg = pane:createLabel({ text = "~  " .. day .. ", " .. tes3.worldController.day.value .. "" .. abb .. " " .. tes3.findGMST(tes3.worldController.month.value).value .. "  ~" })
	dateMsg.color = box.colors[1]
	dateMsg.borderBottom = 12
	dateMsg.borderTop = 12
	dateMsg.wrapText = true
	dateMsg.justifyText = tes3.justifyText.center

	menu:findChild("PartDragMenu_left_title_block"):destroy()
	menu:findChild("PartDragMenu_right_title_block"):destroy()
	menu:findChild("PartDragMenu_title_tint").maxHeight = 17
	menu.visible = box.modData.visible
	menu:updateLayout()
	log:debug("Message Box created.")

	if box.config.msgTimer then
		timer.start({ type = timer.real, duration = 1, iterations = -1, persist = false, callback =
		function()
			if box.menu then
				box.time = box.time + 1
				if box.time >= box.config.msgTime then
					box.menu.visible = false
				end
			end
		end })
	end
end

box.colors = {
	[1] = { 1.0, 1.0, 1.0 }, --White
	[2] = { 0.6, 0.2, 0.2 }, --Health Red
	[3] = { 0.21, 0.27, 0.62 }, --Magicka Blue
	[4] = { 0.2, 0.6, 0.2 }, --Fatigue Green
	[5] = { 0.50, 0.20, 0.66 }, --Technique Purple
	[6] = { 0.35, 0.35, 0.35 }, --Grey
	[7] = { 1.0, 0.62, 0.0 }, --Orangish
	[8] = { 0.792, 0.647, 0.376 }, --Morrowind Font Color
	[9] = { 0.18, 1.0, 0.95 }, --Light Blue
	[10] = { 0.6, 0.6, 0.0 }, --Goldish
	[11] = { 0.38, 0.13, 0.36 }, --Text Purple
	[12] = { 0.3, 0.3, 0.7 }, --Brighter UI Blue Text
	[13] = { 1.0, 0.274, 0.635 },  --Sharp Pink
	[14] = { 0.6, 0.0, 0.0 }, --Blood Karma Crimson
	[15] = { 0.9, 0.0, 0.0 }, --Lycanthropic Power "Bloodmoon"
	[16] = { 0.0, 0.5, 1.0 }, --Soul Energy Azure
	[17] = { 0.74, 0.97, 0.61 }, --Minty
	[18] = { 1.00, 1.00, 0.00 }, --Yellow
	[19] = { 1.00, 0.70, 0.80 }, --Light Pink
	[20] = { 0.53, 0.82, 0.96 }, --Baby Blue
	[21] = { 0.30, 0.30, 1.00 }, --Neon Blue
	[22] = { 0.93, 0.51, 0.93 }, --Violet
	[23] = { 1.00, 0.00, 1.00 }, -- Magenta
	[24] = { 1.00, 1.00, 0.60 }, --Straw
	[25] = { 0.00, 1.00, 1.00 }, --Cyan
	[26] = { 0.24, 0.93, 0.33 }, --UFO Green
	[27] = { 0.66, 0.53, 0.99 }, --Matte Purple
	[28] = { 0.95, 0.66, 0.36 }, --Peach
	[29] = { 0.86, 0.71, 0.35 }, --Dark Gold
	[30] = { 0.89, 0.77, 0.48 }, --Light Gold
	[31] = { 0.73, 0.63, 0.53 }, --Choccy Milk
	[32] = { 0.59, 0.49, 0.40 } --Mocha
}

--1 bricks
--2 raincloud
--3 stars
--4 msg box
--5 moon
box.ascii = {
	[1] = "_|___|___|___|___|___|___|___|___|___|___|___|_\n___|___|___|___|___|___|___|___|___|___|___|___\n_|___|___|_M_|_e_|_s_|_s_|_a_|_g_|_e_|___|___|_\n___|___|___|___|___|_B_|_o_|_x_|___|___|___|___\n_|___|___|___|___|___|___|___|___|___|___|___|_",
	[2] = "                             000      00\n                           0000000   0000\n              0      00  00000000000000000\n            0000 0  000000000000000000000000     0\n         0000000000000000[Message]0000000000000 000\n        0000000000000000000[Box]00000000000000000000\n     000000000000000000000000000000000000000000000\n  000000000000000000000000000000000000000000000000000\n              / / / / / / / / / / / / / / / /\n            / / /   / / / / / / / / / / /\n            / / / / / / / / / / /   / / /\n          / / / / / / / / / / / / / /\n          / / / / /   / / / / / / /\n        / / /   / / / / /   / /\n        /   / /   / /   / /\n          /   / /   / /\n             /   /",
	[3] = ".   .    . .  .   .  \\  .   . .  '    .     *    .      .'      .\n  .   \\  .   @  .    * . .     .  .   .  .   . '    .         .\n   * .   .   .  .    .   *.  .   ' .   @  .      .    .   *.\n.    .    * .  .   .    .   .[msg box]    .     .     . *.\n   .   .  .     .  *   .   '    .  .     *  .   . @    . '     .\n*     . .    .       .   .*     \\ .        .   '   .     .   .\n   .      .   .  .     .   .      .    .  \\  .*  .    .      .*\n    .        '        .     .            .            .\n.              .                   .          .                   .\n         .             '        .",
	[4] = "[msg box]\n                        [msg box]\n         [msg box]\n                 [msg box]\n\n      [msg box]\n[msg box]                           [msg box]\n\n             [msg box]",
	[5] = "***********************************************************\n**********************aaaaaaaaaaaaaaaa*********************************\n******************aaaaaaaaaaaaaaaaaaaaaaaa*************************************\n***************aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa************************************\n*************aaaaaaaaaaaaaaaaa***********aaaaaa********************************\n***********aaaaaaaaaaaaaaaa******************aaaa***************************\n**********aaaaaaaaaaaaa*aa**********************aa***********************\n*********aaaaaaaa******aa*************************a****************\n*********aaaaaaa*aa*aaaa*********************************************\n********aaaaaaaaa*****aaa*******************************************\n********aaaaaaaaaaa*aaaaaaa***********************[msg box]*****************\n********aaaaaaa****aaaaaaaaaa********************************************\n********aaaaaa*a*aaaaaa*aaaaaa*********************************************\n*********aaaaaaa**aaaaaaa*********************************************\n*********aaaaaaaa********************************a***************\n**********aaaaaaaaaa****************************aa******************\n***********aaaaaaaaaaaaaaaa******************aaaa***************************\n*************aaaaaaaaaaaaaaaaa***********aaaaaa********************************\n***************aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa*****************************************\n******************aaaaaaaaaaaaaaaaaaaaaaaa**************************************\n**********************aaaaaaaaaaaaaaaa**********************************\n***********************************************************"
}


-----------
--Helpers------------------------------------------------------------------------------------------------
-----------

--Log message to box.
--- @param msg string --The message to display in the box.
--- @param color table? --Optionally define your own RGB text color.
function box.logMessage(msg, color)
	if string.find(msg, box.config.filterText, 1, true) then log:debug("Filter: \"" .. box.config.filterText .. "\" blocked.") return end
	if box.config.msgLimit and box.num and box.num >= tonumber(box.config.maxMessages) then
		log:debug("Message limit reached. Deleting older messages.")
		for i = 1, math.round(#box.pane:getContentElement().children * 0.3) do
			box.pane:getContentElement().children[i]:destroy()
			box.num = box.num - 1
		end
	end

	if not tes3ui.findMenu("kl_msgBox_menu") then
		if tes3.player then
			box.createBox()
		else
			log:debug("No player ref. Message Box suppressed.")
			return
		end
	end

	local text = msg
	if box.config.timeStamp then
		text = "[" .. os.date(box.config.timeFormat) .. "] " .. msg .. ""
	end

	box.menu.visible = true
	local label = box.pane:createLabel({ text = text })
	label.wrapText = true
	label.borderBottom = box.config.msgOffset
	label.color = { box.config.textRed, box.config.textGreen, box.config.textBlue }
	if color then
		label.color = color
	end
	if string.find(text, box.config.highText, 1, true) then
		label.color = { box.config.highRed, box.config.highGreen, box.config.highBlue }
	end

	box.pane.widget.positionY = 100000 --haha silly scroll bar
	box.pane.widget:contentsChanged()
	box.num = box.num + 1
	box.time = 0
	--box.modData.lastMsg = text
	box.menu:updateLayout() --update while invisible :(
	--log:debug("" .. msg)
end


return box