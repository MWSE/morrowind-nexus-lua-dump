local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local time = require('openmw_aux.time')


local repeatFunct = time.runRepeatedly(function() 

if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseSkill') then

	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseAxe') then
		I.SkillProgression.skillLevelUp('axe', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
	end
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseBlock') then
		I.SkillProgression.skillLevelUp('block', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage) 
	end
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseBlunt') then
		I.SkillProgression.skillLevelUp('bluntweapon', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
	end
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaselongb') then
		I.SkillProgression.skillLevelUp('longblade', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage) 
	end	
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseH2H') then
		I.SkillProgression.skillLevelUp('handtohand', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
	end	
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseHeavyArmor') then
		I.SkillProgression.skillLevelUp('heavyarmor', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
	end	
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increaseMediumArmor') then
		I.SkillProgression.skillLevelUp('mediumarmor', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
	end	
	if types.Actor.activeSpells(self):isSpellActive('WMRT_increasespear') then
		I.SkillProgression.skillLevelUp('spear', I.SkillProgression.SKILL_INCREASE_SOURCES.Usage) 
	end	
end

end, 3 * time.second)
