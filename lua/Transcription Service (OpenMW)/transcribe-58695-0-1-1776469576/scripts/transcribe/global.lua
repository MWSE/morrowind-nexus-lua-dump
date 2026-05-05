local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local I                         = require('openmw.interfaces')

local EnchantRecords = core.magic.enchantments.records

local function doTranscribe(data)
  local actor, item, gold, price, name, enchantid = data.actor, data.item, data.gold, data.price, data.name, data.enchantid
  
  item:remove(1)
  
  gold:remove(price)
  
  print(enchantid)
  
  types.Player.spells(actor):add("sp_" .. enchantid)
  
  actor:sendEvent('TRAN_createUI',{})
end

return {
  eventHandlers = {
    TRAN_doTranscribe = doTranscribe,
  },
}