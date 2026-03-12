local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local T                         = require("openmw.types")
local I                         = require('openmw.interfaces')

local EnchantRecords = core.magic.enchantments.records

local function doRecharge(data)
  local actor, item, actualMax, gold, price = data.actor, data.item, data.actualMax, data.gold, data.price

  T.Item.itemData(item).enchantmentCharge = actualMax
  
  gold:remove(price)
  
  actor:sendEvent('FUJI_createUIRech',{})
end

return {
  eventHandlers = {
    FUJI_doRecharge = doRecharge,
  },
}