local projection = require('scripts.niftyspellpack.effects.projection.player')

local MIN_RADIUS = 60
local MAX_RADIUS = 4000
local MIN_INERTIA_FACTOR = 0.99
local MAX_INERTIA_FACTOR = 0.9

local effect = projection.createProjectionEffect({
    effectId = 'nsp_greaterprojection',
    minRadius = MIN_RADIUS,
    maxRadius = MAX_RADIUS,
    minInertia = MIN_INERTIA_FACTOR,
    maxInertia = MAX_INERTIA_FACTOR,
    useObjectCollision = false,
})

return effect