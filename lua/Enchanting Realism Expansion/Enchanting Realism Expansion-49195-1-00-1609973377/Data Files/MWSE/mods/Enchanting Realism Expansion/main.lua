local common = require("OperatorJack.MagickaExpanded.common")
local H = {}

local function PostTalk(e)
	if (e.dialogue.id == "Variety of Enchantments") or (e.dialogue.id == "- to enchant") then
		for i = 1, #common.spells do
			local spell = common.spells[i]
			if (spell.id ~= "beggar's nose spell") and not (tes3.player.object.spells:contains(spell.id)) then
				mwscript.addSpell({ reference = tes3.player, spell = spell })
				H[spell.id] = 5
			end
		end
	end
end

local function MenuExit(e)
	if (table.size(H) == 0) then
		return
	end

	for i = 1, #common.spells do
		local spell = common.spells[i]
		if (H[spell.id] ~= nil) then
			mwscript.removeSpell({ reference = tes3.player, spell = spell })
			H[spell.id] = nil
		end
	end
	H = {}
end

event.register("postInfoResponse", PostTalk)
event.register("menuExit", MenuExit)