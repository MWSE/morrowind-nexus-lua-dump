-- Interesting actors you talked to and where you encountered them

-- note: went back to default MWSE-Lua UI functions as an easier way to 
-- fix some problems with self.elements.info.text not displaying correctly

local author = 'abot'
local modName = "Who's Where"
local mcmName = author .. "'s " .. modName
local modPrefix = author .. '/'.. modName

local keys = {}
local actors = {}

local function getActors()
	local actor, ref, cell, lcId, actorName, cellName
	local count = 0
	keys = {}
	actors = {}
	for dialogue in tes3.iterate(tes3.mobilePlayer.dialogueList) do
		for info in tes3.iterate(dialogue.info) do
			actor = info.firstHeardFrom
			if actor then
				if actor.cloneCount == 1 then
					lcId = actor.id:lower()
					if not keys[lcId] then
						actorName = actor.name
						ref = tes3.getReference(lcId)
						if ref then
							cell = ref.cell
							if cell then
								cellName = cell.name
								if cellName then
									if not cell.isInterior then
										cellName = string.format("%s (%s, %s)", cellName, cell.gridX, cell.gridY)
									end
									keys[lcId] = true
									count = count + 1
									actors[count] = {name = actorName, cell = cellName,
										cellAndName = cellName .. ': ' .. actorName}
									---mwse.log("%s at %s", actorName, cellName)
								end -- if cellName
							end -- if ref.cell
						end -- if ref
					end -- if not keys[lcId]
				end -- if actor.cloneCount
				break
			end -- if actor
		end -- for info
	end -- for dialogue
end


local modConfig = {}

local function createListLabel(parent, labelText)
	local block = parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 24
	block:createLabel({text = labelText})
end

function modConfig.onCreate(container)
	---mwse.log("%s modConfig.onCreate(%s)", modPrefix, container)
	---assert(mainPane)

	local ready = false
	if tes3.player then
		getActors()
		if #actors > 0 then
			ready = true
		end
	end

	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	local list = mainPane:createVerticalScrollPane({})
	list.borderAllSides = 6
	list.widthProportional = 1.0
	list.heightProportional = 1.0

	local noneYet = 'None yet'
	createListLabel(list, "Who's Where (by name):")
	if ready then
		table.sort(actors, function(a,b) return a.name < b.name end)
		for _, v in ipairs(actors) do
			createListLabel(list, string.format("%s at %s\n", v.name, v.cell))
		end
	else
		createListLabel(list, noneYet)
	end

	list:createDivider({})

	createListLabel(list, "Who's Where (by place, name):")
	if ready then
		table.sort(actors, function(a,b) return a.cellAndName < b.cellAndName end)
		for _, v in ipairs(actors) do
			createListLabel(list, v.cellAndName .. "\n")
		end
	else
		createListLabel(list, noneYet)
	end

	mainPane:getTopLevelParent():updateLayout()
	list.widget:contentsChanged()

	actors = nil
	keys = nil

end

local function modConfigReady()
	mwse.log(modPrefix .. " modConfigReady")
	mwse.registerModConfig(mcmName, modConfig)
end
event.register('modConfigReady', modConfigReady)
