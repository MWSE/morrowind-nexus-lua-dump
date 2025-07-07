local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')

local commonData = require("scripts.QuickStack.commonData")

local windowSize = 400

local transferResultBox
local transferResult
local currentContainer
local currentContainerIndex = 1
local containerIdList = {}

local movingBox = false
local currentTransferPosition = util.vector2(0.413, 0.10)
local startMousePosition
local currentButtonFocus

local function hideTransferResultBox()
	if transferResultBox then
		transferResult = nil
		transferResultBox:destroy()
		transferResultBox = nil
	end
end

local underlineLayout = {
	name = 'underline',
	template = I.MWUI.templates.horizontalLineThick,
	type = ui.TYPE.Image,
	props = {
		position = util.vector2 (0, 17),
		size = util.vector2(0, 2),
	},
}

local horizontalLineLayout = {
	name = 'HorizontalLine',
	template = I.MWUI.templates.horizontalLineThick,
	type = ui.TYPE.Image,
	props = {
		size = util.vector2(1, 1),
	},
}

local horizontalGap = {
	props = { size = util.vector2(16, 0) },
}

local verticalGap = {
	props = { size = util.vector2(0, 16) },
}

local transferResultHeaderLayout = {
	name = 'Header',
	type = ui.TYPE.Flex,
	props = {
		horizontal = true,
		arrange = ui.ALIGNMENT.End,
		size = util.vector2 (windowSize, 0)
	},
	content = ui.content {
		{
			name = "HeaderTitle",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = commonData.content.transferResult.headerTitle,
				textSize = 18,
				relativePosition = util.vector2(1, 0),
			},
			external = {
				grow = 3
			},
			content = ui.content {
				underlineLayout,
			}
		},
		{
			props = { size = util.vector2(32, 0) },
		},
		{
			name = "HeaderContainerLabel",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "Destination:",
				textSize = 18,
				relativePosition = util.vector2(1, 0),
			},
			external = {
				grow = 1
			},
			content = ui.content {
			}
		},
		{
			name = "HeaderCurrentContainer",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "Crate",
				textSize = 16,
			},
			external = {
				grow = 1
			},
		},
	},
}

local function buildHeaderContainerName()
	if transferResult ~= nil then 
		transferResultHeaderLayout.content.HeaderCurrentContainer.props.text = currentContainer.name
	end

end

local transferResultTableHeaderLayout = {
	name = 'TransferResultTableHeader',
	type = ui.TYPE.Flex,
	props = {
		horizontal = true,
		size = util.vector2 (windowSize, 0)
	},
	content = ui.content {
		{
			name = "TableItemLabel",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "Item",
				textSize = 18,
				relativePosition = util.vector2(1, 0),
			},
			external = {
				grow = 3
			},

		},
		{
			name = "TableAmountLabel",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "Amount",
				textSize = 18,
				relativePosition = util.vector2(1, 0),
			},
			external = {
				grow = 1
			},

		},
	}
}

local transferResultTableRowContentLayout = {
	name = 'TransferResultTableRowContents',
	type = ui.TYPE.Flex,
	props = {
		horizontal = true,
		size = util.vector2 (windowSize, 0),
	},
	content = ui.content {
		{
			props = { size = util.vector2(0, 3) },
		},
		{
			name = "TableItem",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				autoSize = false,
				size = util.vector2(50, 18),
				text = "dawdadawdad",
				textSize = 18,
				multiline = true,
				wordWrap = true
			},
			external = {
				grow = 3
			},
		},
		{
			name = "TableAmount",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = tostring(12),
				textSize = 18,
			},
			external = {
				grow = 1
			},

		},
	}
}



local transferResultTableRowLayout = {
	name = 'TransferResultTable',
	type = ui.TYPE.Flex,
	props = {
	},
	content = {
		name = 'TransferResultTableRowContents',
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			size = util.vector2 (windowSize, 0),
		},
		content = ui.content {
		}
	}
}

