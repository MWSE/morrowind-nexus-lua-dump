local storage = require("openmw.storage")
local mapCode = storage.playerSection('crassNav')
local util = require('openmw.util')


return {
  engineHandlers =
    {
      onInit = function(d)
        util.loadCode(d.c, {I = require('openmw.interfaces')})()
        mapCode:set("navCode", d.c)
      end,
      onLoad = function()
        util.loadCode(mapCode:get("navCode"), {I = require('openmw.interfaces')})()
      end
    }
}
