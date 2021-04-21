local function countSpellbooks(e)

    local caster = e.caster
	local source = e.source
	local sourceInstance = e.sourceInstance
	

		--tome of fireballs
	if (source.id == "_wushu_spellbook_fire9") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire8", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire8") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire7", count = 1})
    end
    if (source.id == "_wushu_spellbook_fire7") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire6", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire6") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire5", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire4", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire3", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire2", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire1", count = 1})
    end
	if (source.id == "_wushu_spellbook_fire1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fire0", count = 1})
    end
	
		--tome of great fireballs
	if (source.id == "_wushu_spellbook_great_fire5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_fire4", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_fire4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_fire3", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_fire3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_fire2", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_fire2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_fire1", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_fire1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_fire0", count = 1})
    end
	
		--tome of healing
	if (source.id == "_wushu_spellbook_heal6") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal5", count = 1})
    end
	if (source.id == "_wushu_spellbook_heal5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal4", count = 1})
    end
	if (source.id == "_wushu_spellbook_heal4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal3", count = 1})
    end
	if (source.id == "_wushu_spellbook_heal3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal2", count = 1})
    end
	if (source.id == "_wushu_spellbook_heal2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal1", count = 1})
    end
	if (source.id == "_wushu_spellbook_heal1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_heal0", count = 1})
    end
	
		--tome of great healing
	if (source.id == "_wushu_spellbook_great_heal3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_heal2", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_heal2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_heal1", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_heal1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_heal0", count = 1})
    end
	
		--tome of skelly bois
	if (source.id == "_wushu_spellbook_army5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_army4", count = 1})
    end
	if (source.id == "_wushu_spellbook_army4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_army3", count = 1})
    end
	if (source.id == "_wushu_spellbook_army3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_army2", count = 1})
    end
	if (source.id == "_wushu_spellbook_army2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_army1", count = 1})
    end
	if (source.id == "_wushu_spellbook_army1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_army0", count = 1})
    end
	
		--tome of witchhunter
	if (source.id == "_wushu_spellbook_witchhunter6") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter5", count = 1})
    end
	if (source.id == "_wushu_spellbook_witchhunter5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter4", count = 1})
    end
	if (source.id == "_wushu_spellbook_witchhunter4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter3", count = 1})
    end
	if (source.id == "_wushu_spellbook_witchhunter3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter2", count = 1})
    end
	if (source.id == "_wushu_spellbook_witchhunter2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter1", count = 1})
    end
	if (source.id == "_wushu_spellbook_witchhunter1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_witchhunter0", count = 1})
    end
	
		--tome of poison fangs
	if (source.id == "_wushu_spellbook_poison4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_poison3", count = 1})
    end
	if (source.id == "_wushu_spellbook_poison3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_poison2", count = 1})
    end
	if (source.id == "_wushu_spellbook_poison2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_poison1", count = 1})
    end
	if (source.id == "_wushu_spellbook_poison1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_poison0", count = 1})
    end
	
		--tome of pure body
	if (source.id == "_wushu_spellbook_body4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_body3", count = 1})
    end
	if (source.id == "_wushu_spellbook_body3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_body2", count = 1})
    end
	if (source.id == "_wushu_spellbook_body2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_body1", count = 1})
    end
	if (source.id == "_wushu_spellbook_body1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_body0", count = 1})
    end
	
		--tome of pure soul
	if (source.id == "_wushu_spellbook_soul4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_soul3", count = 1})
    end
	if (source.id == "_wushu_spellbook_soul3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_soul2", count = 1})
    end
	if (source.id == "_wushu_spellbook_soul2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_soul1", count = 1})
    end
	if (source.id == "_wushu_spellbook_soul1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_soul0", count = 1})
    end
	
		--tome of astral chains
	if (source.id == "_wushu_spellbook_chains3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_chains2", count = 1})
    end
	if (source.id == "_wushu_spellbook_chains2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_chains1", count = 1})
    end
	if (source.id == "_wushu_spellbook_chains1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_chains0", count = 1})
    end
	
		--tome of mass hysteria
	if (source.id == "_wushu_spellbook_fear5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fear4", count = 1})
    end
	if (source.id == "_wushu_spellbook_fear4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fear3", count = 1})
    end
	if (source.id == "_wushu_spellbook_fear3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fear2", count = 1})
    end
	if (source.id == "_wushu_spellbook_fear2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fear1", count = 1})
    end
	if (source.id == "_wushu_spellbook_fear1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_fear0", count = 1})
    end
	
		--tome of manaing
	if (source.id == "_wushu_spellbook_mana6") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana5", count = 1})
    end
	if (source.id == "_wushu_spellbook_mana5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana4", count = 1})
    end
	if (source.id == "_wushu_spellbook_mana4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana3", count = 1})
    end
	if (source.id == "_wushu_spellbook_mana3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana2", count = 1})
    end
	if (source.id == "_wushu_spellbook_mana2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana1", count = 1})
    end
	if (source.id == "_wushu_spellbook_mana1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_mana0", count = 1})
    end
	
		--tome of great manaing
	if (source.id == "_wushu_spellbook_great_mana3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_mana2", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_mana2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_mana1", count = 1})
    end
	if (source.id == "_wushu_spellbook_great_mana1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_great_mana0", count = 1})
    end
	
		--tome of frozen touch
	if (source.id == "_wushu_spellbook_ice5") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_ice4", count = 1})
    end
	if (source.id == "_wushu_spellbook_ice4") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_ice3", count = 1})
    end
	if (source.id == "_wushu_spellbook_ice3") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_ice2", count = 1})
    end
	if (source.id == "_wushu_spellbook_ice2") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_ice1", count = 1})
    end
	if (source.id == "_wushu_spellbook_ice1") then
		mwscript.addItem({reference = caster, item = "_wushu_tome_ice0", count = 1})
    end
