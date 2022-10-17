-- Interesting actors you talked to and where you encountered them

-- note: went back to default MWSE-Lua UI functions as an easier way to
-- fix some problems with self.elements.info.text not displaying correctly

local author = 'abot'
local modName = "Who's Where"
local mcmName = author .. "'s " .. modName
---local modPrefix = author .. '/'.. modName

---local logLevel = 0

local mcm = {}

function mcm.onCreate(container)

	local keys = {}
	local actors = {}

	local function getCleanedTable(t)
		for k in pairs(t) do
			--[[if logLevel >= 4 then
				mwse.log('%s: getCleanedTable(t) t["%s"] = nil', modPrefix, k)
			end]]
			t[k] = nil
		end
		t = {}
		return t
	end

	local function cleanTables()
		actors = getCleanedTable(actors)
		keys = getCleanedTable(keys)
	end

	local function getActors()
		cleanTables()
		local actor, ref, actorName, cellName, lcId, i
		local count = 1
		for _, dialogue in pairs(tes3.mobilePlayer.dialogueList) do
			for _, info in pairs(dialogue.info) do
				actor = info.firstHeardFrom
				if actor then
					if actor.cloneCount == 1 then
						lcId = actor.id:lower()
						ref = tes3.getReference(lcId)
						if ref then
							cellName = ref.cell.editorName
							if keys[lcId] then
								i = keys[lcId]
							else
								i = count
								keys[lcId] = count
								count = count + 1
							end
							actorName = actor.name
							actors[i] = {n = actorName, c = cellName, cn = cellName .. ': ' .. actorName}
							---mwse.log("%s at %s", actorName, cellName)
						end -- if ref
					end -- if actor.cloneCount
					break
				end -- if actor
			end -- for info
		end -- for dialogue
	end

	local ready = false
	if tes3.player then
		getActors()
		if #actors > 0 then
			ready = true
		end
	end

	local mainPane, searchInput, list1, list2

	local sSearch = 'Search...'

	local function updateLists()
		local searchText = searchInput.text:lower()
		local search = not (
			(searchText == '')
			or (searchText == sSearch:lower())
		)

		local function updateList(list)
			local children = list.children[1].children[1].children
			local lbl
			for _, el in pairs(children) do
				---mwse.log('el %s %s', el.id, el.name)
				lbl = el.children[1]
				---mwse.log('lbl %s %s %s', lbl.id, lbl.name, lbl.text)
				if search then
					if string.find(lbl.text:lower(), searchText, 1, true) then
						el.visible = true
					else
						el.visible = false
					end
				else
					el.visible = true
				end
			end
		end

		updateList(list1)
		updateList(list2)
		mainPane:getTopLevelParent():updateLayout() -- this is needed too
		list1.widget:contentsChanged()
		list2.widget:contentsChanged()
	end

	local function onFilter()
		updateLists()
	end

	local function onClear(e)
		e.source.text = sSearch
		updateLists()
	end

	--[[local function acquireTextInput()
		tes3ui.acquireTextInput(searchInput)
	end]]

	local function makeInput(el)
		---tes3.messageBox(el.name)
		local searchInputBlock = el:createBlock{}
		searchInputBlock.width = 120
		searchInputBlock.autoHeight = true
		---searchInputBlock.childAlignX = 0.5
		searchInputBlock.childAlignX = 0.0
		local border = searchInputBlock:createThinBorder{}
		border.width = searchInputBlock.width
		---border.height = 30
		border.autoHeight = true
		---border.childAlignX = 0.5
		---border.childAlignY = 0.5
		local input = border:createTextInput({id = 'ab01SearchInput'})
		input.text = sSearch
		input.borderLeft = 3
		input.borderRight = 3
		input.widget.lengthLimit = 31
		input.widget.eraseOnFirstKey = true
		el:register('keyEnter', onFilter) -- only works when text input is not captured
		input:register('keyEnter', onFilter)
		input:register('mouseClick', onClear)

		input:registerAfter('keyPress', onFilter)

		---border:register('mouseClick', acquireTextInput)
		--[[local menu = el:getTopLevelMenu()
		menu:updateLayout()]]
		tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
		return input
	end

	local function createList(el)
		local list = el:createVerticalScrollPane({})
		list.borderAllSides = 6
		list.widthProportional = 1.0
		list.heightProportional = 1.0
		return list
	end

	local function createLabel(parent, labelText)
		local block = parent:createBlock({})
		block.flowDirection = 'top_to_bottom'
		block.paddingAllSides = 4
		block.layoutWidthFraction = 1.0
		block.height = 24
		block:createLabel({text = labelText})
	end

	mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	searchInput = makeInput(mainPane)

	local noneYet = 'None yet'

	mainPane:createLabel({text = "Who's Where (by name):"})
	list1 = createList(mainPane)

	if ready then
		table.sort(actors, function(a,b) return a.n < b.n end)
		for _, v in ipairs(actors) do
			createLabel(list1, string.format("%s at %s\n", v.n, v.c))
		end
	else
		createLabel(list1, noneYet)
	end

	mainPane:createDivider({})

	mainPane:createLabel({text = "Who's Where (by place, name):"})
	list2 = createList(mainPane)

	if ready then
		table.sort(actors, function(a,b) return a.cn < b.cn end)
		for _, v in ipairs(actors) do
			createLabel(list2, v.cn .. "\n")
		end
	else
		createLabel(list2, noneYet)
	end

	mainPane:getTopLevelParent():updateLayout()
	list1.widget:contentsChanged()
	list2.widget:contentsChanged()

	cleanTables()
end

event.register('modConfigReady', function () mwse.registerModConfig(mcmName, mcm) end)
