local input = common.omw.input
local async = common.omw.async
local core = common.omw.core
local ui = common.omw.ui
local I = common.omw.interfaces
local util = common.omw.util
local ambient = common.omw.ambient
local v2 = util.vector2

local M = {
	uiTheme = require("scripts.AnimatedPickup.uitheme"),
	uiMenu = {}
}

local uiTheme = M.uiTheme
local messageBox

function M.removeBox()
	M.animate = {close = true, time = core.getRealTime(), stop = 0.25}
	if M.uiMenu then
		M.uiMenu.callback(0)
		M.uiMenu = nil
	end
end

local function uiClick(_, e)
	M.animate = {close = true, time = core.getRealTime(), stop = 0.25}
	if M.uiMenu then
		M.uiMenu.callback(e.userData)
		M.uiMenu = nil
	end
end

local function uiFocus(_, content)
	for _, v in ipairs(M.uiMenu) do
		v.props.textColor = uiTheme.normal
	end
	content.props.textColor = uiTheme.normal_pressed
--	print(content.userData)
	M.uiMenu.select = content.userData
	messageBox:update()
	ambient.playSound("Menu Click")
end

function M.uiInput()
	local range, press = input.getRangeActionValue, input.isControllerButtonPressed
	local b = input.CONTROLLER_BUTTON	local m = M.uiMenu
	local move, update = 0
	if core.getRealTime() - m.time > 0.2 then
		move = move + range("MoveBackward") - range("MoveForward")
		move = move + range("MoveRight") - range("MoveLeft")
		move = move + (press(b.DPadDown) and 1 or 0) - (press(b.DPadUp) and 1 or 0)
		move = move + (press(b.DPadRight) and 1 or 0) - (press(b.DPadLeft) and 1 or 0)
		move = move - input.getNumberActionValue("Zoom3rdPerson")
	elseif core.getRealTime() - m.time > 0.1 then
		move = move - input.getNumberActionValue("Zoom3rdPerson")
	end
	if math.abs(move) > 0.9 then
	--	local old = m.select
		local new = m.select + (move > 0 and 1 or -1)
	--	old = util.clamp(old, 1, #m)
		new = new > 0 and new or #m	new = new <= #m and new or 1
		uiFocus(_, m[new])
		m.time = core.getRealTime()
	end
	if m.select < 1 or m.select > #m then		return		end
	if input.getBooleanActionValue("Use") or input.isActionPressed(input.ACTION.Activate) then
		uiClick(_, m[m.select])
	end
end

function M.update(dt)
	if M.uiMenu then M.uiInput()		end
	if not messageBox then		return true	end
	local m = M.animate
	if not m.open and not m.close then		return		end
	local time = core.getRealTime() - m.time
	local alpha
	if time < m.stop + 0.2 then
		alpha = math.min((time / m.stop) ^ 2, 1)
		if m.close then		alpha = 1 - alpha		end
		messageBox.layout.props.alpha = alpha
	elseif m.close then
		messageBox:destroy()		messageBox = nil
	--	print("MESSAGEBOX", messageBox, "UIMENU", M.uiMenu)
	else
		m.open = nil
	end
	if alpha then messageBox:update()			end
end


local function paddedBox(options)
    options = options or {}

    local color = options.color and options.color or util.color.hex("000000")
    local alpha = options.alpha or 0
    local padding = options.padding and options.padding or 0
    local texture = options.texture

    if type(padding) == "number" then
        padding = { left = padding, right = padding, top = padding, bottom = padding }
    else
        padding = {
            left = padding.left and padding.left or 0,
            right = padding.right and padding.right or 0,
            top = padding.top and padding.top or 0,
            bottom = padding.bottom and padding.bottom or 0
        }
    end

    local template = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    resource = ui.texture { path = texture or "white" },
                    color = not texture and color or nil,
                    alpha = alpha,
                    size = util.vector2(padding.left + padding.right, padding.top + padding.bottom),
                },
            },
            {
                external = { slot = true },
                props = {
                    position = util.vector2(padding.left, padding.top),
                    relativeSize = util.vector2(1, 1),
                }
            },
        },
    }
    return template
