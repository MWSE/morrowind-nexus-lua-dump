local types = require("openmw.types")
local activation = require('openmw.interfaces').Activation

local orePatterns = {
	"rock_",
	"_mine_ore",
}

local pickList = {
	"BM Nordic Pick",
	"miner's pick",
	"T_De_Ebony_Pickaxe_01",
	"AB_w_FlintPickaxe",
	"AB_w_ToolEbonyPick",
}

local function isOreContainer(object)
	for _, pattern in pairs(orePatterns) do
		if object.recordId:find(pattern) then
			return true
		end
	end

	return false
end

local function hasPick(actor)
	for _, item in pairs(pickList) do
		if types.Actor.inventory(actor):find(item) then
			return true
		end
	end

	return false
end

local function isMuckspunge(object)
	if object.recordId:find("flora_muckspunge_") then
		return true
	end

	return false
end

local function hasMuckshovel(actor)
	if types.Actor.inventory(actor):find("misc_de_muck_shovel_01") then
		return true
	end

	return false
end

local function handlerHarvest(object, actor)
	if isOreContainer(object) then
		if not hasPick(actor) then
			actor:sendEvent("ShowMessage", {message = "You don't have the tools to do anything with this."})
			return false
		end
	end

	if isMuckspunge(object) then
		if not hasMuckshovel(actor) then
			actor:sendEvent("ShowMessage", {message = "You don't have the tools to do anything with this."})
			return false
		end
	end

	return true

end

local function onInit()
	activation.addHandlerForType(types.Container, handlerHarvest)
end

return {
	engineHandlers = { onInit = onInit, onLoad = onInit }
}