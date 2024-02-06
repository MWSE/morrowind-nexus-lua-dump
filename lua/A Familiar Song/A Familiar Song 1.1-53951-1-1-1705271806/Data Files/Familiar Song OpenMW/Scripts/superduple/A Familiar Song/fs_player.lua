local core = require('openmw.core')
local self = require('openmw.self')

local didAttack = false
local doOnce = false

local function isAttacking()
  -- Check if they're attacking, but don't do it again until the attack stops
  if self.controls.use == 1 and not doOnce then 
    didAttack = true
    doOnce = true
  elseif self.controls.use == 0 then
    doOnce = false
  end
  -- Trigger the mwscript variable change in the global script
  if didAttack then
    core.sendGlobalEvent("playerAttacked", self)
    didAttack = false
  end

end

return {
  engineHandlers = {
    onUpdate = isAttacking -- Do these checks every frame just like an mwscript
  }
}