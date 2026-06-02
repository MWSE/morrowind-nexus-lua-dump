local types = require("openmw.types")
local util = require("openmw.util")

local C = {}

C.weaponTypeToAmmoType = {
    [types.Weapon.TYPE.MarksmanBow]      = types.Weapon.TYPE.Arrow,
    [types.Weapon.TYPE.MarksmanCrossbow] = types.Weapon.TYPE.Bolt,
    [types.Weapon.TYPE.MarksmanThrown]   = types.Weapon.TYPE.MarksmanThrown,
}

C.getAnchorPoint = {
    Left = util.vector2(0, 0),
    Center = util.vector2(.5, 0),
    Right = util.vector2(1, 0),
}

return C