local function buildTableRows()
	local tableContentRows = ui.content {}
	--Implement Pagination for overflow (30+ items)?
	if transferResult ~= nil then 
		local itemCount = 0
		for name, count in pairs(currentContainer.items) do
			local transferResultTableRowContentLayout = {
				name = 'TransferResultTableRowContents',
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					size = util.vector2 (windowSize, 0),
				},
				content = ui.content {

					{
						name = "TableItem",
						template = I.MWUI.templates.textNormal,
						type = ui.TYPE.Text,
						props = {
							autoSize = false,
							size = util.vector2(50, 18),
							text = "",
							textSize = 18,
							multiline = true,
							wordWrap = true
						},
						external = {
							grow = 3
						},
					},
					{
						name = "TableAmount",
						template = I.MWUI.templates.textNormal,
						type = ui.TYPE.Text,
						props = {
							text = "",
							textSize = 18,
						},
						external = {
							grow = 1
						},

					},
				}
			}
			--Set item name text value
			transferResultTableRowContentLayout.content.TableItem.props.text = name
			transferResultTableRowContentLayout.content.TableAmount.props.text = tostring(count)
			table.insert(tableContentRows, { props = { size = util.vector2(0, 6) } } )
			table.insert(tableContentRows, transferResultTableRowContentLayout)
						
			--Temp fix before Pagination implemented
			itemCount = itemCount + 1
			if itemCount > 30 then
				local transferResultTableRowContentOverflowLayout = {
					name = 'TransferResultTableRowContents',
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						size = util.vector2 (windowSize, 0),
					},
					content = ui.content {

						{
							name = "TableItem",
							template = I.MWUI.templates.textNormal,
							type = ui.TYPE.Text,
							props = {
								autoSize = false,
								size = util.vector2(50, 18),
								text = "...",
								textSize = 18,
								multiline = true,
								wordWrap = true
							},
							external = {
								grow = 3
							},
						},
						{
							name = "TableAmount",
							template = I.MWUI.templates.textNormal,
							type = ui.TYPE.Text,
							props = {
								text = "...",
								textSize = 18,
							},
							external = {
								grow = 1
							},

						},
					}
				}
				table.insert(tableContentRows, { props = { size = util.vector2(0, 6) } } )
				table.insert(tableContentRows, transferResultTableRowContentOverflowLayout)
				break
			end
		end
		transferResultTableRowLayout.content = tableContentRows
	end
end

--Is this even necessary? Who cares?
local transferResultTableTotalLayout = {
	name = 'TransferResultTotalRow',
	type = ui.TYPE.Flex,
	props = {
		horizontal = true,
		autoSize = true,
		align = ui.ALIGNMENT.End
	},
	content = ui.content {
		{
			name = "TotalLabel",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "Total Transferred:",
				textSize = 18,
			},
		},
		{ props = { size = util.vector2(6, 0) } },
		{
			name = "TotalAmount",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "12",
				textSize = 18,
			},
		},
	}
}


local transferResultTableLayout = {
	name = 'TransferResultTable',
	type = ui.TYPE.Flex,
	props = {
	},
	content = ui.content {
		transferResultTableHeaderLayout,
		horizontalLineLayout,
		transferResultTableRowLayout,
		{ props = { size = util.vector2(0, 6) } },
		horizontalLineLayout,
		--verticalGap,
		--transferResultTableTotalLayout
	}
}

local function updateCurrentContainer()
	if currentContainerIndex == table.getn(containerIdList) + 1 then
		currentContainerIndex = 1
	elseif currentContainerIndex == 0 then
		currentContainerIndex = table.getn(containerIdList)
	end
	currentContainer = transferResult[containerIdList[currentContainerIndex]]
	buildTableRows()
	buildHeaderContainerName()
	transferResultBox:update()
end

local function onClickNext()

end
 
local transferResultButtonBack = {
	template = I.MWUI.templates.boxSolid,
	name = 'ButtonBack',
    type = ui.TYPE.Container,
	props = {
		propagateEvents = false,
		visible = false,
	},
	external = {
		grow = 1,
		stretch = 1
	},
    events = {
		--keyPress = async:callback(function(key) 
			--local action = input.getBooleanActionValue(key)
			--if action ==  input.ACTION.Activate then
				--hideTransferResultBox()
			--end
		--end),
		focusGain = async:callback(function() 
			--print("Prev Gained Focus????")
		end),
		mouseClick = async:callback(function() 
			currentContainerIndex = currentContainerIndex - 1
			updateCurrentContainer()
		end),
	},
	content = ui.content {
		{
			name = "ButtonBackText",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = "  << Prev. Container ",
				textSize = 18,
			},
		},
	},
}

local transferResultButtonClose = {
	template = I.MWUI.templates.boxSolid,
	name = 'ButtonClose',
    type = ui.TYPE.Container,
	props = {
		propagateEvents = false
	},
	external = {
		grow = 1,
		stretch = 1
	},
    events = {
		--keyPress = async:callback(function(key) 
			--local action = input.getBooleanActionValue(key)
			--if action ==  input.ACTION.Activate then
				--hideTransferResultBox()
			--end
		--end),
		mouseClick = async:callback(function() 
			hideTransferResultBox()
		end),
	},
	content = ui.content {
		{
			name = "ButtonCloseText",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = " Close ",
				textSize = 18,
			},
		},
	},
}

