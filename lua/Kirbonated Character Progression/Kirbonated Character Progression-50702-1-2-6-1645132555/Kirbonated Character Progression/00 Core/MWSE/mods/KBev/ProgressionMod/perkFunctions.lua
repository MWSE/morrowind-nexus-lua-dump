--[[
	--=General Guidelines for making perks=--
	Obviously each perk is going to have it's own unique programming challenges, but there are certain tips that may lead to a smoother experience
	
	spells: A relatively easy way to make a perk work is by attaching a spell to it. You can use Magicka Expanded to create magic effects with custom scripted properties
	--NOTE: Magicka Expanded doesn't support "ability" type spells, so you'll have to use the standard tes3spell.create() function to make abilities with custom effects.
	--extra note: make sure you create your spell BEFORE a save game is loaded, or else you may have persistence issues with save games
	
	events: a custom event, "KBProgression:perkActivated" gets sent whenever a perk is marked as activated using the activatePerk() function.
	-You can use this event for perk effects that only apply once, such as perks that grant permanent stat bonuses
	another event, "KBProgression:perkDeactivated" gets sent when a perk is deactivated using the deactivatePerk() function.
	-both of these events included a property "perk" which is the perkID of the perk that was activated
	-use this event to remove any effects that are added by the perkActivated event
	-DO NOT set the activate flag on a perk manually, this will not send the perkActivate/Deactivated events, and won't add/remove spells from the player.
	-Be careful when using these events, because they don't get fired when save games are loaded, so make sure you have contingencies in place to ensure your functions still work correctly between saveloads
	
	playerData:hasPerk(id): this is a function in interop.player, and returns whether or not the player has the perk specified. This will return true even if the perk is deactivated
	
	getPerk(id): this returns the perkdata for the specified perkID, useful for checking the activated variable
	
	activatePerk(id): marks the specified perk as activated, adds any relevant spells to the player, and triggers a perkActivated event
	deactivatePerk(id): marks the specified perk as deactivated, removes any relevant spells from the player, and triggers a perkDeactivated event
	
]]


local common = require("KBev.ProgressionMod.common")
local public = {}

--[[
Perk Parameters
values must be declared unless otherwise specified
	
	id (string): unique identifier (ex. "kb_perk_magickaWell")
	name (string): Display name for perk (ex. "Magicka Well")
	description (string): Description to show in the perk selection menu
	
	(optional)lvlReq(number): The character level that must be reached before the perk can be selected. defaults to 1 if not specified
	(optional)attributeReq(table): a table of required primary attribute values. ex) {attributeReq = {intelligence = 60, willpower = 60}}
	(optional)skillReq(table): a table of skill requirements for the perk. ex) {skillReq = {shortBlade = 50, athletics = 25}}
	(optional)werewolfReq(boolean) whether or not the perk is restricted to werewolves
	(optional)vampireReq(boolean) whether or not the perk is restricted to vampires
	(optional)perkReq(table): a table of perkIDs that the player must have to select the perk. ex) {perkReq = {"kb_perk_SoulSnatcher", "kb_perk_attunement"}}
	
	(optional)perkExclude(table): a table of perkIDs that will block this perk from being selected. ex) {perkExclude = {"kb_perk_atronachAffinity"}}
	
	(optional)hideInMenu(boolean): if set to true, the perk will be hidden from the player unless they meet the requirements to acquire it
	
	(optional)delayActivation(boolean): This can be set to true to prevent the perkActivate function from firing immediately upon granting the perk to the player. May be useful for complex scripted perk effects
	(optional)spells(table)[tes3spell]: list of spells/powers/abilities to add to the player upon selecting the perk
]]

public.createPerk = function(params)
	if common.perkList[params.id] then
		common.info("Perk ID \"" .. params.id .. "\" already present. No data was overwritten")
	else
	common.perkList[params.id] = {
		name = params.name,
		description = params.description,
		
		lvlReq = params.lvlReq or 2,
		attributeReq = params.attributeReq or false,
		skillReq = params.skillReq or false,
		werewolfReq = params.werewolfReq or false,
		vampireReq = params.vampireReq or false,
		perkReq = params.perkReq or false,
		
		customReq = params.CustomReq,
		customReqText = params.CustomReqText or false,
		
		perkExclude = params.perkExclude or false,
		
		
		hideInMenu = params.hideInMenu or false,
		
		
		delayActivation = params.delayActivation or false,
		spells = params.spells or false,
		
		activated = false --is set to true when the perk is activated
	}
	end
	return common.perkList[params.id]
end

public.activatePerk = function(params)
	if not common.perkList[params.id] then common.err("Attempted to activate nonexistent perk \"" .. params.id .. "\"") return false end
	if common.perkList[params.id].spells then 
		for i, s in ipairs(common.perkList[params.id].spells) do
			tes3.addSpell({reference = tes3.player, spell = s}) 
		end
	end
	common.perkList[params.id].activated = true
	tes3.player.data.KBProgression.activatedPerks[params.id] = true
	tes3.mobilePlayer:updateDerivedStatistics()
	event.trigger("KBProgression:perkActivated", {perk = params.id})
	return true
end
event.register("KBProgression:activatePerk", public.activatePerk)

public.deactivatePerk = function(params)
	if not common.perkList[params.id] then common.err("Attempted to deactivate nonexistent perk \"" .. params.id .. "\"") return false end
	if common.perkList[params.id].spells then 
		for i, s in ipairs(common.perkList[params.id].spells) do
			if tes3.hasSpell{reference = tes3.player, spell = s} then
				tes3.removeSpell({reference = tes3.player, spell = s}) 
			end
		end
	end
	common.perkList[params.id].activated = false
	tes3.player.data.KBProgression.activatedPerks[params.id] = nil
	tes3.mobilePlayer:updateDerivedStatistics()
	event.trigger("KBProgression:perkDeactivated", {perk = params.id})
	return true
end
event.register("KBProgression:deactivatePerk", public.deactivatePerk)

public.getPerk = function(id)
	if not common.perkList[id] then 
		return false
	end
	return common.perkList[id]
end

return public