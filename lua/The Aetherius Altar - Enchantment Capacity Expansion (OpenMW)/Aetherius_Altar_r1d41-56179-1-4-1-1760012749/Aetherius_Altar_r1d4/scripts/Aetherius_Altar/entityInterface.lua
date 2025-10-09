local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')

local creature2Talk = 'aetherius_altar_entity' --needs to be lower case since CS
local activator = 'aetherius_altar_entityactivator' --needs to be lower case since CS

return {
  engineHandlers = {
      onActivate = function(object, actor)
        if object.recordId ~= activator then return end
        if not types.Player.objectIsInstance(actor) then return end

        local theRealTarget
        for _, creature in ipairs(actor.cell:getAll()) do
          
            if creature.recordId == creature2Talk then
              theRealTarget = creature
              break
            end
        end

        --print(theRealTarget.recordId)
        actor:sendEvent('SetUiMode', { mode = 'Dialogue', target = theRealTarget })
      end,

      onActorActive = function(actor)
            -- If the entity is active, then progress quest as it is in the same cell as the player
            if actor.recordId == creature2Talk then
                player = world.players[1]
                if types.Player.quests(player)["aetherius_altar_quest"].stage < 10 then
                  types.Player.quests(player)["aetherius_altar_quest"]:addJournalEntry(10)
                end
            end
        end
  }
}