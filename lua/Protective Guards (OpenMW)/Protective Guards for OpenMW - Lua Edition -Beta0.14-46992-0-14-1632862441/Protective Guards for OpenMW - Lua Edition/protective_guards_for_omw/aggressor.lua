local self = require("openmw.self")
local nearby = require("openmw.nearby")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local settings = require('openmw.settings')
local functions = require("protective_guards_for_omw.functions")
local bL = require("protective_guards_for_omw.blacklistedareas")
local outlawLevel = settings.getGMST("iCrimeThreshold") * settings.getGMST("iCrimeThresholdMultiplier")
local timer = 0
local firstRun = false
local previousCell
local playerRef
local resistedArrest = false --only relevant if script is attached on guards
local pacifist = 0 --1no, 2yes
local crimeLevel = 0




--todo
--use AI package to better detect NPC AI
--use crime event to detect crime
--use attack event to detect attack
--use a method to get crime level
--use a method to determine hostility status towards an actor
--some stuff


--this is an alpha version serving as a placeholder for future updates
--for now various methods is used to detect AI behavior
--not recommended for mass combat because the game engine performs poorly on that situation now



local function searchGuardsAdjacentCells(target)

    if not firstRun then
        return
    end
    local doorDistCheck = 8192
    local tempTab = {}
    if self.cell.isExterior then
        doorDistCheck = doorDistCheck / 5
    end
    for _, door in nearby.doors:ipairs() do
        if
            door.destCell ~= previousCell and door.isTeleport and
            (door.position - self.position):length() < doorDistCheck
        then
            tempTab[tostring(door)] = door
        end
    end
    for _, door in pairs(tempTab) do
        core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {door, target})
    end
    firstRun = false
end

local function selfIsHostileCheck()
    if bL[self.cell.name] then
        return
    end
    if not self:getCombatTarget() or not self:canMove() then
        firstRun = true
        return
    end

    local guardsNearby = false
    local distCheck = 8192
    if self.cell.isExterior then
        distCheck = distCheck / 2
    end
    if self:getCombatTarget().type == "Player" then
        playerRef = self:getCombatTarget()
        crimeLevel = playerRef.inventory:countOf("PG_TrigCrime")

		if functions.isGuard(self) then
			guardsNearby = true
		end

        for _, actor in nearby.actors:ipairs() do
            if
                actor ~= self.object and actor.type == "NPC" and
                (actor.position - playerRef.position):length() < distCheck and
                functions.isGuard(actor)
            then
				guardsNearby = true
                if crimeLevel > 0 and functions.isGuard(self) then
                    actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {playerRef})
                    --searchGuardsAdjacentCells(playerRef) bad
                    resistedArrest = true
                elseif crimeLevel == 0 and not resistedArrest then
                    if math.random(5) < 3 then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {self.object})
                        searchGuardsAdjacentCells(self.object)
                    end
                elseif pacifist == 1 and self.type ~= "Creature" then
                    actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {self.object})
                elseif crimeLevel >= outlawLevel and not functions.isGuard(self) and pacifist == 2 then
                    actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {playerRef})
					searchGuardsAdjacentCells(playerRef)
                end
            end
        end

        if not guardsNearby then
            if not functions.isGuard(self) then
                if crimeLevel > 0 then
                    searchGuardsAdjacentCells(playerRef)
                else
                    searchGuardsAdjacentCells(self.object)
                end
            end
		else

                if crimeLevel > 0 then
                    searchGuardsAdjacentCells(playerRef)
                else
                    --do nothing
                end

        end


    end

    guardsNearby = false
end

aux.runEveryNSeconds(0.5, selfIsHostileCheck)


return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(0.5, selfIsHostileCheck)
        end,
        onInactive = function()
            firstRun = true
            previousCell = self.cell
        end,
		onActive = function()
			if self:getCombatTarget() and self:getCombatTarget().type == "Player" then
				if crimeLevel > 0 and not functions.isGuard(self) and pacifist == 2 then
					for _, actor in nearby.actors:ipairs() do
						if functions.isGuard(actor) then
							actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {playerRef})
						end
					end
				end
			end
		end,
        onUpdate = function(dt)
            if not self.type == "NPC" then return end

            if timer < 3 then
                timer = timer + dt
            else
                firstRun = true
                timer = 0
            end


            if resistedArrest then
				playerRef:sendEvent("ProtectiveGuards_notifications_eqnx", {self.cell.name})
                if playerRef.inventory:countOf("PG_TrigCrime") == 0 then
                    resistedArrest = false
                    self:stopCombat()
                end
            end


			--awkward way to get the player object
            if not playerRef then
				playerRef = nearby.selectObjects(query.actors:where(query.OBJECT.type:eq("Player")))[1]
			end

			if pacifist == 0 then
                if self:getCombatTarget() then
                    pacifist = 1 --initialy hostile
                else
                    pacifist = 2 --initialy peaceful
                end
            end
        end
    }
}