end

local function Spacer(options)
    options = options or {}
    local color = options.color and options.color or util.color.hex("00ff00")
    local alpha = options.alpha or 0
    local padding = options.padding and options.padding or 0

    local template = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    resource = ui.texture { path = "white" },
                    color = color,
                    alpha = alpha,
                    size = util.vector2(padding, padding),
                },
            },
        },
    }
    return template
end

local function uiButton(k, text, click, focus)
    return { type = ui.TYPE.Container, content = ui.content {
	{ template = I.MWUI.templates.box, props = { anchor = v2(0, -0.5) },
		content = ui.content { {
		template = I.MWUI.templates.padding,
        	        content = ui.content { {

				type = ui.TYPE.Text,
				userData = k,
				events = { mouseClick=click, focusGain=focus },
				name = name,
				props = { text = text, textColor = uiTheme.normal,
					textSize = uiTheme.baseSize }
			} }
		} }
	}
    } }
end

local function uiOption(k, text, click, focus)
    return {
                template = I.MWUI.templates.padding,
        	        content = ui.content { {

				type = ui.TYPE.Text,
				userData = k,
				events = { mouseClick = click, focusGain=focus },
				name = name,
				props = { text = text, textColor = uiTheme.normal,
					textSize = uiTheme.largeSize }
			} }
 }
end

function M.createMenu(e)
	if messageBox then messageBox:destroy()		end
	M.uiMenu = {select = 0, time = core.getRealTime(), callback = e.callback}
	M.animate = { time=core.getRealTime(), open=true, stop=0.25 }

	local message
	if e.message then message = { {
		template = I.MWUI.templates.padding,
			content = ui.content { {

			type = ui.TYPE.Text,
			props = {
			text = e.message, multiline = true,
			textAlignH = ui.ALIGNMENT.Center,
			textColor = uiTheme.header,
			textSize = uiTheme.baseSize
	        	}

		} }
	} }
	end

	local buttons = {}
	table.insert(buttons, Spacer{ alpha=0, padding=12 })
	for k, item in ipairs(e.buttons) do
		local button = uiOption(k, item, async:callback(uiClick), async:callback(uiFocus))
		table.insert(buttons, button)
		table.insert(M.uiMenu, button.content[1])
	end

	local flex = {}
	if message then
		table.insert(flex, { type = ui.TYPE.Flex,
                content = ui.content(message),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                	}
		})
	end
	table.insert(flex, { type = ui.TYPE.Flex,
                content = ui.content(buttons),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Start,
                }
	})

--[[
	local box = {
		type = ui.TYPE.Container,
		content = ui.content{},
	}
	box.content:add {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "white" },
			color = util.color.rgb(0, 0, 0),
			alpha = 0.5,
			relativeSize = v2(1, 1),
			size = v2(4, 4)
		}
	}
	box.content:add {
		external = { slot = true },
		props = {
			position = v2(2, 2),
			relativeSize = v2(1, 1),
		}
        }
--]]

    messageBox = ui.create {
        layer = "Windows",
        template = paddedBox { alpha = uiTheme.menuBG_thinWide and 0.75 or 0.5,
            padding = 2,
            texture = uiTheme.menuBG_thinWide, color = uiTheme.background },
        props = {
            relativePosition = v2(0.5, 0.7),
            anchor = v2(0.5, 0.5),
            alpha = 0.0
        },
        content = ui.content {

            { template = paddedBox({ alpha = 0.0, padding = {left=32, right=32, top=12, bottom=12},
                color = util.color.hex("00ff00") }),
            content = ui.content{

                { type = ui.TYPE.Flex,
                content = ui.content(flex),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
		}, },

            }, },

         }
    }

	return messageBox
end


return M
