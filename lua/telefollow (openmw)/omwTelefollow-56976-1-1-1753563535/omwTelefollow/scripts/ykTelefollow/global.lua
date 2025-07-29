local I     = require('openmw.interfaces')
local types = require('openmw.types')
local Player = types.Player
local isDead = types.Actor.isDead
local contract = 'scripts/ykTelefollow/custom.lua'
local onGround = {onGround=true}

local function mediate(subj, actor)
   if actor.type == Player and not isDead(subj) then
      if subj:hasScript(contract) then
         actor:sendEvent('ykReqTelefollowStop', subj)
      else
         subj:addScript(contract, actor)
end end end
I.Activation.addHandlerForType(types.NPC, mediate)
I.Activation.addHandlerForType(types.Creature, mediate)

return {
   eventHandlers = {
      ykResTelefollowStop = function(subj)
         subj:removeScript(contract)
      end,
      ykReqTeleport = function(req)
         req.obj:teleport(req.cell, req.pos, req.rot or onGround)
      end,
   },
}
