local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local core = require('openmw.core')
local storage = require('openmw.storage')
local types = require('openmw.types')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local world = require('openmw.world')


--affecting bug: https://gitlab.com/OpenMW/openmw/-/issues/7663


--local ItemUsage = require('openmw.interfaces').ItemUsage
local Activation = require('openmw.interfaces').Activation
local Controls = require('openmw.interfaces').Controls
local I = require('openmw.interfaces')

local userRecipes = {}

local startWithCube = true
local startWithRecipes = true

local theCube = nil
local cubeChest = world.getObjectByFormId(core.getFormId('the_Arcane_Academy_of_Venarius_School_Alpha_02.esm', 7004))
local theBook = nil



--TODO: update this to use player for multiplayer when the time comes
--we cant just keep a reference, because the object is ""deleted"" when we teleport it to another cell.
local function getCubeChest()
	return cubeChest
end

local function getRecipeBook()
	return theBook
end

local function onPlayerAdded(player)
	--ask the player if he's ever had a cube, action continued in e_rx_hadCube below
	player:sendEvent("e_tx_hadCube", nil)
end

local function getCubeContents(player)
	return types.Container.inventory(getCubeChest()):getAll()
end

--update to get the cube specefic to the player, when multiplayer becomes a thing
local function getCube()
	return theCube
end


local function hasCube(player)
	local inv = types.Actor.inventory(player):getAll(types.Miscellaneous)

	for _, item in pairs(inv) do
		if item.recordId == "aav_transmutecube" then
			return true
		end
	end

	return false
end

--add to ItemUse handler when it becomes available
--maybe update container UI to include a transmute button.
local function openCube(player)
	if hasCube(player) == false then print("player did not have cube.") return false end
	cubeChest = getCubeChest(player)
	player:sendEvent("event_openCube", {container = cubeChest})

	return true
end

local function removeLastLetter(str)
	return str:sub(1, -2)
end

local function craftRecipe(player, recordID, count)
	cubeChest = getCubeChest(player)
	local inv = types.Container.inventory(cubeChest):getAll()

	--create new item and jam it into the cube
	--dont bork if item doesnt exist
    local success, result = pcall(function()
        return world.createObject(recordID, count)
    end)

    if success then
    	print("created: " .. recordID)
        newItem = result
    else
    	print("failed to create item: " .. recordID)
        return
    end

	--we've already checked that the stacksize and ingredients are correct. so just nuke the items.
	--and creating the item didnt fail.
	for _, item in pairs(inv) do
		item:remove()
	end

	newItem:moveInto(types.Container.inventory(cubeChest))
	core.sound.playSound3d("alteration cast", player)

--api call not out yet. waiting.
--	async:newUnsavableSimulationTimer(0.2, function()  
--		core.sound.playSound3d(newItem.pickupSound, player)
--	end)

	player:sendEvent("event_openCube", {container = cubeChest})
end

local function checkModRecipes(player)
	--i exist only to be overridden by a mod using the interface.
	return false
end

local function checkUserRecipes(player)
	local found  = true
	cubeChest = getCubeChest(player)
	local inv = types.Container.inventory(cubeChest):getAll()

	if #inv < 1 then return end --nothing in the cube, dont index out of boundts plz

	if #userRecipes < 1 then return false end

	for _, item in pairs(inv) do

		for idx, recipe in pairs(userRecipes) do
			found = true
			
			ingredients = recipe["input"]
			product = recipe["output"]

			ingCount = 0
			for idx, _ in pairs(ingredients) do
				ingCount = ingCount + 1
			end

			if found == true then
				if ingCount ~= #inv then	--stupid workaround, because #ingredients is returning 0 for some reason
					found = false
				end
				if ingredients[item.recordId] == nil then
					found = false
				end
				if item.count ~= ingredients[item.recordId] then
					found = false
				end
			end

			if found == true then
				print("found was true")
				for item, item_count in pairs(product) do
					craftRecipe(player, item, item_count)
				end
				return true
			end	
		end
	end


	return false
end

