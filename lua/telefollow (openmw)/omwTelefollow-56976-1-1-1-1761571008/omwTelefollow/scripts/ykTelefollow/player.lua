local self  = require('openmw.self')
local types = require('openmw.types')
local isDead          = types.Actor.isDead
local isOnGround      = types.Actor.isOnGround
local creatureRecord  = types.Creature.record
local npcRecord, Npc  = types.NPC.record, types.NPC
local sendGlobalEvent = require('openmw.core').sendGlobalEvent
local showMessage = require('openmw.ui').showMessage
local v3 = require('openmw.util').vector3

local myName = npcRecord(self).name
local infoStart = myName .. ":  Stay close."
local infoStop  = myName .. ":  Not so close."
local bond = {}

local function release(subj, dismissed, expired)
   bond[subj.id] = nil
   if not expired then
      sendGlobalEvent('ykResTelefollowStop', subj)
   end
   showMessage(
      dismissed and infoStop or
      (subj.type == Npc and npcRecord or creatureRecord)(subj).name ..
      (dismissed == nil and " stopped following." or " is gone."))
end

local function catchup()
   for id, subj in pairs(bond) do
      if not subj:isValid() then                   -- just in case
         bond[id] = nil
      elseif subj.count < 1 then                   -- summon expired
         release(subj, false, true)
      elseif not subj.enabled or isDead(subj) then -- disabled or dead
         release(subj, false)
      else
         subj:sendEvent('ykReqTelefollowStop', self)
         if isOnGround(self) then
            if self.cell:isInSameSpace(subj) then
               local d = subj.position - self.position
               local λ = d:length()
               λ = self.cell.isExterior and
                  (2048 < λ and 512 / λ or 1) or
                  (1024 < λ and 128 / λ or 1)
               if λ < 1 then
                  sendGlobalEvent(
                     'ykReqTeleport', {
                        cell = self.cell.name,
                        pos  = self.position + v3(d.x * λ, d.y * λ, 128),
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
end end end end end

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
