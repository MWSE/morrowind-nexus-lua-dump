local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')

local function onActivated(actor)
  core.sendGlobalEvent('SG_GiveToPlayer',{actor=actor,item='sg_skyshard',sound="Sound/Fx/item/item.wav"})
  core.sendGlobalEvent('ConsumeItem', {item=self,amount=1})
  actor:sendEvent('ShowMessage', {message='As you break off a piece, the shard disintegrates!'})
end

return {
  engineHandlers = {
    onActivated = onActivated,
  }
}