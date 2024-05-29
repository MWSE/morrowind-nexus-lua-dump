local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local NPC = require('openmw.types').NPC
local doOnce = 0
local selfPos = self.position

local idleTable = {
    idle2 = 60,
    idle3 = 20,
    idle4 = 10,
    idle5 = 10,
    idle6 = 0,
    idle7 = 0,
    idle8 = 0,
    idle9 = 0
}

    local stopFn = time.runRepeatedly(function() 
        if NPC.isWerewolf(nearby.players[1]) then
       types.Actor.spells(self):add('detd_Marked_Pacify')
        end
        if NPC.isWerewolf(nearby.players[1])==false then
           -- local ringObject = types.Actor.getEquipment(self, 12)
            local inventorySelf = types.Actor.inventory(self.object)
            local ringObject = inventorySelf:find('detd_ring_seenwerewolf')
           
             if types.Actor.activeSpells(self):isSpellActive('detd_Marked_Pacify') == true then
                AI.startPackage({cancelOther=true, type='Travel', destPosition = selfPos, isRepeat = false})
                types.Actor.spells(self):remove('detd_Marked_Pacify')
             end

             if ringObject ~= nil and doOnce == 0 then
                AI.startPackage({cancelOther=true, type='Travel', destPosition = selfPos, isRepeat = false})
                types.Actor.spells(self):remove('detd_Marked_Pacify')
                doOnce = 1
             end

            if AI.getActivePackage(self) == nil then
                AI.startPackage({cancelOther=true, type='Wander', distance = 1000, duration = 5 * time.hour,
                idle = idleTable, isRepeat = true})
            end
    end
       end,
                                        5 * time.second)  -- print 'Test' every 5 seconds

                        