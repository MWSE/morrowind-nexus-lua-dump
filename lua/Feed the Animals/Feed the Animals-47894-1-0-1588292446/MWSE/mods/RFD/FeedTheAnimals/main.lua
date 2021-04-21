--[[Feed The Animals
	mod lets you feed peaceful creatures

	authors = {
	["OperatorJack"] = {scripting, troubleshooting},
	["RedFurryDemon"] = {scripting}}

	in case of bugs, please ping RFD on discord
]]--

local creatures = require("RFD.FeedTheAnimals.creatures")

local key
local animal

local function showCreatureMenu(animal)
	tes3ui.showInventorySelectMenu{
	title = "Feed creature",
	noResultsText = string.format("You do not have any appropriate food."),
	filter = function(e)
		return (e.item.objectType == tes3.objectType.ingredient and creatures.food[key][e.item.id] == true)
		end,
	callback = function(e)
        if e.item then
			tes3.player.object.inventory:removeItem{
                mobile = tes3.mobilePlayer,
                item = e.item,
                itemData = e.itemData
            }
			tes3ui.forcePlayerInventoryUpdate()
			animal.fight = (animal.fight - 10)
			animal.flee = (animal.flee - 10)
		end
		end
	}
end

local function activateCreature(e)
    if (e.activator ~= tes3.player) then
        return
    end
	if (e.target.object.objectType ~= tes3.objectType.creature) then
		return
	end
	animal = e.target.mobile
	if (animal.health.current <= 0) then
		return
	else
	local crMesh = e.target.object.mesh:lower()
		for creatureType, creatureMeshes in pairs(creatures.mesh) do
			if (creatureMeshes[crMesh]) then
				key = creatureMeshes.id
				showCreatureMenu(animal)
			end
		end
	end
end

local function initialized()
	event.register("activate", activateCreature)
	mwse.log("[Feed The Animals] initialized")
end

event.register("initialized", initialized)