-- TODO: consider adding an animation. Could be like Animated Pickup?
-- TODO: consider companions with Inventory Share as valid targets for out-of-menu transfer.
-- TODO: consider implementing blacklist for containers.
local blacklist = {
	-- The stalhrim ore isn't marked as organic! This allows the player to store items inside.
	["contain_bm_stalhrim_01"] = true,
}

local inspect = require("inspect")

local config = require("Place Stacks.config")
local log = mwse.Logger.new({
	name = "Place Stacks",
	logLevel = config.logLevel,
})

local i18n = mwse.loadTranslations("Place Stacks")
local ui = require("Place Stacks.ui")
local util = require("Place Stacks.util")
dofile("Place Stacks.mcm")


---@type tes3inputController
local ic
local wasActivateDownThisFrame = false
local targetTimestamp = math.huge

event.register(tes3.event.initialized, function()
	ic = tes3.worldController.inputController
end)


-- This adds a "Place Stacks" button to the ContantsMenu.
---@param e uiActivatedEventData
local function buttonComponent(e)
	-- We also need to set these vars for activate component.
	wasActivateDownThisFrame = true
	targetTimestamp = os.clock() + config.activateDelay

	if not config.buttonEnabled then return end
	local menu = e.element
	local buttonsOuterContainer = menu:findChild(ui.id.buttonsContainer).children[2]
	if not buttonsOuterContainer then
		log:warn("Couldn't find the menu element where \"Place Stacks\" button should be added.")
		return
	end
	local container = buttonsOuterContainer:findChild(ui.id.buttonsContainer)
	if not container then
		log:warn("Couldn't find the menu element where \"Place Stacks\" button should be added.")
		return
	end
	-- TODO: this button has the name "Ralen Hlaalo"
	local button = container:createButton({
		id = ui.id.button,
		-- text = "Stack Items"
		text = i18n("Place Stacks")
	})

	-- UI Expansion doesn't add the capacity bar to dead NPC bodies, but we add
	-- our button to such menus.
	if container:findChild(ui.id.uiExpansionMenuContentsCapacity) then
		button:reorder({ after = container.children[1] })
	else
		-- In this case container.children[1] is the "Take All" or
		-- for empty bodies the "Cancel" button.
		button:reorder({ before = container.children[1] })
	end
	button:registerAfter(tes3.uiEvent.mouseClick, util.transferStacksFromMenu)
	menu:updateLayout()
end
event.register(tes3.event.uiActivated, buttonComponent, { filter = ui.id.menuContents })

-- This will place stacks if holding down the "Activate" keybind.
---@param e enterFrameEventData
local function activateComponent(e)
	if not config.activateEnabled
	or not e.menuMode
	or not wasActivateDownThisFrame then
		return
	end

	if not ic:keybindTest(tes3.keybind.activate) then
		wasActivateDownThisFrame = false
		return
	end

	if os.clock() < targetTimestamp then return end

	wasActivateDownThisFrame = false
	util.transferStacksFromMenu()
end
event.register(tes3.event.enterFrame, activateComponent)


---@param e keyDownEventData
local function keybindComponent(e)
	if not tes3.isKeyEqual({ expected = config.keybind, actual = e }) then
		return
	end

	if tes3.menuMode() then
		util.transferStacksFromMenu()
		return
	end

	if not config.placeStacksOutOfMenu then return end

	---@type placeStacks.transferredTable[]
	local transferredList = {}
	for _, container in ipairs(util.getNearbyContainers()) do
		local transferred = util.transferStacks(tes3.player, container)
		if not transferred then
			goto continue
		end

		table.insert(transferredList, { container = container, list = transferred })
		:: continue ::
	end

	log:debug("Transfer multiple - transferred = %s", inspect, transferredList)

	if table.empty(transferredList) then
		tes3.messageBox(i18n("No items transferred!"))
		return
	end

	if config.shortTransferReport then
		---@type string[]
		local containerNames = {}
		for _, record in ipairs(transferredList) do
			table.insert(containerNames, record.container.object.name)
		end
		local size = #containerNames
		local str = containerNames[size]
		containerNames[size] = nil
		if #containerNames >= 1 then
			str = string.format(i18n("%s and %s"),
				table.concat(containerNames, ", "), str)
		end

		tes3.messageBox(i18n("Stored in: %s."), str)
	end

	if not config.detailedTransferReport then
		return
	end
	ui.createTransferNotification(transferredList)
end
event.register(tes3.event.keyDown, keybindComponent)
