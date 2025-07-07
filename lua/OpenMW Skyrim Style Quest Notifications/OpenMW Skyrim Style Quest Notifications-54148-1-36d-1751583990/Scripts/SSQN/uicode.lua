local common = common
local ui = common.omw.ui
local core = common.omw.core
local I = common.omw.interfaces
local util = common.omw.util
local l10n = common.omw.l10n


local function gmstToRgb(id, blend)
	local gmst = core.getGMST(id)
	if not gmst then return util.color.rgb(0.6, 0.6, 0.6) end
	local col = {}
	for v in string.gmatch(gmst, "(%d+)") do col[#col + 1] = tonumber(v) end
	if #col ~= 3 then print("Invalid RGB from "..gmst.." "..id) return util.color.rgb(0.6, 0.6, 0.6) end
	if blend then
		for i = 1, 3 do col[i] = col[i] * blend[i] end
	end
	return util.color.rgb(col[1] / 255, col[2] / 255, col[3] / 255)
end

local uiTheme = {
	normal = gmstToRgb("FontColor_color_normal"),
	header = gmstToRgb("FontColor_color_header"),
	baseSize = 16
}


local self, element = { animate = {} }

function self.renderBanner(m)
	self.animate = { time = 0, length = m.duration, alpha = 0,
		width = m.onlyFade and 1100 or 20, fadeTime = m.onlyFade and 1.5 or 1,
		fadeStart = m.duration + (m.onlyFade and 0 or 0.15)
	}

	local template = m.transparent and I.MWUI.templates.boxTransparentThick
		or I.MWUI.templates.boxSolidThick

	local endCap = { type = ui.TYPE.Image,
		props = {
			size = util.vector2(1100, 1),
			resource = ui.texture { path = "white" },
			color = util.color.hex("ff0000"), alpha = 0,
		}
	}

	local minHeight = { type = ui.TYPE.Image,
		props = {
			size = util.vector2(8, m.height - 2),
			resource = ui.texture { path = "white" },
			color = util.color.hex("ff0000"), alpha = 0,
		}
	}

	local minWidth = { type = ui.TYPE.Image,
		props = {
			size = util.vector2(m.width - 16, 1),
			resource = ui.texture { path = "white" },
			color = util.color.hex("00ff00"), alpha = 0,
		}
	}

	local spacer = { type = ui.TYPE.Image,
		props = {
			size = util.vector2(20, 8),
			resource = ui.texture { path = "white" },
			color = util.color.hex("00ff00"), alpha = 0,
		}
	}
	local spacer4 = { type = ui.TYPE.Image,
		props = {
			size = util.vector2(20, 4),
			resource = ui.texture { path = "white" },
			color = util.color.hex("00ff00"), alpha = 0,
		}
	}
--[[
	local contentIcon = {
		type = ui.TYPE.Image,
		props = {
				--** Size of Icon 48 x 48. Change values in line below.
        	        size = util.vector2(48, 48),
			resource = ui.texture { path = m.icon },
		},
	}

	local contentLabel = {
		template = I.MWUI.templates.textNormal,
		type = ui.TYPE.Text,
		props = {
		    text = l10n(m.header),
		    textSize =  uiTheme.baseSize, textColor = uiTheme.normal,
		},
	}
--]]

	local contentText = {}
	table.insert(contentText, minWidth)
	if m.header then
		table.insert(contentText, spacer)
		table.insert(contentText,
		{
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
			    text = l10n(m.header),
			    textSize =  uiTheme.baseSize, textColor = uiTheme.normal,
			},
		})
		if m.bodySize == 16 then
			table.insert(contentText, spacer4)
		end
	end
	table.insert(contentText, spacer)
	table.insert(contentText,
		{ template = I.MWUI.templates.textHeader,
		type = ui.TYPE.Text,
		props = {
			text = m.text,
			textSize = m.bodySize, textColor = uiTheme.header,
			},
		})

	table.insert(contentText, spacer)
	table.insert(contentText, minWidth)


	local contentBanner = {}
	if m.icon then
		table.insert(contentBanner, minHeight)
		table.insert(contentBanner,
		{
			type = ui.TYPE.Image,
			props = {
					--** Size of Icon 48 x 48. Change values in line below.
	        	        size = util.vector2(48, 48),
				resource = ui.texture { path = m.icon },
			},
		})
	end
	table.insert(contentBanner, minHeight)
	table.insert(contentBanner,
        	{ template = I.MWUI.templates.padding, alignment = ui.ALIGNMENT.Center, content = ui.content {
			{ type = ui.TYPE.Flex,
				props = { horizontal = false,
        	        	   align = ui.ALIGNMENT.Center,
	                	    arrange = ui.ALIGNMENT.Center,
				},
				content = ui.content(contentText)
			},
		}, })

	table.insert(contentBanner, minHeight)


	element = ui.create {
		layer = 'Notification',
		type = ui.TYPE.Widget,
		props = {
		visible = true,
		relativePosition = util.vector2(m.x, m.y),
		anchor = util.vector2(0.5, 0.5),
		size = util.vector2(self.animate.width, 120),
		alpha = self.animate.alpha,
		},

		content = ui.content {
			{
				type = ui.TYPE.Container,
				props = {
					relativePosition = util.vector2(0.5, 0.5),
					anchor = util.vector2(0.5, 0.5),
				},

				content = ui.content {
					{ type = ui.TYPE.Flex, props = { horizontal = false,
			         	          align = ui.ALIGNMENT.Center,
		        		            arrange = ui.ALIGNMENT.Center,
					},

						content = ui.content {
							endCap,
							{
								template = template,
								type = ui.TYPE.Container,
								props = {
									relativePosition = util.vector2(0.5, 0.5),
									anchor = util.vector2(0.5, 0.5),
								},
								content = ui.content {
									{ type = ui.TYPE.Flex,
										props = { horizontal = true,
								                  align = ui.ALIGNMENT.Center,
								       	            arrange = ui.ALIGNMENT.Center,
										},
										content = ui.content(contentBanner),
									},
								},
							},
						},

					},
				},
			},
		},
	}

	return element
end

function self.removePopup()
	if not element or type(element) == "number" then element = nil	return		end
	element:destroy()
	element = nil
end

function self.update(dt)
	local m = self.animate
	m.time = m.time + dt
	if m.time > m.length + 0.2 then		return true		end
	local width, alpha
	if m.width == 20 then
		if m.time < 1.5 then
			width = 20 + 1000 * m.time
		elseif m.time > m.length - 1 and m.time < m.length + 0.2 then
			width = 20 + 1000 * (m.length - m.time)
		end
		if width and width < 1100 then
			width = math.floor(width / 2) * 2
			element.layout.props.size = util.vector2(width, 120)
		else
			width = nil
		end
	end
	if m.time < 0.6 then
		alpha = math.min((m.time / 0.4) ^ 2, 1)
	elseif m.time > m.fadeStart - m.fadeTime and m.time < m.length + 0.2 then
		alpha = math.max(1 - ((m.time + m.fadeTime - m.fadeStart) / m.fadeTime) ^ 2, 0)
	end
	if alpha then
		element.layout.props.alpha = alpha
	end
	if alpha or width then element:update()			end
end

return self
