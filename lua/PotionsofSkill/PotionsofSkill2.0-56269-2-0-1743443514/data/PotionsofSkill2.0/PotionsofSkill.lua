local ui = require('openmw.ui')
local types = require('openmw.types')
local I = require('openmw.interfaces')


return {
	engineHandlers = {
		onConsume = function(item)
			if types.Potion.record(item).id == 'p_chameleon_c' then
				I.SkillProgression.skillLevelUp('sneak', 'book')
				ui.showMessage('You have been super sneaky')
			end
			if types.Potion.record(item).id == 'p_fortify_personality_e' then
				I.SkillProgression.skillLevelUp('speechcraft', 'book')
				ui.showMessage('How Charismatic')
			end
			if types.Potion.record(item).id == 'p_jump_e' then
				I.SkillProgression.skillLevelUp('acrobatics', 'book')
				ui.showMessage('Get Down From There!!!')
			end
			if types.Potion.record(item).id == 'p_fortify_strength_q' then
				I.SkillProgression.skillLevelUp('handtohand', 'book')
				ui.showMessage('No more messing around')
			end
			if types.Potion.record(item).id == 'p_telekinesis_s' then
				I.SkillProgression.skillLevelUp('illusion', 'book')
				ui.showMessage('May the force be with you..')
			end
			if types.Potion.record(item).id == 'p_fortify_luck_b' then
				I.SkillProgression.skillLevelUp('security', 'book')
				ui.showMessage('Insider Trading?')
			end
			if types.Potion.record(item).id == 'potion_skooma_01' then
				I.SkillProgression.skillLevelUp('alchemy', 'book')
				ui.showMessage('Addict...')
			end			
			if types.Potion.record(item).id == 'p_fire_shield_c' then
				I.SkillProgression.skillLevelUp('armorer', 'book')
				ui.showMessage('Hide nwah')
			end
					

		end
	}
}