local function transmuteCube(player)
	local inv = types.Container.inventory(getCubeChest(player)):getAll()

	local count = 1

	if #inv < 1 then return end --nothing in the cube, dont index out of boundts plz

	local recordID = nil

	local firstItem = inv[1]
	local recordName = firstItem.recordId
	local itemName = firstItem.type.record(firstItem).name

	print("recordName: " .. recordName)
	print("itemName: " .. itemName)

	if checkModRecipes(player) == true then
		return
	elseif checkUserRecipes(player) == true then
		return
	elseif string.sub(recordName, 1, 2) == "p_" then
		if #inv > 1 then print("inv greater than 1, ending.") return end
		if firstItem.count ~= 3 then print("itemcount not 3, ending.") return end

		local suffix = ""
		if recordName:match("_b") then			
			suffix = "c"
		elseif recordName:match("_c") then
			suffix = "s"
		elseif recordName:match("_s") then			
			suffix = "q"
		elseif recordName:match("_q") then
			suffix = "e"
		end

		local basePotion = removeLastLetter(firstItem.recordId)
		recordID = basePotion .. suffix
		print("recordID: " .. recordID)
	elseif recordName:match("ingred_") then
		if #inv ~= 2 then return end

		local secondItem = inv[2]
		if secondItem.recordId:match("arrow") then

			if secondItem.count ~= 50 and secondItem.count ~= 100 then return end --check how big a stacksize is

			count = secondItem.count

			if recordName == "ingred_bonemeal_01" then
				recordID = "bonemold arrow"
			elseif recordName == "ingred_raw_glass_01" then
				recordID = "glass arrow"
			elseif recordName == "ingred_raw_ebony_01" then
				recordID = "ebony arrow"
			elseif recordName == "ingred_scrap_metal_01" then
				recordID = "steel arrow"
			elseif recordName == "ingred_daedras_heart_01" then
				recordID = "daedric arrow"
			end
		end

	elseif recordName:match("soulgem") then
		print("name match soulgem")

		if #inv ~= 1 then return end
		if firstItem.count ~= 3 then return end
		if recordName == "misc_soulgem_petty" then
			recordID = "Misc_SoulGem_Lesser"
		elseif recordName == "misc_soulgem_lesser" then
			recordID = "Misc_SoulGem_Common"
		elseif recordName == "misc_soulgem_common" then
			recordID = "Misc_SoulGem_Greater"
		elseif recordName == "misc_soulgem_greater" then
			recordID = "Misc_SoulGem_Grand"
		end

	--todo add in recipe for bent probes
	elseif recordName:match("repair_prongs") then
		print("name match prongs")

		if #inv ~= 1 then return end
		if firstItem.count ~= 3 then return end

		recordID = "repair_journeyman_01"

	elseif recordName:match("apprentice") then
		if #inv ~= 1 then return end
		if firstItem.count ~= 3 then return end

		recordID = string.gsub(recordName, "apprentice", "journeyman")
	elseif recordName:match("journeyman") then
		if #inv ~= 1 then return end
		if firstItem.count ~= 3 then return end

		if recordName =="pick_journeyman_01" then
			recordID = "pick_master" --this doesnt work with a straight gsub. so special casing it
		else
			recordID = string.gsub(recordName, "journeyman", "master")
		end


	elseif recordName:match("ring") or recordName:match("amulet") then
		print("name match ring or amulet")

		if #inv == 1 then
			if firstItem.count == 3 then
				if recordName:match("common") then
					recordID = string.gsub(recordName, "common", "expensive")
				elseif recordName:match("expensive") then
					recordID = string.gsub(recordName, "expensive", "extravagant")
				elseif recordName:match("extravagant") then
					recordID = string.gsub(recordName, "extravagant", "exquisite")
				end
			end

		elseif #inv == 2 then
			local secondItem = inv[2]

			if firstItem.count == 3 then
				if secondItem.recordId:match("common") then
					if not recordName:match("gravedust") then return end
				end
				if secondItem.recordId:match("expensive") then
					if not recordName:match("bonemeal") then return end
				end
				if secondItem.recordId:match("extravagant") then
					if not recordName:match("ashsalt") then return end
				end
				if secondItem.recordId:match("exquisite") then
					if not recordName:match("frostsalt") then return end
				end
				if secondItem.recordId:match("ring") then
					recordID = string.gsub(recordName, "ring", "amulet")
				else
					recordID = string.gsub(recordName, "amulet", "ring")
				end
			end
		end
	end

	if recordID == nil then return end

	--everything checks out, create the damn thing
	craftRecipe(player, recordID, count)
