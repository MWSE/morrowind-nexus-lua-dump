local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local T                         = require("openmw.types")
local I                         = require('openmw.interfaces')

local function giveObject(data)
  local actor, objID, count = data.actor, data.objID, data.count
  world.createObject(objID, count):moveInto(actor)
end

local function potRemoveObject(data)
  local obj, count = data.obj, data.count
  assert(obj and obj:isValid())
  obj:remove(count)
end

local function init()
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
  },
  eventHandlers = {
    SALC_GiveObject = giveObject,
    SALC_PotRemoveObject = potRemoveObject
  },
}