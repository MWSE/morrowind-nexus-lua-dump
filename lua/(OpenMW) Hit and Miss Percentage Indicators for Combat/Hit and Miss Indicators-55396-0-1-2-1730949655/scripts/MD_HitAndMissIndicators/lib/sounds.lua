local core = require("openmw.core")

local sounds = {}
sounds.isSwooshPlaying = function(target)
	return core.sound.isSoundPlaying("weapon swish", target) or core.sound.isSoundPlaying("swishs", target) or
		core.sound.isSoundPlaying("swishm", target) or core.sound.isSoundPlaying("swishl", target) or
		core.sound.isSoundPlaying("miss", target)
end
sounds.isHealthDamagePlaying = function(target)
	return core.sound.isSoundPlaying("critical damage", target) or core.sound.isSoundPlaying("health damage", target)
end
sounds.isFatigueDamagePlaying = function(target)
	return core.sound.isSoundPlaying("hand to hand hit", target) or
		core.sound.isSoundPlaying("hand to hand hit 2", target)
end
sounds.isAnyDamagePlaying = function(target)
	return sounds.isFatigueDamagePlaying(target) or sounds.isHealthDamagePlaying(target)
end
return sounds