end

local function event_openCube(player)
	openCube(player)
end

local function event_transmute(player)
	print("event_transmute hit.")
	transmuteCube(player)
end


--	settings = modStorage:asTable()["settings"]
local function e_rx_hadCube(data)

	--if player has already been given a cube, dont give them one on spawn
	if data.hadCube == true then return end
	print("--did not have cube. continuing")

	theCube = world.createObject("aav_transmutecube", 1)
	theBook = world.createObject("bk_dwemerCubeRecipes", 1)
	theBook:moveInto(types.Actor.inventory(data.player))
	theCube:moveInto(types.Actor.inventory(data.player))

	-- local cellItems = world.getCellByName("toddtest"):getAll(types.Container)
	-- cubeChest:teleport("toddtest", util.vector3(2035.569580078125, 3245.40771484375, -152.9093017578125))

--allow the cubeChest time to teleport.
	-- async:newUnsavableSimulationTimer(0.1, function()
	-- 	if startWithRecipes == true then
	-- 		print("1book: " .. tostring(theBook))							--shows item exists
	-- 		cubeChest = getCubeChest(data.player)
	-- 		print("1cubechest: " .. tostring(cubeChest))					--shows item exists
	-- 		theBook:moveInto(types.Container.inventory(cubeChest))			--shows item was deleted?!
	-- 		print("2book: " .. tostring(theBook))
	-- 	end

	-- 	--if we arent starting the player off with the cube, then at least shove one in a box for them
	-- 	if startWithCube == true then
	-- 	else
	-- 		theCube:moveInto(types.Container.inventory(cubeChest))
	-- 	end
	-- end)

	-- async:newUnsavableSimulationTimer(0.15, function()
		-- -- dirty hack to get around this https://gitlab.com/OpenMW/openmw/-/issues/7663
	-- 	theBook = types.Container.inventory(cubeChest):getAll(types.Book)[1]
	-- end)
end

local function onSave()
	for _, player in ipairs(world.players) do
		modStorage:set("ownedKeys", ownedKeys)
	end
end

local function onInit(initData)
	for fileName in vfs.pathsWithPrefix("recipes") do
		fileName = fileName:sub(1, -5)

		local recipes = require(fileName).recipes

		for idx, recipe in pairs(recipes) do
			table.insert(userRecipes, recipe)
		end
	end
end

local function setStartWithCube(isStart)
	startWithCube = isStart
end

local function setStartWithRecipeBook(isStart)
	startWithRecipes = isStart
end


--TODO save theCube variable, and load it when the game loads. its mobile, so we dont know which cell it will be in, unlike the chest
return { 
	interfaceName = "gnounc_transmuteCube",
	interface = {
		version = 1,
		setStartWithCube = setStartWithCube,
		setStartWithRecipeBook = setStartWithRecipeBook,
		hasCube = hasCube,
		openCube = openCube,
		getCube = getCube,
		getCubeChest = getCubeChest,
		getRecipeBook = getRecipeBook,
		craftRecipe = craftRecipe,
		getCubeContents = getCubeContents,
		checkUserRecipes = checkUserRecipes,
		checkModRecipes = checkModRecipes,
		transmutecube = transmuteCube
	},
	engineHandlers = {
		onInit = onInit,
		onPlayerAdded = onPlayerAdded
	},
	eventHandlers = {
		event_openCube = event_openCube,
		event_transmute = event_transmute,
		e_rx_hadCube = e_rx_hadCube
	}
}
