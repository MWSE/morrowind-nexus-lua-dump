-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cooking and Magic													  │
-- ╰──────────────────────────────────────────────────────────────────────╯
local cookingRecipeDB = require("scripts.SunsDusk.lib.cooking_recipes").recipes



function toBitPositions(n, step)
	step = step or 1  -- default to standard binary (step of 1)
	n = math.floor(n / step) -- Convert magnitude to "units" based on step
	local result = {}
	local position = 1
	while n > 0 do
		if n % 2 == 1 then
			table.insert(result, position)
		end
		n = math.floor(n / 2)
		position = position + 1
	end
	return result
end

local shortBits = {
["sd-detectenchantment1"] = 4,
["sd-detectenchantment2"] = 4,
["sd-detectenchantment3"] = 4,
["sd-detectenchantment4"] = 4,
["sd-fortifyhealth1"] = 4,
["sd-fortifyhealth2"] = 4,
["sd-fortifyhealth3"] = 4,
["sd-fortifyhealth4"] = 4,
["sd-cureblightdisease1"] = 4,
["sd-cureblightdisease2"] = 4,
["sd-cureblightdisease3"] = 4,
["sd-cureblightdisease4"] = 4,
["sd-spellabsorption1"] = 4,
["sd-spellabsorption2"] = 4,
["sd-spellabsorption3"] = 4,
["sd-spellabsorption4"] = 4,
["sd-waterbreathing1"] = 1,
["sd-waterbreathing2"] = 1,
["sd-waterbreathing3"] = 1,
["sd-waterbreathing4"] = 1,
["sd-cureparalyzation1"] = 4,
["sd-cureparalyzation2"] = 4,
["sd-cureparalyzation3"] = 4,
["sd-cureparalyzation4"] = 4,
["sd-restoremagicka1"] = 4,
["sd-restoremagicka2"] = 4,
["sd-restoremagicka3"] = 4,
["sd-restoremagicka4"] = 4,
["sd-resistfire1"] = 4,
["sd-resistfire2"] = 4,
["sd-resistfire3"] = 4,
["sd-resistfire4"] = 4,
["sd-lightningshield1"] = 4,
["sd-lightningshield2"] = 4,
["sd-lightningshield3"] = 4,
["sd-lightningshield4"] = 4,
["sd-drainfatigue1"] = 4,
["sd-drainfatigue2"] = 4,
["sd-drainfatigue3"] = 4,
["sd-drainfatigue4"] = 4,
["sd-swiftswim1"] = 4,
["sd-swiftswim2"] = 4,
["sd-swiftswim3"] = 4,
["sd-swiftswim4"] = 4,
["sd-fortifyattack1"] = 4,
["sd-fortifyattack2"] = 4,
["sd-fortifyattack3"] = 4,
["sd-fortifyattack4"] = 4,
["sd-resistfrost1"] = 4,
["sd-resistfrost2"] = 4,
["sd-resistfrost3"] = 4,
["sd-resistfrost4"] = 4,
["sd-resistpoison1"] = 4,
["sd-resistpoison2"] = 4,
["sd-resistpoison3"] = 4,
["sd-resistpoison4"] = 4,
["sd-resistshock1"] = 4,
["sd-resistshock2"] = 4,
["sd-resistshock3"] = 4,
["sd-resistshock4"] = 4,
["sd-curepoison1"] = 4,
["sd-curepoison2"] = 4,
["sd-curepoison3"] = 4,
["sd-curepoison4"] = 4,
["sd-invisibility1"] = 1,
["sd-invisibility2"] = 1,
["sd-invisibility3"] = 1,
["sd-invisibility4"] = 1,
["sd-restorehealth1"] = 5,
["sd-restorehealth2"] = 5,
["sd-restorehealth3"] = 5,
["sd-restorehealth4"] = 5,
["sd-nighteye1"] = 4,
["sd-nighteye2"] = 4,
["sd-nighteye3"] = 4,
["sd-nighteye4"] = 4,
["sd-almsiviintervention1"] = 4,
["sd-almsiviintervention2"] = 4,
["sd-almsiviintervention3"] = 4,
["sd-almsiviintervention4"] = 4,
["sd-burden1"] = 4,
["sd-burden2"] = 4,
["sd-burden3"] = 4,
["sd-burden4"] = 4,
["sd-detectkey1"] = 4,
["sd-detectkey2"] = 4,
["sd-detectkey3"] = 4,
["sd-detectkey4"] = 4,
["sd-restorefatigue1"] = 5,
["sd-restorefatigue2"] = 5,
["sd-restorefatigue3"] = 5,
["sd-restorefatigue4"] = 5,
["sd-fortifyfatigue1"] = 4,
["sd-fortifyfatigue2"] = 4,
["sd-fortifyfatigue3"] = 4,
["sd-fortifyfatigue4"] = 4,
["sd-jump1"] = 4,
["sd-jump2"] = 4,
["sd-jump3"] = 4,
["sd-jump4"] = 4,
["sd-sanctuary1"] = 4,
["sd-sanctuary2"] = 4,
["sd-sanctuary3"] = 4,
["sd-sanctuary4"] = 4,
["sd-waterwalking1"] = 1,
["sd-waterwalking2"] = 1,
["sd-waterwalking3"] = 1,
["sd-waterwalking4"] = 1,
["sd-shield1"] = 4,
["sd-shield2"] = 4,
["sd-shield3"] = 4,
["sd-shield4"] = 4,
["sd-light1"] = 4,
["sd-light2"] = 4,
["sd-light3"] = 4,
["sd-light4"] = 4,
["sd-levitate1"] = 4,
["sd-levitate2"] = 4,
["sd-levitate3"] = 4,
["sd-levitate4"] = 4,
["sd-fireshield1"] = 4,
["sd-fireshield2"] = 4,
["sd-fireshield3"] = 4,
["sd-fireshield4"] = 4,
["sd-telekinesis1"] = 4,
["sd-telekinesis2"] = 4,
["sd-telekinesis3"] = 4,
["sd-telekinesis4"] = 4,
["sd-fortifyattributepersonality1"] = 4,
["sd-fortifyattributewillpower1"] = 4,
["sd-fortifyattributestrength1"] = 4,
["sd-fortifyattributespeed1"] = 4,
["sd-fortifyattributeagility1"] = 4,
["sd-fortifyattributeintelligence1"] = 4,
["sd-fortifyattributeluck1"] = 4,
["sd-fortifyattributeendurance1"] = 4,
["sd-fortifyattributepersonality2"] = 4,
["sd-fortifyattributewillpower2"] = 4,
["sd-fortifyattributestrength2"] = 4,
["sd-fortifyattributespeed2"] = 4,
["sd-fortifyattributeagility2"] = 4,
["sd-fortifyattributeintelligence2"] = 4,
["sd-fortifyattributeluck2"] = 4,
["sd-fortifyattributeendurance2"] = 4,
["sd-fortifyattributepersonality3"] = 4,
["sd-fortifyattributewillpower3"] = 4,
["sd-fortifyattributestrength3"] = 4,
["sd-fortifyattributespeed3"] = 4,
["sd-fortifyattributeagility3"] = 4,
["sd-fortifyattributeintelligence3"] = 4,
["sd-fortifyattributeluck3"] = 4,
["sd-fortifyattributeendurance3"] = 4,
["sd-fortifyattributepersonality4"] = 4,
["sd-fortifyattributewillpower4"] = 4,
["sd-fortifyattributestrength4"] = 4,
["sd-fortifyattributespeed4"] = 4,
["sd-fortifyattributeagility4"] = 4,
["sd-fortifyattributeintelligence4"] = 4,
["sd-fortifyattributeluck4"] = 4,
["sd-fortifyattributeendurance4"] = 4,
["sd-frostshield1"] = 4,
["sd-frostshield2"] = 4,
["sd-frostshield3"] = 4,
["sd-frostshield4"] = 4,
["sd-resistmagicka1"] = 4,
["sd-resistmagicka2"] = 4,
["sd-resistmagicka3"] = 4,
["sd-resistmagicka4"] = 4,
["sd-slowfall1"] = 4,
["sd-slowfall2"] = 4,
["sd-slowfall3"] = 4,
["sd-slowfall4"] = 4,
["sd-curecommondisease1"] = 4,
["sd-curecommondisease2"] = 4,
["sd-curecommondisease3"] = 4,
["sd-curecommondisease4"] = 4,
["sd-feather1"] = 4,
["sd-feather2"] = 4,
["sd-feather3"] = 4,
["sd-feather4"] = 4,
["sd-chameleon1"] = 4,
["sd-chameleon2"] = 4,
["sd-chameleon3"] = 4,
["sd-chameleon4"] = 4,
["sd-detectanimal1"] = 4,
["sd-detectanimal2"] = 4,
["sd-detectanimal3"] = 4,
["sd-detectanimal4"] = 4,
}

