local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local T                         = require("openmw.types")
local I                         = require('openmw.interfaces')

local function modDisposition(data)
  local self, actor, amt = data.self, data.actor, data.amt
  
  local disp = types.NPC.getDisposition(actor, self)
  
  if (disp + amt) > 100 then
    amt = 100 - disp
  elseif (disp + amt) < 0 then
    amt = disp * -1
  end
  
  types.NPC.modifyBaseDisposition(actor, self, amt)
end

local function payGold(data)
  local gold, price = data.gold, data.price

  gold:remove(price)
end

local function init()
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
  },
  eventHandlers = {
    GAB_ModDisposition = modDisposition,
    GAB_payGold = payGold,
  },
}