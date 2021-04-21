local this = {}

--[[
    Common functions that aren't specific to this mod. Feel free to copy paste from here
]]

function this.messageBox(params)
    --[[
        Button = { text, callback}
    ]]--
    local message = params.message
    local buttons = params.buttons
    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button+1]
        if button.callback then
            button.callback()
        end
    end
    --Make list of strings to insert into buttons 
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end
    tes3.messageBox({
        message = message,
        buttons = buttonStrings,
        callback = callback
    })
end

--Stolen (and modified) from ~Sophisticated Save System. Thank you NullCascade!
--Stolen from Continue mod. Thanks PeteTheGoat!
function this.getNewestSaveFile()
	local newestSave = nil
	local newestTimestamp = 0
	for file in lfs.dir("saves") do
		if string.endswith(file, ".ess") then
			-- Check to see if the file is newer than our current newest file.
			local lastModified = lfs.attributes("saves/" .. file, "modification")
			if lastModified > newestTimestamp then
				newestSave = file
				newestTimestamp = lastModified;
			end
		end
	end

	if newestSave ~= nil then
		-- Return the whole filename, including extension.
		return newestSave
	end
end


function this.getSaveName(file)
    local lastModified = lfs.attributes("saves/" .. file, "modification")
    return string.sub(file, 1, -5), lastModified
end

function this.safeDelete(reference)
    reference.sceneNode.appCulled = true
    tes3.positionCell{
        reference = reference, 
        position = { 0, 0, 0, },
    }
    reference:disable()
    timer.delayOneFrame(function()
        mwscript.setDelete{ reference = reference}
    end)
end


function this.createTooltip(tooltip, labelText, color)
    local function setupOuterBlock(e)
        e.flowDirection = 'left_to_right'
        e.paddingTop = 0
        e.paddingBottom = 2
        e.paddingLeft = 6
        e.paddingRight = 6
        e.autoWidth = 1.0
        e.autoHeight = true
        e.childAlignX = 0.5
    end

    --Get main block inside tooltip
    local partmenuID = tes3ui.registerID('PartHelpMenu_main')
    local mainBlock = tooltip:findChild(partmenuID):findChild(partmenuID):findChild(partmenuID)

    local outerBlock = mainBlock:createBlock()
    setupOuterBlock(outerBlock)

    local label = outerBlock:createLabel({text = labelText})
    label.autoHeight = true
    label.autoWidth = true
    if color then label.color = color end
    mainBlock:reorderChildren(1, -1, 1)
    mainBlock:updateLayout()
end

return this