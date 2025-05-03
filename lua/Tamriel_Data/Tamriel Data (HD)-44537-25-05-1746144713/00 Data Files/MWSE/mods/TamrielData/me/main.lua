-- Script for overwriting Magicka Expanded's spells/effects with those from Tamriel Data
local config = require("tamrielData.config")
event.register(tes3.event.loaded, function()
    local me_framework = include("OperatorJack.MagickaExpanded")
    if me_framework then
		local me_summoning = include("OperatorJack.MagickaExpanded-SummoningPack.main")
		local me_tr = include("OperatorJack.MagickaExpanded-TamrielRebuiltPack.main")
		local me_lorefriendly = include("OperatorJack.MagickaExpanded-LoreFriendlyPack.main")
		local me_cortex = include("OperatorJack.MagickaExpanded-CortexPack.main")

		for _,spell in pairs(me_framework.getActiveSpells()) do
			for i = 1, 8, 1 do
				local duration = spell.effects[i].duration
				local min = spell.effects[i].min
				local max = spell.effects[i].max
				local area = spell.effects[i].radius
				local type = spell.effects[i].rangeType

				local replacementEffect
				if config.summoningSpells == true then
					if me_summoning then
						if spell.effects[i].id == tes3.effect.summonDraugr then
							replacementEffect = tes3.getObject("T_Nor_Cnj_SummonDraugr").effects[1]
							spell.effects[i] = replacementEffect
						elseif spell.effects[i].id == tes3.effect.summonOgrim then
							replacementEffect = tes3.getObject("T_Com_Cnj_SummonOgrim").effects[1]
							spell.effects[i] = replacementEffect
						elseif spell.effects[i].id == tes3.effect.summonSpriggan then
							replacementEffect = tes3.getObject("T_Nor_Cnj_SummonSpriggan").effects[1]
							spell.effects[i] = replacementEffect
						elseif spell.effects[i].id == tes3.effect.summonCenturionSteam then
							replacementEffect = tes3.getObject("T_Dwe_Cnj_Uni_SummonSteamCent").effects[1]
							spell.effects[i] = replacementEffect
						elseif spell.effects[i].id == tes3.effect.summonCenturionSpider then
							replacementEffect = tes3.getObject("T_Dwe_Cnj_Uni_SummonSpiderCent").effects[1]
							spell.effects[i] = replacementEffect
						end
					end
					
					if me_tr then
						if spell.effects[i].id == tes3.effect.summonWelkyndSpirit then
							replacementEffect = tes3.getObject("T_Ayl_Cnj_SummonWelkyndSpirit").effects[1]
							spell.effects[i] = replacementEffect
						elseif spell.effects[i].id == tes3.effect.summonVermai then
							replacementEffect = tes3.getObject("T_Com_Cnj_SummonVermai").effects[1]
							spell.effects[i] = replacementEffect
						end
					end
				end
				
				if config.boundSpells == true and me_lorefriendly then
					if spell.effects[i].id == tes3.effect.boundGreaves then
						replacementEffect = tes3.getObject("T_Com_Cnj_BoundGreaves").effects[1]
						spell.effects[i] = replacementEffect
					elseif spell.effects[i].id == tes3.effect.boundLeftPauldron then
						replacementEffect = tes3.getObject("T_Com_Cnj_BoundPauldron").effects[1]
						spell.effects[i] = replacementEffect
					elseif spell.effects[i].id == tes3.effect.boundRightPauldron then
						spell.effects[i] = tes3.getObject("T_Com_Cnj_BoundPauldron").effects[8]
					elseif spell.effects[i].id == tes3.effect.boundWarAxe then
						replacementEffect = tes3.getObject("T_Com_Cnj_BoundWarAxe").effects[1]
						spell.effects[i] = replacementEffect
					elseif spell.effects[i].id == tes3.effect.boundWarhammer then
						replacementEffect = tes3.getObject("T_Com_Cnj_BoundWarhammer").effects[1]
						spell.effects[i] = replacementEffect
					elseif spell.effects[i].id == tes3.effect.boundClaymore then
						replacementEffect = tes3.getObject("T_Com_Cnj_BoundGreatsword").effects[1]
						spell.effects[i] = replacementEffect
					end
				end
				
				if config.miscSpells == true then
					if me_lorefriendly then
						if spell.effects[i].id == tes3.effect.banishDaedra then
							replacementEffect = tes3.getObject("T_Com_Mys_BanishDaedra").effects[1]
							spell.effects[i] = replacementEffect
						end
					end

					if me_cortex then
						if spell.effects[i].id == tes3.effect.blink then
							replacementEffect = tes3.getObject("T_Com_Mys_Blink").effects[1]
							spell.effects[i] = replacementEffect
						end
					end
				end
				
				-- Cost is not modified because getAutoCalcMagickaCost() has problems with these ME spells (and T_Com_Mys_BanishDaedra) for unclear reasons
				spell.effects[i].duration = duration
				spell.effects[i].min = min
				spell.effects[i].max = max
				spell.effects[i].radius = area
				spell.effects[i].rangeType = type
			end
		end
	end
end, {priority = -10})