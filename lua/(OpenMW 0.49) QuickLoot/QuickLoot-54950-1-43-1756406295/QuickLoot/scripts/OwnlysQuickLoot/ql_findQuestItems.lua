json = require "jsonStorage"

path = "D:\\"

paths = {
(path.."morrowind.json"),
(path.."tribunal.json"),
(path.."bloodmoon.json"),
(path.."tamriel_data.json"),
(path.."tr_mainland.json"),
(path.."tr_factions.json")
}
scripts = {}
items = {}
local types = {}

local itemBlacklist = {
["misc_soulgem_petty"] = true,
["misc_soulgem_azura"] = true,
["misc_soulgem_common"] = true,
["misc_soulgem_grand"] = true,
["misc_soulgem_lesser"] = true,
["misc_soulgem_greater"] = true,
["gold_001"] = true,
["potion_local_liquor_01"] = true, --sujamma tr_m4_andohh_sujammacrate
["potion_cyro_whiskey_01"] = true, --flin  "colonyaldam"
["iron spear"] = true, --This is the Shrine to the Battle of Bodrum, one of the Temple pilgrimage shrines.\r\n\r\nshort button\r\nshort questionState\r\nshort doOnce\r\n\r\nif ( OnActivate == 1 )\r\n\tSet questionState to 1\r\n\tReturn\r\nendif\r\n\r\nif ( questionState == 0 )\r\n\tReturn\r\nendif\r\n\r\nif ( questionState == 1 )\r\n\r\n\tif ( Player->GetItemCount \"iron spear\" > 0 )\r\n\t\tMessageBox \"
["iron long spear"] = true, --This is the Shrine to the Battle of Bodrum, one of the Temple pilgrimage shrines.\r\n\r\nshort button\r\nshort questionState\r\nshort doOnce\r\n\r\nif ( OnActivate == 1 )\r\n\tSet questionState to 1\r\n\tReturn\r\nendif\r\n\r\nif ( questionState == 0 )\r\n\tReturn\r\nendif\r\n\r\nif ( questionState == 1 )\r\n\r\n\tif ( Player->GetItemCount \"iron spear\" > 0 )\r\n\t\tMessageBox \"
["p_restore_health_s"] = true, --rothisscript HR_CowardDisgrace https://en.uesp.net/wiki/Morrowind:Duel_of_Honor
["slave_bracer_right"] = true,
["slave_bracer_left"] = true,
["p_cure_common_s"] = true, --cure common disease
["miner's pick"] = true, -- common
["potion_skooma_01"] = true, -- for tr_m4_npc_bthuangthuvsquatter

}

local scriptBlacklist = {
["tr_m1_q_drinkschest_script"] = true, --alc
["tr_m2_q_9_dreynisscript"] = true, --alc
["tr_m3_q_3_vaultwatcher_sc"] = true, --keeps track of what the PC steals from the Vault impunitamente
["t_sccrea_armorcenturionequip"] = true, --Since we can't have \"smart\" leveled lists, such as \"one sword or one crossbow and twenty bolts\",\r\n; this script manages the centurion's equipment based on his leveled list result.
--["tr_m3_q_oe_mg_manielscript"] = true, --https://en.uesp.net/wiki/Tamriel_Rebuilt:Don%27t_Touch_My_Gems!
["tr_m3_aillijarescapescript"] = true, --invisibility potion for escape
["tr_m2_q_a9_1_sathysn_scr"] = true, --3 of 20 holy books for https://en.m.uesp.net/wiki/Tamriel_Rebuilt:Preaching_by_Proxy
["shrinestopmoon"] = true, -- any levitation potion
["tr_m3_npc_giacinia_andelius"] = true, -- https://en.uesp.net/wiki/Tamriel_Rebuilt:Friends_with_Rats
["tr_m1_fw_gummidge_script"] = true, -- tr_m1_fw_gummidge_script https://en.uesp.net/wiki/Tamriel_Rebuilt:Gummidge
["tr_m2_q_a8_6_eifidscript"] = true, -- checks if npc has silver bolts left
["tr_m4_q_amandin_platier_sc"] = true, -- npc equipment manager silver flaming sword
["tr_m7_npc_bolnor_selvilo"] = true,   -- npc equipment manager short silver sword, exquisite_shoes_01, key
["tr_m4_npc_sarus_savrethi"] = true,   -- npc equipment manager steel shortsword
["tr_m1_fw_fedrinshipmentscript"] = true,   -- exquisite clothing shipment quest
["db_assassinscript"] = true,   -- adds flavor text (? sets stage to 20) if player has unique ebony dart https://en.uesp.net/wiki/Tribunal:Dark_Brotherhood_Attacks
["tr_m7_pedestal_muatra_sc"] = true,   -- choose chitin or T_De_Dreugh_Spear_01

}
--hardcoded:
-- ["bk_a1_1_caiuspackage"] = true,


local itemsWithMwscripts = {}

local itemCount = 0
for _, path in pairs(paths) do
	esp = json.loadTable(path)
	for a,b in pairs(esp) do
		if b.data and (b.data.weight or b.data.Weight) and (b.data.value or b.data.Value) then
			types[b.type:lower()] = true
			if not itemBlacklist[b.id:lower()] and (b.type:lower() == "miscitem" or b.type:lower() == "book") then --category filter?
				items[b.id:lower()] = {}
				if b.script then
					itemsWithMwscripts[b.id:lower()] = b.script:lower()
				end
				itemCount = itemCount + 1
			end
		end
		if b.type:lower() == "script" then
			scripts[b.id:lower()] = b.text
		end
	end
end

for a,b in pairs(types) do
	print(a)
end
local export = "return {\n"
local done = 0
local relevantScripts = {}
local relevantScriptCounter = {}
for iId, t in pairs(items) do
	if done %100 == 0 then print(done.."/"..itemCount) end
	local delEntry = true
	for sId, text in pairs(scripts) do
		if not scriptBlacklist[sId] and sId:sub(1,#"chargen") ~= "chargen" and text:lower():find(iId:lower()) then
			local pos = text:lower():find(iId:lower())
			local suffix = text:lower():sub(pos+#iId,pos+#iId)
			if suffix ~= "_" then
				local passage = text:lower():sub(pos-23,pos)--+#iId+5)
				if passage:find("getitemcount") then
					
					local passage2 = text:lower():sub(pos-23+passage:find("getitemcount")-16,pos-23+passage:find("getitemcount"))--+#iId+5)
					if not passage2:lower():find("->") or passage2:lower():find("player") then
						--print(passage2)
						--print(passage)
						--print("")
						--print(iId)
						--print("-----")
						--t[sId] = text
						table.insert(t,sId)
						relevantScripts[sId] = text
						relevantScriptCounter[sId] = (relevantScriptCounter[sId] or 0) + 1
						--print("\t"..sId)
						delEntry = false
					end
				end
			end
		end
	end
	if delEntry then
		items[iId] = nil
	else
		export = export..'["'..iId..'"] = true,\n'
	end
	done=done+1
end
export = export.."}"

for a,b in pairs(itemsWithMwscripts) do
	itemsWithMwscripts[a] = scripts[b]
end



local file = io.open(path.."ql_questItems.lua", "w") 
file:write(export)
file:close()
--print(export)
json.saveTable(items, path.."allQuestItems.json")
json.saveTable(relevantScripts, path.."allQuestItemScripts.json")
json.saveTable(relevantScriptCounter, path.."questItemScriptCounter.json")
json.saveTable(itemsWithMwscripts, path.."itemsWithMwscripts.json")