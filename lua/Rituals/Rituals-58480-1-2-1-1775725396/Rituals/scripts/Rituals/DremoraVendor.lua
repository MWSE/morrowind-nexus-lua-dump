local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local I = require('openmw.interfaces')

I.Combat.addOnHitHandler(
  function(attack)
    core.sendGlobalEvent('R_RemoveVendor',{actor=self})
    return true
  end
)

local timer = async:registerTimerCallback('R_DremoraVendorTimer',
  function(self)
    core.sendGlobalEvent('R_RemoveVendor',{actor=self})
  end
)

async:newGameTimer(3600,timer,self)