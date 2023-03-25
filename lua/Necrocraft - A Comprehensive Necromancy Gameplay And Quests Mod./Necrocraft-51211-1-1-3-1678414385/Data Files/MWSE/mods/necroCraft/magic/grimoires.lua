local magickaExpanded = require("OperatorJack.MagickaExpanded.magickaExpanded")
local id = require("NecroCraft.magic.id")

grimoires = {}

local function registerGrimoires()

	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.spreadDisease1,
		spellIds = {
            id.spell.spreadDisease1,
        }
	})

	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseSkeleton1,
		spellIds = {
            id.spell.raiseSkeleton1,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseSkeleton2,
		spellIds = {
            id.spell.raiseSkeleton2,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseSkeleton3,
		spellIds = {
            id.spell.raiseSkeleton3,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseBonespider,
		spellIds = {
            id.spell.raiseBonespider,
        }
	})

	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseBonelord,
		spellIds = {
            id.spell.raiseBonelord,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseBoneoverlord,
		spellIds = {
            id.spell.raiseBoneoverlord,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseCorpse1,
		spellIds = {
            id.spell.raiseCorpse1,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseCorpse2,
		spellIds = {
           id.spell.raiseCorpse2,
        }
	})
	
	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.raiseCorpse3,
		spellIds = {
           id.spell.raiseCorpse3,
        }
	})

	magickaExpanded.grimoires.registerGrimoire({
		id = id.grimoire.darkestRitual,
		spellIds = {
            id.spell.darkestRitual,
        }
	})	
	
end

event.register("MagickaExpanded:Register", registerGrimoires)

return grimoires