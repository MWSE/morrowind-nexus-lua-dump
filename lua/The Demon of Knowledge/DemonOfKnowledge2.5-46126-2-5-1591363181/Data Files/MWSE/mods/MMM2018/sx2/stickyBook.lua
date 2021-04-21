--[[
	stickyBook
	This code adds the Occulomicon to the player inventory after they first exit a bookshop.
	Subsequently, if the player tries to dispose of the book it will find its way back
		into their inventory after some time.
]]--

-------------------------------------------------
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Demon of Knowledge: DEBUG] " .. string)
	end
end

local common = require("MMM2018.sx2.common")
------------------------------------------------

-- Config -----------------------------------------
local lostInterval = 1
---------------------------------------------------

local currentTarget --shopkeeper, have to get reference before opening dialog
local function targetChanged(e)
	if e.current then
		--debugMessage("Target changed to " .. e.current.object.id or "Nil" )
		currentTarget = e.current
	end
end

--Delete any books you've sold
local function enterBarter(e)
	debugMessage("Enter barter")

	local hasBook = ( mwscript.getItemCount({reference = tes3.player, item = common.itemIds.Occulomicon}) >= 1 )
	
	--if the player has the book, remove from anyone you might have sold to
	if hasBook and currentTarget then		
		targetBooks = mwscript.getItemCount({reference = currentTarget, item = common.itemIds.Occulomicon})
		if targetBooks > 0 then
			mwscript.removeItem({ reference = currentTarget, item = common.itemIds.Occulomicon, count = targetBooks })
		end
	end
end

local function deleteBookRefs(cell)
	if cell then
		for ref in cell:iterateReferences(tes3.objectType.book) do
			if ref.object.id == common.itemIds.Occulomicon then		
				mwscript.disable({ reference = ref })
			end
		end
	end
end


local function cellChanged(e)
	debugMessage(common.itemIds.Occulomicon)
	--add book first time
	if e.previousCell and e.previousCell.id:lower():find("book") then
		--We're supposedly in a bookstore, add the Occulomicon if we haven't already
		if not common.data.givenBook then
			common.data.givenBook = true
			mwscript.addItem({ reference = tes3.player, item = common.itemIds.Occulomicon, count = 1 })
		end
	end
	deleteBookRefs(e.previousCell)
end

local lostBook
local lostBookTimer

local function returnBook()
	local finalQuest = tes3.getJournalIndex({ id = "sx2_mq7" })
	if finalQuest and finalQuest >= 100 then return end

	local hasBook = ( mwscript.getItemCount({reference = tes3.player, item = common.itemIds.Occulomicon}) >= 1 )
	lostBook = false
	if not hasBook then
		tes3.runLegacyScript({ command = "Journal sx2_mq1 15" })
		mwscript.addItem({ reference = tes3.player, item = common.itemIds.Occulomicon, count = 1 })
	end
end

--Check if the player has dropped or sold a book
local function checkBook()
	local hasBook = ( mwscript.getItemCount({reference = tes3.player, item = common.itemIds.Occulomicon}) >= 1 )
	if not lostBook and not hasBook and common.data.givenBook then
		debugMessage("Set timer to return book")
		lostBook = true
		lostBookTimer = timer.start({ type = timer.game, duration = lostInterval, callback = returnBook })
	end
	if hasBook then
		deleteBookRefs(tes3.getPlayerCell())
	end
end

local function activateContainer(e)
	if e.target.object.objectType == tes3.objectType.container then
		debugMessage("is container")
		local hasBook = ( mwscript.getItemCount({reference = tes3.player, item = common.itemIds.Occulomicon}) >= 1 )
		if hasBook then
			local containerBookCount = mwscript.getItemCount({reference = e.target, item = common.itemIds.Occulomicon})
			if containerBookCount > 0 then
				debugMessage("removing " .. containerBookCount .. " books from container" )
				mwscript.removeItem({ reference = e.target, item = common.itemIds.Occulomicon, count = containerBookCount })
			end
		end
		
	end
end

local function dataLoaded()
	event.unregister("cellChanged", cellChanged )
	event.unregister("uiActivated", enterBarter, { filter = "MenuDialog" } )	
	event.unregister("activationTargetChanged", targetChanged )
	event.unregister("activate", activateContainer )
	
	event.register("cellChanged", cellChanged )	
	event.register("uiActivated", enterBarter, { filter = "MenuDialog" } )
	event.register("activationTargetChanged", targetChanged )
	event.register("activate", activateContainer )
	bookTimer = timer.start({ type = timer.simulate, duration = 0.05, iterations = -1, callback = checkBook })
	
end

local function onload()
	lostBook = nil
end

event.register("loaded", onload)

event.register("Herme:dataReady", dataLoaded)
