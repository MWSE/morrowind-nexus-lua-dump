-- fall_risk/palettes.lua — v0.2
local util = require('openmw.util')
return {
  default = {
    safe   = util.color.hex('2ecc71'), -- vert
    danger = util.color.hex('e74c3c'), -- rouge
  },
  alt = {
    safe   = util.color.hex('21918c'), -- teal/cyan (CVD-friendly)
    danger = util.color.hex('fde725'), -- jaune (CVD-friendly)
  },
}
