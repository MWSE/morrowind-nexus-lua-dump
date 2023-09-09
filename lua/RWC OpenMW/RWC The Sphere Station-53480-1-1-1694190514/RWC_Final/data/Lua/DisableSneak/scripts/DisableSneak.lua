local self = require('openmw.self')
return {
  engineHandlers = {
    onFrame = function() self.controls.sneak = false end
  }
}