local longBits = {
sd_weaknesstoblightdisease1 = 3,
sd_weaknesstoblightdisease2 = 3,
sd_fortifymagicka1 = 5,
sd_fortifymagicka2 = 5,
sd_spellabsorption1 = 3,
sd_spellabsorption2 = 3,
sd_reflect1 = 3,
sd_reflect2 = 3,
sd_blind1 = 3,
sd_blind2 = 3,
sd_waterwalking1 = 1,
sd_waterwalking2 = 1,
sd_absorbmagicka1 = 3,
sd_absorbmagicka2 = 3,
sd_detectanimal1 = 7,
sd_detectanimal2 = 7,
sd_fortifymaximummagicka1 = 3,
sd_fortifymaximummagicka2 = 3,
sd_swiftswim1 = 6,
sd_swiftswim2 = 6,
sd_weaknesstoshock1 = 3,
sd_weaknesstoshock2 = 3,
sd_calmcreature1 = 5,
sd_calmcreature2 = 5,
sd_sound1 = 3,
sd_sound2 = 3,
sd_levitate1 = 2,
sd_levitate2 = 2,
sd_poison1 = 2,
sd_poison2 = 2,
sd_weaknesstofire1 = 3,
sd_weaknesstofire2 = 3,
sd_drainskillbluntweapon1 = 4,
sd_drainskillaxe1 = 4,
sd_drainskillarmorer1 = 4,
sd_drainskillrestoration1 = 4,
sd_drainskillenchant1 = 4,
sd_drainskillathletics1 = 4,
sd_drainskillmarksman1 = 4,
sd_drainskillmediumarmor1 = 4,
sd_drainskillunarmored1 = 4,
sd_drainskillspear1 = 4,
sd_drainskillalteration1 = 4,
sd_drainskilldestruction1 = 4,
sd_drainskillspeechcraft1 = 4,
sd_drainskillshortblade1 = 4,
sd_drainskilllongblade1 = 4,
sd_drainskillmysticism1 = 4,
sd_drainskillsecurity1 = 4,
sd_drainskillillusion1 = 4,
sd_drainskillblock1 = 4,
sd_drainskilllightarmor1 = 4,
sd_drainskillheavyarmor1 = 4,
sd_drainskillhandtohand1 = 4,
sd_drainskillalchemy1 = 4,
sd_drainskillsneak1 = 4,
sd_drainskillconjuration1 = 4,
sd_drainskillacrobatics1 = 4,
sd_drainskillmercantile1 = 4,
sd_drainskillbluntweapon2 = 4,
sd_drainskillaxe2 = 4,
sd_drainskillarmorer2 = 4,
sd_drainskillrestoration2 = 4,
sd_drainskillenchant2 = 4,
sd_drainskillathletics2 = 4,
sd_drainskillmarksman2 = 4,
sd_drainskillmediumarmor2 = 4,
sd_drainskillunarmored2 = 4,
sd_drainskillspear2 = 4,
sd_drainskillalteration2 = 4,
sd_drainskilldestruction2 = 4,
sd_drainskillspeechcraft2 = 4,
sd_drainskillshortblade2 = 4,
sd_drainskilllongblade2 = 4,
sd_drainskillmysticism2 = 4,
sd_drainskillsecurity2 = 4,
sd_drainskillillusion2 = 4,
sd_drainskillblock2 = 4,
sd_drainskilllightarmor2 = 4,
sd_drainskillheavyarmor2 = 4,
sd_drainskillhandtohand2 = 4,
sd_drainskillalchemy2 = 4,
sd_drainskillsneak2 = 4,
sd_drainskillconjuration2 = 4,
sd_drainskillacrobatics2 = 4,
sd_drainskillmercantile2 = 4,
sd_firedamage1 = 2,
sd_firedamage2 = 2,
sd_rallycreature1 = 8,
sd_rallycreature2 = 8,
sd_weaknesstocorprusdisease1 = 3,
sd_weaknesstocorprusdisease2 = 3,
sd_weaknesstofrost1 = 3,
sd_weaknesstofrost2 = 3,
sd_resistcorprusdisease1 = 6,
sd_resistcorprusdisease2 = 6,
sd_absorbskillbluntweapon1 = 3,
sd_absorbskillaxe1 = 3,
sd_absorbskillarmorer1 = 3,
sd_absorbskillrestoration1 = 3,
sd_absorbskillenchant1 = 3,
sd_absorbskillathletics1 = 3,
sd_absorbskillmarksman1 = 3,
sd_absorbskillmediumarmor1 = 3,
sd_absorbskillunarmored1 = 3,
sd_absorbskillspear1 = 3,
sd_absorbskillalteration1 = 3,
sd_absorbskilldestruction1 = 3,
sd_absorbskillspeechcraft1 = 3,
sd_absorbskillshortblade1 = 3,
sd_absorbskilllongblade1 = 3,
sd_absorbskillmysticism1 = 3,
sd_absorbskillsecurity1 = 3,
sd_absorbskillillusion1 = 3,
sd_absorbskillblock1 = 3,
sd_absorbskilllightarmor1 = 3,
sd_absorbskillheavyarmor1 = 3,
sd_absorbskillhandtohand1 = 3,
sd_absorbskillalchemy1 = 3,
sd_absorbskillsneak1 = 3,
sd_absorbskillconjuration1 = 3,
sd_absorbskillacrobatics1 = 3,
sd_absorbskillmercantile1 = 3,
sd_absorbskillbluntweapon2 = 3,
sd_absorbskillaxe2 = 3,
sd_absorbskillarmorer2 = 3,
sd_absorbskillrestoration2 = 3,
sd_absorbskillenchant2 = 3,
sd_absorbskillathletics2 = 3,
sd_absorbskillmarksman2 = 3,
sd_absorbskillmediumarmor2 = 3,
sd_absorbskillunarmored2 = 3,
sd_absorbskillspear2 = 3,
sd_absorbskillalteration2 = 3,
sd_absorbskilldestruction2 = 3,
sd_absorbskillspeechcraft2 = 3,
sd_absorbskillshortblade2 = 3,
sd_absorbskilllongblade2 = 3,
sd_absorbskillmysticism2 = 3,
sd_absorbskillsecurity2 = 3,
sd_absorbskillillusion2 = 3,
sd_absorbskillblock2 = 3,
sd_absorbskilllightarmor2 = 3,
sd_absorbskillheavyarmor2 = 3,
sd_absorbskillhandtohand2 = 3,
sd_absorbskillalchemy2 = 3,
sd_absorbskillsneak2 = 3,
sd_absorbskillconjuration2 = 3,
sd_absorbskillacrobatics2 = 3,
sd_absorbskillmercantile2 = 3,
sd_commandhumanoid1 = 2,
sd_commandhumanoid2 = 2,
sd_fortifyattributepersonality1 = 6,
sd_fortifyattributewillpower1 = 6,
sd_fortifyattributestrength1 = 6,
sd_fortifyattributespeed1 = 6,
sd_fortifyattributeagility1 = 6,
sd_fortifyattributeintelligence1 = 6,
sd_fortifyattributeluck1 = 6,
sd_fortifyattributeendurance1 = 6,
sd_fortifyattributepersonality2 = 6,
sd_fortifyattributewillpower2 = 6,
sd_fortifyattributestrength2 = 6,
sd_fortifyattributespeed2 = 6,
sd_fortifyattributeagility2 = 6,
sd_fortifyattributeintelligence2 = 6,
sd_fortifyattributeluck2 = 6,
sd_fortifyattributeendurance2 = 6,
sd_weaknesstocommondisease1 = 4,
sd_weaknesstocommondisease2 = 4,
sd_frenzycreature1 = 5,
sd_frenzycreature2 = 5,
sd_weaknesstonormalweapons1 = 3,
sd_weaknesstonormalweapons2 = 3,
sd_fireshield1 = 5,
sd_fireshield2 = 5,
sd_sanctuary1 = 5,
sd_sanctuary2 = 5,
sd_slowfall1 = 4,
sd_slowfall2 = 4,
sd_calmhumanoid1 = 5,
sd_calmhumanoid2 = 5,
sd_fortifyfatigue1 = 6,
sd_fortifyfatigue2 = 6,
sd_restoreskillbluntweapon1 = 4,
sd_restoreskillaxe1 = 4,
sd_restoreskillarmorer1 = 4,
sd_restoreskillrestoration1 = 4,
sd_restoreskillenchant1 = 4,
sd_restoreskillathletics1 = 4,
sd_restoreskillmarksman1 = 4,
sd_restoreskillmediumarmor1 = 4,
sd_restoreskillunarmored1 = 4,
sd_restoreskillspear1 = 4,
sd_restoreskillalteration1 = 4,
sd_restoreskilldestruction1 = 4,
sd_restoreskillspeechcraft1 = 4,
sd_restoreskillshortblade1 = 4,
sd_restoreskilllongblade1 = 4,
sd_restoreskillmysticism1 = 4,
sd_restoreskillsecurity1 = 4,
sd_restoreskillillusion1 = 4,
sd_restoreskillblock1 = 4,
sd_restoreskilllightarmor1 = 4,
sd_restoreskillheavyarmor1 = 4,
sd_restoreskillhandtohand1 = 4,
sd_restoreskillalchemy1 = 4,
sd_restoreskillsneak1 = 4,
sd_restoreskillconjuration1 = 4,
sd_restoreskillacrobatics1 = 4,
sd_restoreskillmercantile1 = 4,
sd_restoreskillbluntweapon2 = 4,
sd_restoreskillaxe2 = 4,
sd_restoreskillarmorer2 = 4,
sd_restoreskillrestoration2 = 4,
sd_restoreskillenchant2 = 4,
sd_restoreskillathletics2 = 4,
sd_restoreskillmarksman2 = 4,
sd_restoreskillmediumarmor2 = 4,
sd_restoreskillunarmored2 = 4,
sd_restoreskillspear2 = 4,
sd_restoreskillalteration2 = 4,
sd_restoreskilldestruction2 = 4,
sd_restoreskillspeechcraft2 = 4,
sd_restoreskillshortblade2 = 4,
sd_restoreskilllongblade2 = 4,
sd_restoreskillmysticism2 = 4,
sd_restoreskillsecurity2 = 4,
sd_restoreskillillusion2 = 4,
sd_restoreskillblock2 = 4,
sd_restoreskilllightarmor2 = 4,
sd_restoreskillheavyarmor2 = 4,
sd_restoreskillhandtohand2 = 4,
sd_restoreskillalchemy2 = 4,
sd_restoreskillsneak2 = 4,
sd_restoreskillconjuration2 = 4,
sd_restoreskillacrobatics2 = 4,
sd_restoreskillmercantile2 = 4,
sd_restoremagicka1 = 2,
sd_restoremagicka2 = 2,
sd_restoreattributepersonality1 = 4,
sd_restoreattributewillpower1 = 4,
sd_restoreattributestrength1 = 4,
sd_restoreattributespeed1 = 4,
sd_restoreattributeagility1 = 4,
sd_restoreattributeintelligence1 = 4,
sd_restoreattributeluck1 = 4,
sd_restoreattributeendurance1 = 4,
sd_restoreattributepersonality2 = 4,
sd_restoreattributewillpower2 = 4,
sd_restoreattributestrength2 = 4,
sd_restoreattributespeed2 = 4,
sd_restoreattributeagility2 = 4,
sd_restoreattributeintelligence2 = 4,
sd_restoreattributeluck2 = 4,
sd_restoreattributeendurance2 = 4,
sd_resistcommondisease1 = 6,
sd_resistcommondisease2 = 6,
sd_drainattributepersonality1 = 4,
sd_drainattributewillpower1 = 4,
sd_drainattributestrength1 = 4,
sd_drainattributespeed1 = 4,
sd_drainattributeagility1 = 4,
sd_drainattributeintelligence1 = 4,
sd_drainattributeluck1 = 4,
sd_drainattributeendurance1 = 4,
sd_drainattributepersonality2 = 4,
sd_drainattributewillpower2 = 4,
sd_drainattributestrength2 = 4,
sd_drainattributespeed2 = 4,
sd_drainattributeagility2 = 4,
sd_drainattributeintelligence2 = 4,
sd_drainattributeluck2 = 4,
sd_drainattributeendurance2 = 4,
sd_resistfrost1 = 5,
sd_resistfrost2 = 5,
sd_resistshock1 = 5,
sd_resistshock2 = 5,
sd_restorehealth1 = 2,
sd_restorehealth2 = 2,
sd_nighteye1 = 7,
sd_nighteye2 = 7,
sd_frostshield1 = 5,
sd_frostshield2 = 5,
sd_resistnormalweapons1 = 4,
sd_resistnormalweapons2 = 4,
sd_damagefatigue1 = 2,
sd_damagefatigue2 = 2,
sd_demoralizecreature1 = 5,
sd_demoralizecreature2 = 5,
sd_telekinesis1 = 7,
sd_telekinesis2 = 7,
sd_resistmagicka1 = 5,
sd_resistmagicka2 = 5,
sd_fortifyskillbluntweapon1 = 6,
sd_fortifyskillaxe1 = 6,
sd_fortifyskillarmorer1 = 6,
sd_fortifyskillrestoration1 = 6,
sd_fortifyskillenchant1 = 6,
sd_fortifyskillathletics1 = 6,
sd_fortifyskillmarksman1 = 6,
sd_fortifyskillmediumarmor1 = 6,
sd_fortifyskillunarmored1 = 6,
sd_fortifyskillspear1 = 6,
sd_fortifyskillalteration1 = 6,
sd_fortifyskilldestruction1 = 6,
sd_fortifyskillspeechcraft1 = 6,
sd_fortifyskillshortblade1 = 6,
sd_fortifyskilllongblade1 = 6,
sd_fortifyskillmysticism1 = 6,
sd_fortifyskillsecurity1 = 6,
sd_fortifyskillillusion1 = 6,
sd_fortifyskillblock1 = 6,
sd_fortifyskilllightarmor1 = 6,
sd_fortifyskillheavyarmor1 = 6,
sd_fortifyskillhandtohand1 = 6,
sd_fortifyskillalchemy1 = 6,
sd_fortifyskillsneak1 = 6,
sd_fortifyskillconjuration1 = 6,
sd_fortifyskillacrobatics1 = 6,
sd_fortifyskillmercantile1 = 6,
sd_fortifyskillbluntweapon2 = 6,
sd_fortifyskillaxe2 = 6,
sd_fortifyskillarmorer2 = 6,
sd_fortifyskillrestoration2 = 6,
sd_fortifyskillenchant2 = 6,
sd_fortifyskillathletics2 = 6,
sd_fortifyskillmarksman2 = 6,
sd_fortifyskillmediumarmor2 = 6,
sd_fortifyskillunarmored2 = 6,
sd_fortifyskillspear2 = 6,
sd_fortifyskillalteration2 = 6,
sd_fortifyskilldestruction2 = 6,
sd_fortifyskillspeechcraft2 = 6,
sd_fortifyskillshortblade2 = 6,
sd_fortifyskilllongblade2 = 6,
sd_fortifyskillmysticism2 = 6,
sd_fortifyskillsecurity2 = 6,
sd_fortifyskillillusion2 = 6,
sd_fortifyskillblock2 = 6,
sd_fortifyskilllightarmor2 = 6,
sd_fortifyskillheavyarmor2 = 6,
sd_fortifyskillhandtohand2 = 6,
sd_fortifyskillalchemy2 = 6,
sd_fortifyskillsneak2 = 6,
sd_fortifyskillconjuration2 = 6,
sd_fortifyskillacrobatics2 = 6,
sd_fortifyskillmercantile2 = 6,
sd_frenzyhumanoid1 = 5,
sd_frenzyhumanoid2 = 5,
sd_absorbhealth1 = 3,
sd_absorbhealth2 = 3,
sd_waterbreathing1 = 1,
sd_waterbreathing2 = 1,
sd_shockdamage1 = 2,
sd_shockdamage2 = 2,
sd_detectkey1 = 7,
sd_detectkey2 = 7,
sd_resistparalysis1 = 5,
sd_resistparalysis2 = 5,
sd_demoralizehumanoid1 = 5,
sd_demoralizehumanoid2 = 5,
sd_lightningshield1 = 5,
sd_lightningshield2 = 5,
sd_commandcreature1 = 2,
sd_commandcreature2 = 2,
sd_resistfire1 = 5,
sd_resistfire2 = 5,
sd_fortifyattack1 = 6,
sd_fortifyattack2 = 6,
sd_resistpoison1 = 5,
sd_resistpoison2 = 5,
sd_detectenchantment1 = 7,
sd_detectenchantment2 = 7,
sd_weaknesstopoison1 = 4,
sd_weaknesstopoison2 = 4,
sd_absorbfatigue1 = 3,
sd_absorbfatigue2 = 3,
sd_resistblightdisease1 = 6,
sd_resistblightdisease2 = 6,
sd_burden1 = 5,
sd_burden2 = 5,
sd_sundamage1 = 2,
sd_sundamage2 = 2,
sd_restorefatigue1 = 2,
sd_restorefatigue2 = 2,
sd_weaknesstomagicka1 = 3,
sd_weaknesstomagicka2 = 3,
sd_frostdamage1 = 2,
sd_frostdamage2 = 2,
sd_fortifyhealth1 = 5,
sd_fortifyhealth2 = 5,
sd_rallyhumanoid1 = 8,
sd_rallyhumanoid2 = 8,
sd_feather1 = 6,
sd_feather2 = 6,
sd_absorbattributepersonality1 = 3,
sd_absorbattributewillpower1 = 3,
sd_absorbattributestrength1 = 3,
sd_absorbattributespeed1 = 3,
sd_absorbattributeagility1 = 3,
sd_absorbattributeintelligence1 = 3,
sd_absorbattributeluck1 = 3,
sd_absorbattributeendurance1 = 3,
sd_absorbattributepersonality2 = 3,
sd_absorbattributewillpower2 = 3,
sd_absorbattributestrength2 = 3,
sd_absorbattributespeed2 = 3,
sd_absorbattributeagility2 = 3,
sd_absorbattributeintelligence2 = 3,
sd_absorbattributeluck2 = 3,
sd_absorbattributeendurance2 = 3,
sd_shield1 = 5,
sd_shield2 = 5,
sd_jump1 = 5,
sd_jump2 = 5,
sd_charm1 = 2,
sd_charm2 = 2,
sd_chameleon1 = 5,
sd_chameleon2 = 5,
}

