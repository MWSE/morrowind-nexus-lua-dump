--Thanks to NullCascade for this mcm menu code

local this = {}

local refreshActiveList

local blackListPane
local blackListActualPane

local function createBlackListRow(container, id)
	local row = container:createBlock({})
	row.layoutWidthFraction = 1.0
	row.autoHeight = true
	blackListActualPane = row.parent

	local label = row:createLabel({ text = id })

	local removeBtn = row:createButton({ text = "Remove" })
	removeBtn.layoutOriginFractionX = 1.0
	removeBtn:register("mouseClick", function(e)
		table.removevalue(this.config.blackList, id)
		row:destroy()
		refreshActiveList()
		container:getTopLevelParent():updateLayout()
	end)

	return row
end

local function caseInsensitiveSorter(a, b)
	return string.lower(a) < string.lower(b)
end

local function refreshBlackList()
	if (blackListActualPane) then
		blackListActualPane:destroyChildren()
	end
	table.sort(this.config.blackList, caseInsensitiveSorter)
	for i = 1, #this.config.blackList do
		createBlackListRow(blackListPane, this.config.blackList[i])
	end
end

local activeListPane
local activeListActualPane

local function createActiveListRow(container, follower)
	local row = container:createBlock({})
	row.layoutWidthFraction = 1.0
	row.autoHeight = true
	activeListActualPane = row.parent

	local followerBaseId = follower.id
	if (follower.isInstance) then
		followerBaseId = follower.baseObject.id
	end

	local label = row:createLabel({ text = followerBaseId })

	if (table.find(this.config.blackList, followerBaseId) == nil) then
		local removeBtn = row:createButton({ text = "Blacklist" })
		removeBtn.layoutOriginFractionX = 1.0
		removeBtn:register("mouseClick", function(e)
			table.insert(this.config.blackList, followerBaseId)
			refreshBlackList()
			removeBtn.visible = false
		end)
	end

	return row
end

refreshActiveList = function()
	if (activeListActualPane) then
		activeListActualPane:destroyChildren()
	end

	local macp = tes3.mobilePlayer
	if (macp) then
		for actor in tes3.iterate(macp.friendlyActors) do
			if (actor ~= macp) then
				createActiveListRow(activeListPane, actor.reference.object)
			end
		end
	end
end

local function createConfigSliderPackage(params)
	local horizontalBlock = params.parent:createBlock({})
	horizontalBlock.flowDirection = "left_to_right"
	horizontalBlock.layoutWidthFraction = 1.0
	horizontalBlock.height = 24

	local label = horizontalBlock:createLabel({ text = params.label })
	label.layoutOriginFractionX = 0.0
	label.layoutOriginFractionY = 0.5

	local config = params.config
	local key = params.key
	local value = config[key] or params.default or 0
	
	local sliderLabel = horizontalBlock:createLabel({ text = tostring(value) })
	sliderLabel.layoutOriginFractionX = 1.0
	sliderLabel.layoutOriginFractionY = 0.5
	sliderLabel.borderRight = 306

	local range = params.max - params.min

	local slider = horizontalBlock:createSlider({ current = value - params.min, max = range, step = params.step, jump = params.jump })
	slider.layoutOriginFractionX = 1.0
	slider.layoutOriginFractionY = 0.5
	slider.width = 300
	slider:register("PartScrollBar_changed", function(e)
		config[key] = slider:getPropertyInt("PartScrollBar_current") + params.min
		sliderLabel.text = config[key]
		if (params.onUpdate) then
			params.onUpdate(e)
		end
	end)

	return { block = horizontalBlock, label = label, sliderLabel = sliderLabel, slider = slider }
end

function this.onCreate(parent)
	blackListActualPane = nil
	activeListActualPane = nil

	local container = parent:createThinBorder({})
	container.flowDirection = "top_to_bottom"
	container.layoutHeightFraction = 1.0
	container.layoutWidthFraction = 1.0
	container.paddingAllSides = 6

	local descriptionLabel
	if (tes3.mobilePlayer) then
		descriptionLabel = container:createLabel({ text = "Companion Health Bars adds health bars to your companions. Sometimes friendly actors that aren't companions can end up with one as well. You can use this blacklist to stop non-companion actors from receiving health bars. To do this, click the blacklist button. You may also remove actors from this blacklist." })
	else
		descriptionLabel = container:createLabel({ text = "Companion Health Bars adds health bars to your companions. Sometimes friendly actors that aren't companions can end up with one as well. To view and blacklist actors, load a save game." })
	end
	descriptionLabel.layoutWidthFraction = 1.0
	descriptionLabel.wrapText = true
	descriptionLabel.layoutHeightFraction = -1
	descriptionLabel.borderBottom = 12
	
	createConfigSliderPackage({
		parent = container,
		label = "Seconds between updates:",
		config = this.config,
		key = "pollRate",
		min = 1,
		max = 5,
		step = 1,
		jump = 1,
	})

	local splitPane = container:createBlock({})
	splitPane.flowDirection = "left_to_right"
	splitPane.layoutWidthFraction = 1.0
	splitPane.layoutHeightFraction = 1.0

	do
		local blackListBox = splitPane:createBlock({})
		blackListBox.flowDirection = "top_to_bottom"
		blackListBox.layoutWidthFraction = 1.0
		blackListBox.layoutHeightFraction = 1.0
	
		local label = blackListBox:createLabel({ text = "Blacklist:" })
		label.borderBottom = 6

		blackListPane = blackListBox:createVerticalScrollPane({})
		blackListPane.layoutWidthFraction = 1.0
		blackListPane.layoutHeightFraction = 1.0
		blackListPane.paddingAllSides = 6

		refreshBlackList()
	end

	if (tes3.mobilePlayer) then
		local activeListBox = splitPane:createBlock({})
		activeListBox.flowDirection = "top_to_bottom"
		activeListBox.layoutWidthFraction = 1.0
		activeListBox.layoutHeightFraction = 1.0
		activeListBox.borderLeft = 6
	
		local label = activeListBox:createLabel({ text = "Friendly Actors:" })
		label.borderBottom = 6

		activeListPane = activeListBox:createVerticalScrollPane({})
		activeListPane.layoutWidthFraction = 1.0
		activeListPane.layoutHeightFraction = 1.0
		activeListPane.paddingAllSides = 6
		
		refreshActiveList()
	end
	
	container:getTopLevelParent():updateLayout()
end

-- Since we are taking control of the mod config system, we will manually handle saves. This is
-- called when the save button is clicked while configuring this mod.
function this.onClose(container)
	mwse.saveConfig("Companion Health Bars", this.config)
end

return this