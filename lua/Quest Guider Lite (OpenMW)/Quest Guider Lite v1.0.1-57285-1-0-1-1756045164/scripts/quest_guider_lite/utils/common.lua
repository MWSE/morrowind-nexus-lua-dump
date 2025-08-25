local util = require('openmw.util')

local this = {}

function this.copyVector3(vector)
    return util.vector3(vector.x, vector.y, vector.z)
end


function this.distance2D(vector1, vector2)
    return math.sqrt((vector1.x - vector2.x)^2 + (vector1.y - vector2.y)^2)
end


return this