--[[ Convert cloth bolts & pieces into cloth prepared for sewing
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for smithing materials per filters: item class, material
local scrapRecipes = require("Morrowind_Crafting_3.Shears.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")
local this = {}
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel, UID_spacerLabel
local UID_buttonClass, UID_buttonGroup, UID_filterText
local sClass, sGroup = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc
local dq = false
local onFilterClass, onFilterGroup
local SelectScrappingItem -- Must be forward-declared like this
local smithTextFilter = ""
local sortBy = "Normal"

-- Register IDs
UID_ListPane = tes3ui.registerID("ShearsMenu::List")
UID_ListLabel = tes3ui.registerID("ShearsMenu::ListBlockLabel")
UID_filterText = tes3ui.registerID("ShearsMenu::Input")
UID_spacerLabel = tes3ui.registerID("spacerLabel")

function this.init()
	this.id_menu = tes3ui.registerID("Shears")
	this.id_menulist = tes3ui.registerID("Shearslist")
	this.id_cancel = tes3ui.registerID("Shears_cancel")
	this.id_scrap = tes3ui.registerID("btnScrap")
end

local function filterScrapCandidates(e)
    local isit = false
    for idx, x in ipairs(scrapRecipes) do
        if x.id == e.item.id then
			isit = true
			break
        end
    end
    return isit
end

local function onScrapInventoryItemSelected(e)
	config = mwse.loadConfig(configPath)
    local batchSize, gmhammers, yieldcount, timerCount, batchCap
    if e.item == nil then
        return false
	end
	if mc3_timeOut then 
		-- do nothing
	else
  	  	for idx, x in ipairs(scrapRecipes) do
			if x.id == e.item.id then
				timerCount = x.taskTime
                --We got one!   Now ensure that the user has enough to actually scrap
				batchSize = math.floor(e.count / x.qtyReq)
				batchCap = math.floor(24 / timerCount)
				if (batchSize > batchCap) and (config.tasktime == true) then
					batchSize = batchCap
					tes3.messageBox({ message = "You can only manage to cut out "..batchSize.." in a 24-hour period."})
				end
  	            yieldcount = x.yieldCount
    	        --Got this far, must be enough. Add the material to the player's inventory
    	        tes3.addItem({ reference = tes3.player, item = x.yieldID, count = batchSize * yieldcount, playSound = false })
    	        -- Now remove the item(s) from player's inventory
    	        tes3.removeItem({ reference = tes3.player, item = e.item, count = batchSize * x.qtyReq, playSound = false })
                tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
            end
		end
		mc.timePass(timerCount * batchSize)
	end
    ttemp = tes3ui.forcePlayerInventoryUpdate
    timer.frame.delayOneFrame(function()
		SelectScrappingItem()
	end)
end
 
SelectScrappingItem = function()
    tes3ui.showInventorySelectMenu({
		id = "ShearsMenuWindow",
        title = "Select Item(s) to Cut",
        noResultsText = "No usable items found.",
        filter = filterScrapCandidates,
		height = 720,
        callback = onScrapInventoryItemSelected
    })
end

-- Buttons
-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("ShearsMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onEquip(e)
	if e.item.id == "misc_shears_01" then
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
		SelectScrappingItem()
		return false
	end
end
event.register("equip", onEquip)