--maxlength	32

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Container Helpers                                                    │
-- ╰──────────────────────────────────────────────────────────────────────╯

local FALLBACK_MESH = "meshes/SunsDusk/contain_couldron10.nif"
local FALLBACK_ICON = "icons/SunsDusk/cooking_pot.dds"

local function createStew(data)
	local player = data[1]
	local foodData = data[2]
	local inv = types.Actor.inventory(player)
	
	local totalCount = foodData.count
	local foodware = foodData.foodware -- "bowl", "plate", or nil
	local stewIcon = foodData.recipeIcon or FALLBACK_ICON
	local stewName = foodData.recipeName or "Stew"
	local recipeId = foodData.recipeId
	
	-- Determine container preference order
	local primaryType, secondaryType
	if foodware == "bowl" then
		primaryType = "bowl"
		secondaryType = "plate"
	elseif foodware == "plate" then
		primaryType = "plate"
		secondaryType = "bowl"
	end
	
	-- Group containers by mesh, tracking actual items for consumption
	-- First pass: primary container type
	-- Second pass: secondary container type (fallback)
	-- Group containers by recordId, tracking mesh for visuals
	local containerGroups = {} -- { [recordId] = { count=N, mesh=..., items={...} } }
	local totalContainers = 0
	
	local function gatherContainers(targetType)
		if not targetType then return end
		for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
			if item:isValid() and item.count > 0 then
				if getFoodwareType(item) == targetType then
					local rec = types.Miscellaneous.record(item)
					local recordId = rec.id
					if not containerGroups[recordId] then
						containerGroups[recordId] = { 
							count = 0, 
							mesh = rec.model or FALLBACK_MESH, 
							items = {} 
						}
					end
					containerGroups[recordId].count = containerGroups[recordId].count + item.count
					table.insert(containerGroups[recordId].items, { item = item, available = item.count })
					totalContainers = totalContainers + item.count
				end
			end
		end
	end
	
	-- Gather primary type first
	gatherContainers(primaryType)
	-- If we need more, gather secondary type
	if totalContainers < totalCount then
		gatherContainers(secondaryType)
	end
	
	-- Allocate requested count across container groups + fallback
	local allocations = {} -- { { mesh=..., count=..., containerRecordId=... }, ... }
	local allocated = 0
	
	for recordId, group in pairs(containerGroups) do
		local toAllocate = math.min(group.count, totalCount - allocated)
		if toAllocate > 0 then
			table.insert(allocations, {
				mesh = group.mesh,
				count = toAllocate,
				foodwareRecordId = recordId
			})
			allocated = allocated + toAllocate
		end
		if allocated >= totalCount then break end
	end
	
	-- Fallback for remaining (no containers left)
	if allocated < totalCount then
		table.insert(allocations, {
			mesh = FALLBACK_MESH,
			count = totalCount - allocated,
			foodwareRecordId = nil
		})
	end
	
	-- Calculate batches: min 4, max batch size = ceil(total/4)
	local maxBatchSize = math.ceil(totalCount / 4)
	local batches = {} -- { { mesh=..., count=..., foodwareRecordId=... }, ... }
	
	for _, alloc in ipairs(allocations) do
		local remaining = alloc.count
		while remaining > 0 do
			local batchCount = math.min(remaining, maxBatchSize)
			table.insert(batches, {
				mesh = alloc.mesh,
				count = batchCount,
				foodwareRecordId = alloc.foodwareRecordId
			})
			remaining = remaining - batchCount
		end
	end
	
	-- If under 4 batches, split largest until we hit 4 (or all size 1)
	while #batches < 4 do
		local largestIdx = 1
		local largestCount = batches[1].count
		for i, batch in ipairs(batches) do
			if batch.count > largestCount then
				largestIdx = i
				largestCount = batch.count
			end
		end
		
		if largestCount <= 1 then break end
		
		local half1 = math.ceil(largestCount / 2)
		local half2 = largestCount - half1
		local original = batches[largestIdx]
		batches[largestIdx] = { mesh = original.mesh, count = half1, foodwareRecordId = original.foodwareRecordId }
		table.insert(batches, { mesh = original.mesh, count = half2, foodwareRecordId = original.foodwareRecordId })
	end
	
	-- Prepare shared data
	local tmpl = types.Potion.record("sd_waterbottle_template")
	
	local infoBracket = math.floor(foodData.foodValue + 0.5)
	if foodData.wakeValue > 0 then
		infoBracket = infoBracket .. "/" .. math.floor(foodData.drinkValue + 0.5) .. "/" .. math.floor(foodData.wakeValue + 0.5)
	elseif foodData.drinkValue > 0 then
		infoBracket = infoBracket .. "/" .. math.floor(foodData.drinkValue + 0.5)
	end
	
	local baseValue = 0
	for itemId, _ in pairs(foodData.consumedIngredients) do
		local record = types.Ingredient.records[itemId] or types.Potion.records[itemId]
		if record then
			baseValue = baseValue + record.value
		end
	end
	
	local timestamp = core.getGameTime()
	
	-- Create records for each batch
	for _, batch in ipairs(batches) do
		-- Roll effects for this batch
		local newEffects = {}
		for uniqueId, effectData in pairs(foodData.dynamicEffects) do
			local magnitude = effectData.magnitude
			if math.random() < magnitude % 1 then
				magnitude = magnitude + 1
			end
			local step = 1
			local maxBits = longBits[uniqueId] or 0
			
			if foodData.shortBuff then
				step = 5
				maxBits = shortBits[uniqueId] or 0
				magnitude = math.floor(magnitude / 5 + 0.5) * 5
				if effectData.successfulContributors and effectData.successfulContributors > 0 then
					magnitude = math.max(5, magnitude)
				end
			else
				magnitude = math.floor(magnitude)
			end
			
			local maxMagnitude = step * (2 ^ maxBits - 1)
			magnitude = math.min(maxMagnitude, magnitude)
			
			if magnitude >= step then
				local sourcePotion = types.Potion.records[uniqueId]
				if sourcePotion then
					if foodData.shortBuff then
						table.insert(newEffects, sourcePotion.effects[math.floor(magnitude / 5)])
					else
						for _, pos in pairs(toBitPositions(magnitude, step)) do
							table.insert(newEffects, sourcePotion.effects[pos])
						end
					end
				end
			end
		end
		
		-- Recipe name with stats bracket
		local recordDraft = types.Potion.createRecordDraft({
			name     = " " .. stewName .. " [" .. infoBracket .. "]",
			template = tmpl,
			model    = batch.mesh,
			icon     = stewIcon,
			weight   = 1,
			value    = baseValue,
			effects  = newEffects,
			mwscript = 'sd_loot_tracker',
		})
		
		local rec = world.createRecord(recordDraft)
		
		-- Register stew data for VFX, fresh/cold tracking, and container return
		local containerType = nil
		if recipeId and batch.mesh ~= FALLBACK_MESH then
			-- Determine the type based on the mesh used
			if batch.foodwareRecordId then
				-- Look up the actual container record to get its type
				containerType = getFoodwareType(batch.foodwareRecordId)
			end
		end
		local recipeData = recipeId and cookingRecipeDB[recipeId]
		
		if foodData.foodValue2 == 0 then
			foodData.foodValue2 = nil
		end
		if foodData.drinkValue2 == 0 then
			foodData.drinkValue2 = nil
		end
		if foodData.wakeValue == 0 then
			foodData.wakeValue = nil
		end
		if foodData.warmthValue == 0 then
			foodData.warmthValue = nil
		end
		if foodData.warmthValue2 == 0 then
			foodData.warmthValue2 = nil
		end
		
		saveData.stewRegistry[rec.id] = {
			timestamp = timestamp,
			recipeId = recipeId,
			foodwareRecordId = batch.foodwareRecordId, -- nil if no container used
			foodwareType = containerType, -- "bowl", "plate", or nil
			isSoup = recipeData and recipeData.isSoup or false,
			consumeCategory = foodData.consumeCategory,
			foodValue       = foodData.foodValue or 0,
			foodValue2      = foodData.foodValue2,
			drinkValue      = foodData.drinkValue or 0,
			drinkValue2     = foodData.drinkValue2,
			wakeValue       = foodData.wakeValue or 0,
			wakeValue2      = foodData.wakeValue2,
			warmthValue      = foodData.warmthValue,
			warmthValue2      = foodData.warmthValue2,
			isToxic         = foodData.isToxic,
			isGreenPact     = foodData.isGreenPact,
			isCookedMeal    = true,
		}
		
		local playerDbEntry = {
			timestamp = timestamp,
			recipeId = recipeId,
			--foodwareRecordId = batch.foodwareRecordId, -- nil if no container used
			--foodwareType = containerType, -- "bowl", "plate", or nil
			--isSoup = recipeData and recipeData.isSoup or false,
			consumeCategory = foodData.consumeCategory,
			foodValue       = foodData.foodValue or 0,
			foodValue2      = foodData.foodValue2,
			drinkValue      = foodData.drinkValue or 0,
			drinkValue2     = foodData.drinkValue2,
			wakeValue       = foodData.wakeValue or 0,
			wakeValue2      = foodData.wakeValue2,
			warmthValue      = foodData.warmthValue,
			warmthValue2      = foodData.warmthValue2,
			isToxic         = foodData.isToxic,
			isGreenPact     = foodData.isGreenPact,
			isCookedMeal    = true,
		}
		
		-- Register consumable
		for _, player in pairs(world.players) do
			player:sendEvent("SunsDusk_addConsumable", { rec.id, saveData.stewRegistry[rec.id]})
		end
		
		-- Spawn items
		world.createObject(rec.id, batch.count):moveInto(inv)
	end
	
	-- Consume containers based on what we allocated
	for _, alloc in ipairs(allocations) do
		if alloc.foodwareRecordId then
			local toConsume = alloc.count
			for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
				if toConsume <= 0 then break end
				if item:isValid() and item.count > 0 and item.recordId == alloc.foodwareRecordId then
					local removeCount = math.min(item.count, toConsume)
					item:remove(removeCount)
					toConsume = toConsume - removeCount
				end
			end
		end
	end
	
	-- Consume ingredients
	for _, item in pairs(inv:getAll()) do
		if foodData.consumedIngredients[item.recordId] then
			item:remove(foodData.consumedIngredients[item.recordId])
		end
	end