end

local function buttonPress(e) --started on button press
local index = "0"
local newid = item.id --get current tome id
	if e.button == 1 then
			if (cost == 0) then
				tes3.messageBox({ message = "This tome cannot hold more charges."}) --tomes with max charges have enchant cap set to 0 in CS
			elseif (tes3.mobilePlayer.magicka.current < cost) then
				tes3.messageBox({ message = "You are not powerful enough to charge this tome."}) --break if PC does not have required MP
				mwscript.playSound{reference=player, sound="Enchant Fail"}
			elseif (cost > 0) then		
				tes3.mobilePlayer.magicka.current = tes3.mobilePlayer.magicka.current - cost  --lower player's MP by cost
				tes3.messageBox({ message = "Successfuly charged!"})
				mwscript.playSound{reference=player, sound="Enchant Success"}
				mwscript.removeItem({reference = tes3.player, item = item.id, count = 1}) --remove previous tome from inventory
				index = newid:sub(-1) + 1
				newid = newid:sub(1, -2)
				mwscript.addItem({reference = tes3.player, item = newid..index, count = 1}) --grant player a tome with +1 uses
			end
	end
end

function chargeSpellbooks(e)

reference = e.reference
item = e.item


	if (string.startswith(item.id, "_wushu_tome")) then --start when tome is used on paperdoll
		cost = item.enchantCapacity --cost in mana to recharge always equals to items enchant cap in CS
		tes3.messageBox{ 
			message = "You have chosen " .. item.name, 
			buttons = { "Leave it","Recharge (Cost: "..cost.." magicka)"}, 
			callback = buttonPress, 
		}
		
	end
end


 -- The function to call on the initialized event.
local function initialized()
    event.register("magicCasted", countSpellbooks)
	event.register("equip", chargeSpellbooks)
end

 -- Register our initialized function to the initialized event.
event.register("initialized", initialized)





