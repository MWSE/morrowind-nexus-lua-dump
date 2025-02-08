local I = require("openmw.interfaces")
local types = require("openmw.types")
local Actor = types.Actor
local NPC = types.NPC

local ui = require("openmw.ui")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local storage = require("openmw.storage")
local self = require("openmw.self")
local blAreas = require("scripts/protective_guards_for_omw/blacklistedAreas")
local section = storage.playerSection("Settings_PGFOMW_Options_Key_KINDI")
local modInfo = require("scripts.protective_guards_for_omw.modInfo")
local pursuit_for_omw = false

-- you can edit factions families as you want. Just write the same string (example: "IMPfamily") for a given family. Factions are IDs in lowercase.
-- if you don't want families, just leave the array empty:  local factionsFamilies = {}
local factionsFamilies = {
	["imperial legion"] = "IMPfamily", 
	["census and excise"] = "IMPfamily", 
	["imperial knights"] = "IMPfamily", 
	["royal guard"] = "IMPfamily", 
	["east empire company"] = "IMPfamily",
	["temple"] = "TEMfamily",
	["redoran"] = "TEMfamily",
	}

local factions_targets = {} -- Array to memorize the target for each faction
local factions_witnes = {} -- Array to memorize a witness guard for each faction (useful to give context informations)

local function onSave()
    return {
        FT = factions_targets,
        FW = factions_witnes
    }
end

local function onLoad(data)
	if data then
		factions_targets = data.FT
		factions_witnes = data.FW
	end
end

local function searchGuardsAdjacentCells(attacker)
    for _, door in pairs(nearby.doors) do
        if door.type.isTeleport(door) and (door.position - e.actor.position):length() < 2000 then
            core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {
                door,
                attacker,
                section:get("Search Guard of Class"):lower()
            })
        end
    end
end

local function nearbyGuards()
    local classes = section:get("Search Guard of Class"):lower()
    return aux_util.mapFilter(nearby.actors, function(actor)
        local actorClass = actor.type.record(actor).class
        return actorClass and types.Actor.isDead(actor) == false and actor.enabled and classes:find(actorClass:lower())
    end)
end

local function debug(actor, e)
    local guard = actor.type.record(actor)
    local agg = e.actor.type.record(e.actor)
    if storage.playerSection("Settings_PGFOMW_ZDebug_Key_KINDI"):get("Debug") then
        ui.showMessage(string.format("%s of %s class from %s attacks %s", guard.name, guard.class, actor.cell.name, agg.name))
    end
end