end

G_onLoadJobs.cooking = function(data)
	saveData.stewRegistry = saveData.stewRegistry or {}
	saveData.steamingStews = saveData.steamingStews or {}
	saveData.stewLootIdCounter = saveData.stewLootIdCounter or 0
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Stew Steam VFX                                                       │
-- ╰──────────────────────────────────────────────────────────────────────╯
G_onObjectActiveJobs.cooking = function(object)
	local stewData = saveData.stewRegistry[object.recordId]
	if not stewData then return end
	
	if saveData.steamingStews[object.id] then return end
	
	saveData.stewLootIdCounter = saveData.stewLootIdCounter + 1
	local lootId = saveData.stewLootIdCounter
	
	local mwscript = world.mwscript.getLocalScript(object)
	if mwscript then
		mwscript.variables.lootId = lootId
	end
	
	-- Get base food offset (normalized position for this recipe)
	local baseData = foodOffsets[stewData.recipeId]
	local baseOffset = baseData and baseData.offset or v3(0,0,0)
	local baseScale = baseData and baseData.scale or 1
	
	-- Get foodware-specific adjustment (multiplier for this specific bowl/plate)
	-- Use soupFoodwareOffsets for soups, foodwareOffsets for normal food
	local foodwareOffsetsTable = stewData.isSoup and soupFoodwareOffsets or foodwareOffsets
	local foodwareAdjust = stewData.foodwareRecordId and foodwareOffsetsTable[stewData.foodwareRecordId]
	local foodwareOffset, foodwareScale
	
	if foodwareAdjust then
		foodwareOffset = foodwareAdjust.offset
		foodwareScale = foodwareAdjust.scale
	else
		-- Fallback: calculate offset/scale from the object's bounding box
		local bbox = object:getBoundingBox()
		local shortestSide = math.min(bbox.halfSize.x * 2, bbox.halfSize.y * 2)
		foodwareScale = shortestSide * 1.414 / 20.495 * 1.15
		if stewData.isSoup then
			foodwareOffset = bbox.center-object.position + v3(0, 0, bbox.halfSize.z / 2)
		else
			foodwareOffset = bbox.center-object.position - v3(0, 0, bbox.halfSize.z / 2)
		end
	end
	
	
	-- Apply both: base offset scales with food, then add foodware adjustment
	local finalOffset = baseOffset * foodwareScale + foodwareOffset
	local finalScale = baseScale * foodwareScale
	
	local static = world.createObject(stewData.recipeId)
	static:teleport(object.cell, object.position + finalOffset, {onGround = false})
	static:setScale(finalScale)
	
	local steamStatic = nil
	local currentTime = core.getGameTime()
	local ageInHours = (currentTime - stewData.timestamp) / 3600
	
	if ageInHours < 3 then
		steamStatic = world.createObject("sd_food_steam")
		steamStatic:teleport(object.cell, object.position + finalOffset, {onGround = false})
		steamStatic:setScale(finalScale)
	end
	
	saveData.steamingStews[object.id] = {
		object = object,
		static = static,
		steamStatic = steamStatic,
		lootId = lootId,
		timestamp = stewData.timestamp,
	}
