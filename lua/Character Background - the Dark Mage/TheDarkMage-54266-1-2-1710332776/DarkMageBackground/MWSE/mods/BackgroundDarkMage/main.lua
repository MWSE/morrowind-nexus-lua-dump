local function getData()
    local data = tes3.player.data.merBackgrounds or {};
    return data;
end

local function initialize()

	local interop = require("mer.characterBackgrounds.interop");
	
	local darkMage = {
		id = "darkMageBk",
		name = "Dark Mage",
		description = ( "You were apprenticed to a warlock and are adept at " ..
			"casting debilitating curses and blasts of dark energies. Drain spell effects " ..
			"you cast are twice as powerful. But your focus on this specific subset leaves you " ..
			"incapable of casting fire, frost or shock spells.\n\nRequirements: Destruction cannot be a misc skill."),
		
		checkDisabled = function()
			local sType = tes3.mobilePlayer.destruction.type;
			return sType == tes3.skillType.misc;
		end,

		callback = function()
				
			local function missChance(e)
		  
				local data = getData();

				if (data.currentBackground == "darkMageBk") then
					--tes3.messageBox({message = "background ok"});
					if (e.source.castType == tes3.spellType.spell and e.caster == tes3.player) then
						--tes3.messageBox({message = "source ok"});
						for _, value in pairs(e.source.effects) do
							if (value.id > 13 and value.id < 17) then
								e.castChance = 0;
								--tes3.messageBox({message = "effect ok"});
								break;
							end
						end
					end
				end
			end

			local function effectBonus(e)

				local data = getData();

				if (data.currentBackground == "darkMageBk") then
					if (e.source.castType == tes3.spellType.spell and e.caster == tes3.player) then
						if (e.effect.id > 16 and e.effect.id < 22) then
							--tes3.messageBox({message = "effect ok"});
							tes3.applyMagicSource(
								{	reference = e.target,
									name = "Dark Mage's Expertise",
									effects = {{
										id = e.effect.id,
										skill = e.effect.skill,
										attribute = e.effect.attribute,
										min = e.effect.min,
										max = e.effect.max,
										duration = e.effect.duration
									}}
								}
							);
						end
					end
				end
			end

			event.register("spellCast", missChance);
			event.register("spellResist", effectBonus);
		end
	}
	
	interop.addBackground(darkMage);

	--tes3.messageBox({message = "Initialized!"});
end

event.register("initialized", initialize);