return {
    engineHandlers = {
		onLoad = onLoad,
		onSave = onSave,
        onActive = function()
            assert(core.API_REVISION >= modInfo.MIN_API, "[Protective Guards] mod requires OpenMW version 0.48 or newer!")
        end
    },
    eventHandlers = {
        ProtectiveGuards_thisActorIsAttackedBy_eqnx = function(e)
            if not section:get("Mod Status") then
                return
            end
            if blAreas[e.actor.cell.name] then
                return
            end

            local intDist = section:get("Search Guard Distance Interiors")
            local extDist = section:get("Search Guard Distance Exteriors")

			-- we memorize if the attacker/defensor are guards
			local guardList = nearbyGuards()
			local aggIsGuard = false
		    local victIsGuard = false
		    for _, guard_ in pairs(guardList) do
				if guard_.id == e.actor.id then aggIsGuard = true end
				if guard_.id == e.vict.id then victIsGuard = true end
				if aggIsGuard == true and victIsGuard == true then break end
			end
			
			-- we memorize if the defensor is the player or no
			local playerVictim = false
			if e.vict.type == types.Player then 
				playerVictim = true
			end
						
            for _, actorG in pairs(guardList) do
				
				if actorG ~= e.actor and actorG ~= e.vict and Actor.getStance(actorG) == 0 and ((actorG.position - e.actor.position):length() < (e.actor.cell.isExterior and extDist or intDist)) then
	
					local target = e.actor -- default value
				    local guardFaction = NPC.getFactions(actorG)[1]
				    					
					local factionMem = nil
					
					-- if guard has a faction we are going to determine his "faction family"
					local guardFactionFamily
				    if guardFaction ~= nil then
				    
						guardFactionFamily = factionsFamilies[guardFaction]
						if guardFactionFamily == nil then
							guardFactionFamily = guardFaction
						end
						
						local factionTarget = factions_targets[guardFactionFamily]
						local factionWitnes = factions_witnes[guardFactionFamily]
						
						-- if faction target memorization is not valid, or if we are in a not-valid/unclear context, then we (re-)determine faction target memorization...
						if factionTarget == nil
						 or Actor.isDead(factionTarget)
						  or not factionTarget.enabled
						   or not Actor.isInActorsProcessingRange(factionTarget)
						    or Actor.getStance(factionTarget) == 0
						     or ( factionTarget ~= e.vict and factionTarget ~= e.actor )
						      or Actor.isDead(factionWitnes)
						       or not factionWitnes.enabled
						        or not Actor.isInActorsProcessingRange(factionWitnes)
						         or Actor.getStance(factionWitnes) == 0 then
				
							factions_targets[guardFactionFamily] = e.actor -- default value
							factions_witnes[guardFactionFamily] = actorG
							factionMem = true -- so we know we have passed through the "rememorization" process
							
							local aggressorFaction = NPC.getFactions(e.actor)[1]
							local aggFactionFamily = factionsFamilies[aggressorFaction]
							if aggFactionFamily == nil then
								aggFactionFamily = aggressorFaction
							end
							
							local victimFaction
							local victFactionFamily = nil
							if playerVictim == false then
								victimFaction = NPC.getFactions(e.vict)[1]
								victFactionFamily = factionsFamilies[victimFaction]
								if victFactionFamily == nil then
									victFactionFamily = victimFaction
								end
							end
							
							-- if guard Faction Family = the attacker faction family
							if guardFactionFamily == aggFactionFamily then
								local victimRank = 0
								-- if the defensor is the player then we are going to determine his factions&ranks in relation to the attacker
								if playerVictim == true then
									local rank
									for _, faction_ in pairs(NPC.getFactions(e.vict)) do
										if aggressorFaction == faction_ or aggFactionFamily == factionsFamilies[faction_] then
											victFactionFamily = aggFactionFamily
											rank = NPC.getFactionRank(e.vict, faction_)
											if faction_ == "royal guard" then -- i count a "royal guard" rank as 2 ranks
												rank = rank * 2					-- because they have only 2 ranks
											end
											if rank > victimRank then
												victimRank = rank
											end
										end
									end
								end
								-- if guard Faction Family = the attacker faction family = the defensor faction family
								-- then we are going to determine who is the best "ranked" between attacker and defensor
								if victFactionFamily == aggFactionFamily then
									if playerVictim == false then
										victimRank = NPC.getFactionRank(e.vict, NPC.getFactions(e.vict)[1])
										if victimFaction == "royal guard" then
											victimRank = victimRank * 2
										end
									end
									local aggressorRank = NPC.getFactionRank(e.actor, aggressorFaction)
									if aggressorFaction == "royal guard" then
										aggressorRank = aggressorRank * 2
									end
				
									if aggressorRank > victimRank or (aggressorRank == victimRank and aggIsGuard and not victIsGuard) then -- ...or (equals ranks, and attacker is a guard and defensor isn't a guard) then...
										target = e.vict -- guard is going to attack the defensor
										factions_targets[guardFactionFamily] = e.vict -- memorization of the target for that faction
									
									-- if ranks are equal and they are both guards, then guard isn't going to intervene...
									elseif aggressorRank == victimRank and aggIsGuard and victIsGuard then
										target = nil
										factions_targets[guardFactionFamily] = factionTarget -- backup
										factions_witnes[guardFactionFamily] = factionWitnes -- backup
									end
									
								else -- (guard Faction Family = the attacker faction family) <> the defensor faction family
									target = e.vict
									factions_targets[guardFactionFamily] = e.vict
								end
								
							-- (guard Faction Family <> the attacker faction family)
							elseif aggIsGuard and not victIsGuard then -- if attacker is a guard and defensor isn't a guard...
				
								-- then we have to determine the defensor faction family related to guard if defensor=player
								if playerVictim == true then
									for _, faction_ in pairs(NPC.getFactions(e.vict)) do
										if faction_ == guardFaction or factionsFamilies[faction_] == guardFactionFamily then
											victFactionFamily = guardFactionFamily
											break
										end
									end
								end
								-- ...and if defensor faction family is also <> guard Faction Family, then ...
								if victFactionFamily ~= guardFactionFamily then
									target = e.vict
									factions_targets[guardFactionFamily] = e.vict
								end
								
							-- (guard Faction Family <> the attacker faction family)
							elseif aggIsGuard and victIsGuard then -- if attacker&defensor are guards...
								if playerVictim == true then
									for _, faction_ in pairs(NPC.getFactions(e.vict)) do
										if faction_ == guardFaction or factionsFamilies[faction_] == guardFactionFamily then
											victFactionFamily = guardFactionFamily
											break
										end
									end
								end
								-- ...and if defensor faction family is also <> guard Faction Family, then guard isn't going to intervene...
								if victFactionFamily ~= guardFactionFamily then
									target = nil
									factions_targets[guardFactionFamily] = factionTarget -- backup
									factions_witnes[guardFactionFamily] = factionWitnes -- backup
								end
							end
							
						else -- factionTarget is valid
							target = factionTarget
						end
				    
				    -- (guard has no faction), and if attacker is a guard and defensor isn't a guard then...
					elseif aggIsGuard and not victIsGuard then
						target = e.vict 
						
				    -- (guard has no faction), and if attacker&defensor are guards then...
					elseif aggIsGuard and victIsGuard then
						target = nil
					end
					
					-- test for player crime 
					if e.vict.id == self.id and target == e.actor then
						if types.Player.getCrimeLevel then
							core.sendGlobalEvent("ProtectiveGuards_oldVersionCleanup_eqnx", {
							actor = self
							})
							if types.Player.getCrimeLevel(self) > 10 then
								target = nil
								if factionMem then
									factions_targets[guardFactionFamily] = factionTarget -- backup
									factions_witnes[guardFactionFamily] = factionWitnes -- backup
								end
							end
						elseif types.Actor.inventory(self):countOf("PG_TrigCrime") > 10 then
						-- not used in v0.49. Kept for backwards compatiblity
							target = nil
							if factionMem then
								factions_targets[guardFactionFamily] = factionTarget -- backup
								factions_witnes[guardFactionFamily] = factionWitnes -- backup
							end
						end
					end

					--guards dislike very much werewolf in morrowind (only for v0.49 and newer)
					if NPC.isWerewolf then
						local aggWerewolf = NPC.isWerewolf(e.actor)
						local victWerewolf = NPC.isWerewolf(e.vict)
						-- if guard must protect a werewolf, and the other fighter isn't a werewolf, he won't protect...
						if (victWerewolf and not aggWerewolf and target == e.actor) or (aggWerewolf and not victWerewolf and target == e.vict) then
							target = nil
							if factionMem then
								factions_targets[guardFactionFamily] = factionTarget -- backup
								factions_witnes[guardFactionFamily] = factionWitnes -- backup
							end
						-- guards dislike vampirism (but less than werewolves...) in morrowind
						elseif Actor.activeEffects then
							local aggVampirism = Actor.activeEffects(e.actor):getEffect("Vampirism").magnitude
							local victVampirism = Actor.activeEffects(e.vict):getEffect("Vampirism").magnitude
							-- if guard must protect a "vampire", and the other fighter isn't a vampire, he won't protect...
							if (victVampirism > 0 and aggVampirism <= 0 and target == e.actor) or (aggVampirism > 0 and victVampirism <= 0 and target == e.vict) then
								-- if the vampire fight back, guard will attack him, else he'll do nothing...
								if target == e.vict and Actor.getStance(e.actor) > 0 then
									target = e.actor
								elseif target == e.actor and Actor.getStance(e.vict) > 0 then
									target = e.vict
								else
									target = nil
								end
								if factionMem then
									factions_targets[guardFactionFamily] = factionTarget -- backup
									factions_witnes[guardFactionFamily] = factionWitnes -- backup
								end
							end
						end
					end
					
					if target ~= nil then
						actorG:sendEvent("ProtectiveGuards_alertGuard_eqnx", {
								attacker = target,
								isImmune = e.isImmune
							})
					end
					
					debug(actorG, e)
				end
			end
			
			-- future
            -- check if current cell has peaceful npc, playsound for help, goes to a nearby adjacent cell, and alert guards
            if not e.isImmune and section:get("Search Guard In Nearby Adjacent Cells") and pursuit_for_omw then
                searchGuardsAdjacentCells(e.actor)
            end
        end,
        
        Pursuit_IsInstalled_eqnx = function(e)
            pursuit_for_omw = e.isInstalled
            if pursuit_for_omw then
                print("Pursuit and Protective Guards interaction established")
                -- ui.showMessage("Pursuit and Protective Guards interaction established")
            end
        end
	}
}