local transferResultButtonNext = {
	template = I.MWUI.templates.boxSolid,
	name = 'ButtonNext',
    type = ui.TYPE.Container,
	props = {
		propagateEvents = false,
		visible = false,
	},
	external = {
		grow = 1,
		stretch = 1
	},
    events = {
		--keyPress = async:callback(function(key) 
			--local action = input.getBooleanActionValue(key)
			--if action ==  input.ACTION.Activate then
				--hideTransferResultBox()
			--end
		--end),
		mouseClick = async:callback(function() 
			currentContainerIndex = currentContainerIndex + 1
			updateCurrentContainer()
			--hideTransferResultBox()
		end),
	},
	content = ui.content {
		{
			name = "ButtonNextText",
			template = I.MWUI.templates.textNormal,
			type = ui.TYPE.Text,
			props = {
				text = " Next Container >>",
				textSize = 18,
			},
		},
	},
}

local transferResultButtonsLayout = {
	name = 'TransferResultButtons',
	type = ui.TYPE.Flex,
	props = {
		horizontal = true,
		autoSize = true
	},
	external = {
		stretch = 1
	},
	content = ui.content {
		transferResultButtonBack,
		transferResultButtonClose,
		transferResultButtonNext
	}
}

local transferResultContainerBottomPadding = {
	props = { size = util.vector2(0, 10) },
}


local transferResultContainer = {
    type = ui.TYPE.Flex,
    props = {
		position = util.vector2(10, 10),
	},
	content = ui.content {
		transferResultHeaderLayout,
		verticalGap,
		transferResultTableLayout,
		verticalGap,
		transferResultButtonsLayout,
		transferResultContainerBottomPadding
	}
}

local function moveTransferWindowPosition()
	local startMousePosX = input.getMouseMoveX()
	local startMousePosY = input.getMouseMoveY()
	
	local startWindowPosX = currentTransferPosition.x
	local startWindowPosY = currentTransferPosition.Y
	
	
end

local transferResultLayout = {
	template = I.MWUI.templates.boxSolidThick,
	layer = 'Windows',
	name = 'TransferResultBox',
    type = ui.TYPE.Container,
    props = {
        relativePosition = currentTransferPosition,
	},
	content = ui.content {
		transferResultContainer,
	},
	events = {
		--mousePress = async:callback(function(event)
			--print("MOUSE PRESS!")
			--movingBox = true
			--print("Moving Box Bool:", movingBox)
			--startMousePosition = event.position
			--print(startMousePosition)
			
		--end),
		--mouseRelease = async:callback(function(event)
			--print("MOUSE Release!")
			--movingBox = false
			--print("Moving Box Bool:", movingBox)
			--newMousePosition = event.position
			--mouseMovementDiff = startMousePosition - newMousePosition
			
			--print("old:", currentTransferPosition)
			--newWindowPosition = currentTransferPosition - mouseMovementDiff
			--currentTransferPosition = newWindowPosition
			--print("new:", currentTransferPosition)
			--transferResultLayout.props.relativePosition = newWindowPosition
			--transferResultBox:update()
		--end),
	},
}





local function setTransferResultData(data)
	transferResult = data
end

local function showTransferResultBox(config)
	containerIdList = {}
	transferResultButtonBack.props.visible = false
	transferResultButtonNext.props.visible = false
	if transferResult ~= nil then
		local gotCurrentContainer = false
		for id, container in pairs(transferResult) do
			if 	gotCurrentContainer == false then
				currentContainer = container
				gotCurrentContainer = true
			end
			table.insert(containerIdList, id)
		end
		if table.getn(containerIdList) > 1 then
			transferResultButtonBack.props.visible = true
			transferResultButtonNext.props.visible = true
		end
	end
	
	if not transferResultBox then
		transferResultBox = ui.create(transferResultLayout)
		buildTableRows()
		buildHeaderContainerName()
	end

	
	transferResultBox:update()
end

local function onInputAction(id)
	if currentButtonFocus == nil then
		if id == 5 then
			print("Focus Prev Contianer Button")
		elseif id == 6 then
			print("Focus next Contianer Button")
		elseif id == 7 or id == 8 then
			print("Focus next close Button")
		end
	end
end

return {
	setTransferResultData = setTransferResultData,
	showTransferResultBox = showTransferResultBox,
	hideTransferResultBox = hideTransferResultBox,
	engineHandlers = {
		--onInputAction = onInputAction,
		--onUpdate = function(dt)
			--print(movingBox)
		--end
	},
}