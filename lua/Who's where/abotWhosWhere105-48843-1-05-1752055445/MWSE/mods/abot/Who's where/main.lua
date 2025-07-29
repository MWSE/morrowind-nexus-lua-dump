---@diagnostic disable: missing-fields
-- Interesting actors you talked to and where you encountered them

-- note: went back to default MWSE-Lua UI functions as an easier way to
-- fix some problems with self.elements.info.text not displaying correctly

local author = 'abot'
local modName = "Who's Where"
local mcmName = author .. "'s " .. modName
---local modPrefix = author .. '/'.. modName

---local logLevel = 0

local mcm = {}

local cmd, destCell, destPos

local function simulate()
	if not (tes3.player.cell == destCell) then
		return
	end
	local pathGrid = destCell.pathGrid
	if pathGrid then
		if not pathGrid.isLoaded then
			return -- wait until path grid is loaded
		end
		local nodes = pathGrid.nodes
		if nodes
		and (#nodes > 0) then
			local pos
			if destPos then
				for i = 1, #nodes do
					local node = nodes[i]
					local connectedNodes = node.connectedNodes
					if connectedNodes
					and (#connectedNodes > 0)
					and (node.position:distance(destPos) <= 1024) then
						pos = node.position
						break
					end
				end
			else
				local node = nodes[math.floor(#nodes / 2 + 0.5)]
				if node then
					pos = node.position
				end
			end
			if pos then
				local pPos = tes3.player.position
				pPos.x, pPos.y, pPos.z = pos.x, pos.y, pos.z
			end
		end
	end
	event.unregister('simulate', simulate)
end

local lastSearch = true

function mcm.onCreate(container)

	local keys = {}
	local actors = {}

	local function getCleanedTable(t)
		for k, _ in pairs(t) do
			t[k] = nil
		end
		t = {}
		return t
	end

	---local worldController, mobileActors

	local function initData()
		cmd = nil
		destCell = nil
		destPos = nil
		actors = getCleanedTable(actors)
		keys = getCleanedTable(keys)
		---worldController = tes3.worldController
		---if worldController then
			---mobileActors = worldController.allMobileActors
		---end
	end

	local function getActorRef(lcId)
		-- should hopefully be faster than tes3.getReference()
		-- cons: 72 hours expire, enough for our use case
		--[[local ref
		if mobileActors then
			local mob
			for i = 1, #mobileActors do
				mob = mobileActors[i]
				ref = mob.reference
				if ref
				and (not ref.disabled)
				and (not ref.deleted) then					---mwse.log('ref = "%s"', ref)
					if string.lower(ref.object.id) == lcId then
						return ref
					end
				end
			end
		end]]
		local ref = tes3.getReference(lcId)
		if ref
		and (not ref.disabled)
		and (not ref.deleted) then
			return ref
		end
	end

	local function getActors()
		initData()
		local count = 1
		local dialogueList = tes3.mobilePlayer.dialogueList
		for i = 1, #dialogueList do
			local dialogue = dialogueList[i]
			local infos = dialogue.info
			for j = 1, #infos do
				local info = infos[j]
				local actor = info.firstHeardFrom
				or info.actor
				if actor
				and (actor.cloneCount <= 1) then
					local lcId = string.lower(actor.id)
					local ref = getActorRef(lcId)
					if ref
					and (not ref.disabled)
					and (not ref.deleted)
					and (not ref.isDead) then
						local cellName = ref.cell.editorName
						local k = count
						if keys[lcId] then
							k = keys[lcId]
						else
							keys[lcId] = count
							count = count + 1
						end
						local actorName = actor.name
						actors[k] = {n = actorName, c = cellName,
							cn = cellName .. ': ' .. actorName, cl = ref.cell, p = ref.position}
						---mwse.log("%s at %s", actorName, cellName)
					end -- if ref
					break -- exit for j loop
				end -- if actor
			end -- for j
		end -- for i
	end

	local ready = false
	if tes3.player then
		getActors()
		if #actors > 0 then
			ready = true
		end
	end

	local mainPane, searchInput, searchInput2, list1, list2

	local sSearch = 'Containing...'
	local sSearch2 = 'Not containing...'

	local search, search2, searchText, searchText2

	local function updateList(list)
		local children = list:getContentElement().children
		for i = 1, #children do
			local el = children[i]
			local lbl = el.children[1]
			local lcText = string.lower(lbl.text)
			---mwse.log('lbl %s %s', lbl.id, lbl.text)
			local visible = true
			if search
			and (not string.find(lcText, searchText, 1, true)) then
				visible = false
			elseif search2
				and string.find(lcText, searchText2, 1, true) then
				visible = false
			end
			if not (el.visible == visible) then
				el.visible = visible
			end
		end
		list.widget:contentsChanged()
	end

	local function updateView()
		mainPane:getTopLevelMenu():updateLayout() -- this is needed too
		list1.widget:contentsChanged()
		list2.widget:contentsChanged()
	end

	local function updateLists()
		searchText = string.lower(searchInput.text)
		searchText2 = string.lower(searchInput2.text)
		search = not (
			(string.len(searchText) < 2)
			or (searchText == string.lower(sSearch))
		)
		search2 = not (
			(string.len(searchText2) < 2)
			or (searchText2 == string.lower(sSearch2))
		)
		---mwse.log('searchText = "%s", searchText2 = "%s", search = %s, search2 = %s',
			---searchText, searchText2, search, search2)
		local search3 = search
			or search2
		if search3 == lastSearch then
			if not search3 then
				return
			end
		end
		lastSearch = search3
		updateList(list1)
		updateList(list2)
	end

	local function onFilter()
		updateLists()
	end

	local function onClear(e)
		local el = e.source
		tes3ui.acquireTextInput(el)
		if el.name == 'ab01SearchInput' then
			el.text = sSearch
		else
			el.text = sSearch2
		end
		updateLists()
	end

	local function onClear2(e)
		onClear({source = e.source.children[1]})
	end

	local function createInput(parent, inputId, searchInitText)
		---tes3.messageBox(parent.name)
		local searchInputBlock = parent:createBlock{}
		searchInputBlock.width = 200
		searchInputBlock.autoHeight = true
		local border = searchInputBlock:createThinBorder{}
		border.width = searchInputBlock.width
		---border.height = 30
		border.autoHeight = true
		local input = border:createTextInput({id = inputId})
		input.text = searchInitText
		input.borderAllSides = 3
		input.widget.lengthLimit = 31
		input.widget.eraseOnFirstKey = true
		input:register('keyEnter', onFilter)
		border:register('keyEnter', onFilter) -- only works when text input is not captured
		input:registerAfter('keyPress', onFilter)
		input:register('mouseClick', onClear)
		border:register('mouseClick', onClear2)
		return input
	end

	local function createList(parent)
		local list = parent:createVerticalScrollPane({})
		list.borderAllSides = 3
		list.widthProportional = 1.0
		list.heightProportional = 1.0
		return list
	end

	local function mouseClickLabel(e)
		local el = e.source
		destCell = el:getLuaData('cell')
		if not destCell then
			return
		end
		if destCell == tes3.player.cell then
			return
		end
		local menu = el:getTopLevelMenu()
		if not menu then
			return
		end
		destPos = el:getLuaData('pos')

		local function onButtonPressed(ev)
			if ev.button == 1 then
				os.setClipboardText(el.text)
				return
			end
			if destCell.isInterior then
				cmd = string.format('COC "%s"', destCell.id)
			else
				cmd = string.format('COE %s %s', destCell.gridX, destCell.gridY)
			end
			timer.start({duration = 0.1, callback =
				function ()
					tes3.runLegacyScript({command = cmd, source = tes3.compilerSource.console})
					if destCell.isInterior then
						return
					end
					event.register('simulate', simulate)
				end
			})
			tes3ui.leaveMenuMode()
			menu:destroy()
		end

		tes3.messageBox({
			message = string.format('Teleport to "%s"?', destCell.editorName),
			buttons = {
[[Yeah, I am a cheater and proud of it!]],
[[Nope, I'm roleplaying this as some personal note.
Just copy the line to the clipboard.]],
			},
			showInDialog = false,
			callback = onButtonPressed,
		})
	end

	local function makeLabel(parent, labelText, cell, pos)
		local block = parent:createBlock({})
		block.flowDirection = 'top_to_bottom'
		block.paddingAllSides = 4
		block.layoutWidthFraction = 1.0
		block.height = 24
		local label = block:createLabel({text = labelText})
		label.layoutWidthFraction = 1.0
		label.paddingAllSides = 2
		if cell then
			label:setLuaData('cell', cell)
			if pos then
				label:setLuaData('pos', pos)
			end
			label:register('mouseClick', mouseClickLabel)
		end
	end

	mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	local block = mainPane:createBlock({})
	block.flowDirection = 'left_to_right'
	block.childAlignX = 0.0 -- left align
	block.autoHeight = true
	block.autoWidth = true
	block.borderAllSides = 3
	block.borderBottom = 10
	searchInput = createInput(block, 'ab01SearchInput', sSearch)
	searchInput2 = createInput(block, 'ab01SearchInput2', sSearch2)

	-- automatically reset when menu is closed
	tes3ui.acquireTextInput(searchInput)

	local noneYet = 'None yet'
	local lbl = mainPane:createLabel({text = "Who's Where (by name):"})
	lbl.paddingAllSides = 3
	list1 = createList(mainPane)

	if ready then
		table.sort(actors, function(a,b) return a.n < b.n end)
		for i = 1, #actors do
			local v = actors[i]
			makeLabel(list1, v.n .. ' at ' .. v.c .. '\n', v.cl, v.p)
		end
	else
		makeLabel(list1, noneYet)
	end

	mainPane:createDivider({})

	local lbl2 = mainPane:createLabel({text = "Who's Where (by place, name):"})
	lbl2.paddingAllSides = 3

	list2 = createList(mainPane)

	if ready then
		table.sort(actors, function(a,b) return a.cn < b.cn end)
		for i = 1, #actors do
			local v = actors[i]
			makeLabel(list2, v.cn .. '\n', v.cl, v.p)
		end
	else
		makeLabel(list2, noneYet)
	end

	updateView()

end
event.register('modConfigReady', function () mwse.registerModConfig(mcmName, mcm) end)
