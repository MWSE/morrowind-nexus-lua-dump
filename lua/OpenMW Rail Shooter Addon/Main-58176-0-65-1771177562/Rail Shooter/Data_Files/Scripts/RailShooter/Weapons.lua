local types = require('openmw.types')
local self = require('openmw.self')


local Weapons={	Damage={handgun=10,shotgun=3,grenadelauncher=1,machinegun=5,magnum=15},
				spellOnHitRecord={handgun=nil, shotgun=nil, grenadelauncher="grenaderound",machinegun=nil, magnum=nil},
				BaseBullets={handgun=5, shotgun=2, grenadelauncher=1,machinegun=7,magnum=4},
				Piercing={handgun=false, shotgun=false, grenadelauncher=false,machinegun=false,magnum=true},
				Automatic={handgun=false, shotgun=false, grenadelauncher=false,machinegun=0.1,magnum=false},
				Pellets={handgun=1, shotgun=12, grenadelauncher=1,machinegun=1,magnum=1},
				DefaultWeapon="handgun",}

return (Weapons)
