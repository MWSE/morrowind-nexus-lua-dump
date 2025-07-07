local self  = require('openmw.self')
local types = require('openmw.types')
local isDead          = types.Actor.isDead
local isOnGround      = types.Actor.isOnGround
local creatureRecord  = types.Creature.record
local npcRecord, Npc  = types.NPC.record, types.NPC
local showMessage     = require('openmw.ui').showMessage
local sendGlobalEvent = require('openmw.core').sendGlobalEvent

local myName = npcRecord(self).name
local infoStart = myName .. ":  Stay close."
local infoStop  = myName .. ":  Not so close."
local bond = {}

local function release(subj, dismissed)
   bond[subj.id] = nil
   sendGlobalEvent('ykResTelefollowStop', subj)
   showMessage(
      dismissed and infoStop or
      (subj.type == Npc and npcRecord or creatureRecord)(subj).name ..
      (dismissed == nil and " stopped following." or " is gone."))
end

local function catchup()
   for _, subj in pairs(bond) do
      if subj.enabled and not isDead(subj) then
         subj:sendEvent('ykReqTelefollowStop', self)
         if isOnGround(self) then
            if self.cell:isInSameSpace(subj) then
               local dist = subj.position - self.position
               local len  = dist:length()
               if 999 < len then
                  sendGlobalEvent(
                     'ykReqTeleport', {
                        cell = self.cell.name,
                        pos  = self.position + dist * (333 / len),
                        obj  = subj,
                  })
            end else
                  sendGlobalEvent(
                     'ykReqTeleport', {
                        cell = self.cell.name,
                        pos  = self.position,
                        rot  = self.rotation,
                        obj  = subj,
                  })
      end end else
            release(subj, false)
end end end

require('openmw_aux.time').runRepeatedly(catchup, 1)
return {
   eventHandlers = {
      ykReqTelefollowStart = function(subj)
         if bond[subj.id] then else
            bond[subj.id] = subj
            showMessage(infoStart)
      end end,
      ykResTelefollowStop = release,
      ykReqTelefollowStop = function(subj)
         if bond[subj.id] then release(subj, true) end
      end,
   },
   engineHandlers = {
      onLoad = function(data) bond = data end,
      onSave = function() return bond end,
   },
}