end

--local function unhookStew(object)
--	if not saveData.steamingStews[object.id] then return end
--	local static = saveData.steamingStews[object.id].static
--	if static.count > 0 then
--		static:remove()
--	end
--	print("-", object.id, static, static.count)
--	saveData.steamingStews[object.id] = nil
--end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ MWScript Loot Detection (the cursed workaround)                      │
-- ╰──────────────────────────────────────────────────────────────────────╯
G_onUpdateJobs.cookingLootDetector = function(dt)
    local globals = world.mwscript.getGlobalVariables()
    local lootedId = globals.sd_loot_signal or 0
    if lootedId < 1 then return end
    
    globals.sd_loot_signal = 0
    
    for objectId, data in pairs(saveData.steamingStews) do
        if data.lootId == lootedId then
            if data.static and data.static:isValid() and data.static.count > 0 then
                data.static:remove()
            end
            if data.steamStatic and data.steamStatic:isValid() and data.steamStatic.count > 0 then
                data.steamStatic:remove()
            end
            saveData.steamingStews[objectId] = nil
            break
        end
    end
end

local steamIterator
G_onUpdateJobs.cookingSteamAgeChecker = function(dt)
    local currentTime = core.getGameTime()
    
	local data
    steamIterator, data = next(saveData.steamingStews, steamIterator)
    if steamIterator then
        if data.steamStatic and data.steamStatic:isValid() and data.timestamp then
            local ageInHours = (currentTime - data.timestamp) / 3600
            if ageInHours >= 3 then
                data.steamStatic:remove()
                data.steamStatic = nil
            end
        end
    end
end

--G_onUpdateJobs.cooking = function(dt)
--	for objectId, data in pairs(saveData.steamingStews) do
--		local object = data.object
--		if not object or not object:isValid() or object.count < 1 then
--			saveData.steamingStews[objectId] = nil
--		else
--			data.timer = data.timer + dt
--			if data.timer >= 0.5 then
--				data.timer = 0
--				world.vfx.spawn(
--					data.vfxMesh,
--					object.position,
--					{
--						vfxId = data.vfxId
--					}
--				)
--			end
--		end
--	end
--end

local function lootStew(item, player)
end

I.Activation.addHandlerForType(types.Potion, lootStew)

local function returnContainer(data)
	local player = data.player
	local stewId = data.stewId
	
	if not stewId then return end
	
	local stewData = saveData.stewRegistry[stewId]
	if stewData and stewData.foodwareRecordId then
		local inv = types.Actor.inventory(player)
		world.createObject(stewData.foodwareRecordId, 1):moveInto(inv)
	end
end

G_eventHandlers.SunsDusk_returnContainer = returnContainer
G_eventHandlers.SunsDusk_createStew = createStew
G_eventHandlers.SunsDusk_UnhookStew = unhookStew