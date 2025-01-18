local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local NPC = require('openmw.types').NPC
local doOnce = 0
local selfPos = self.position

    local stopFn = time.runRepeatedly(function() 
        if NPC.isWerewolf(nearby.players[1]) then
       types.Actor.spells(self):add('detd_Marked_Pacify')
        end
        if NPC.isWerewolf(nearby.players[1])==false then
           -- local ringObject = types.Actor.getEquipment(self, 12)
            local inventorySelf = types.Actor.inventory(self.object)
            local ringObject = inventorySelf:find('detd_ring_seenwerewolf')
           
             if types.Actor.activeSpells(self):isSpellActive('detd_Marked_Pacify') == true then
                AI.removePackages("Combat")
                types.Actor.spells(self):remove('detd_Marked_Pacify')
             end

             if ringObject ~= nil and doOnce == 0 then
                AI.removePackages("Combat")
                types.Actor.spells(self):remove('detd_Marked_Pacify')
                doOnce = 1
             end

            if AI.getActivePackage(self) == nil then
                types.Actor.spells(self):remove('detd_Marked_Pacify')
            end
    end
       end,
                                        5 * time.second)  -- print 'Test' every 5 seconds

                        