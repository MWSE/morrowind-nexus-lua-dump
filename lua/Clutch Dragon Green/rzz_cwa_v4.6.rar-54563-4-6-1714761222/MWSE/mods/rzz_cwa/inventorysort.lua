local this = {}

---[[ Контроль замороженых предметов в инвентаре
local controlFreez = function(id_test)
	if not data.A_RZZ.itemFreez then return false end
	for __, stack in pairs(data.A_RZZ.itemFreez) do
		if (stack == id_test) then
			return true
		end
	end
	return false
end

---[[ Сортировка предметов по целевым контейнерам
this.cosort = function()
	local tomb = tes3.getObject("A_RZZ_chest_tomb_1")--редикюль+
	local crate_1 = tes3.getObject("A_RZZ_crate_1")--волшебные книги+
	local crate_2 = tes3.getObject("A_RZZ_crate_2")--домашняя утварь+
	local crate_3 = tes3.getObject("A_RZZ_crate_3")--легкие доспехи+
	local crate_4 = tes3.getObject("A_RZZ_crate_4")--средние доспехи+
	local crate_5 = tes3.getObject("A_RZZ_crate_5")--тяжелые доспехи+
	local crate_6 = tes3.getObject("A_RZZ_crate_6")--светильники+
	local sack_1 = tes3.getObject("A_RZZ_sack_1")--одежда+
	local sack_2 = tes3.getObject("A_RZZ_sack_2")--хлам+
	local barrel_1 = tes3.getObject("A_RZZ_barrel_1")--алхимич. аппараты+
	local barrel_2 = tes3.getObject("A_RZZ_barrel_2")--метательное оружие+
	local barrel_3 = tes3.getObject("A_RZZ_barrel_3")--посохи и копья+
	local barrel_4 = tes3.getObject("A_RZZ_barrel_4")--топоры, молоты и дубинки+
	local barrel_5 = tes3.getObject("A_RZZ_barrel_5")--клинки+
	local small_1 = tes3.getObject("A_RZZ_chest_small_1")--стрелы+
	local small_2 = tes3.getObject("A_RZZ_chest_small_2")--болты+
	local small_3 = tes3.getObject("A_RZZ_chest_small_3")--свитки+
	local small_4 = tes3.getObject("A_RZZ_chest_small_4")--кольца и амулеты+
	local small_5 = tes3.getObject("A_RZZ_chest_small_5")--ключи+
	local small_6 = tes3.getObject("A_RZZ_chest_small_6")--документы+
	local small_7 = tes3.getObject("A_RZZ_chest_small_7")--артефакты+
	local small_8 = tes3.getObject("A_RZZ_chest_small_8")--камни душ+
	local small_9 = tes3.getObject("A_RZZ_chest_small_9")--волшебные кольца и амулеты+
	local small_10 = tes3.getObject("A_RZZ_chest_small_10")--особые ключи+
	local small_12 = tes3.getObject("A_RZZ_chest_small_12")--редкие предметы+
	local mumia_1 = tes3.getObject("A_RZZ_mumia_1")--ингридиенты+
	local mumia_2 = tes3.getObject("A_RZZ_mumia_2")--зелья+
	local mumia_3 = tes3.getObject("A_RZZ_mumia_3")--книги+
	local mumia_4 = tes3.getObject("A_RZZ_mumia_4")--инструменты+
	local mumia_5 = tes3.getObject("A_RZZ_mumia_5")--волшебное метательное оружие+
	local mumia_6 = tes3.getObject("A_RZZ_mumia_6")--волшебные посохи и копья+
	local mumia_7 = tes3.getObject("A_RZZ_mumia_7")--волшебные топоры, молоты и дубинки+
	local mumia_8 = tes3.getObject("A_RZZ_mumia_8")--волшебные клинки+
	local mumia_9 = tes3.getObject("A_RZZ_mumia_9")--волшебная одежда+
	local mumia_10 = tes3.getObject("A_RZZ_mumia_L10")--волшебные легкие доспехи+
	local mumia_11 = tes3.getObject("A_RZZ_mumia_M11")--волшебные средние доспехи+
	local mumia_12 = tes3.getObject("A_RZZ_mumia_H12")--волшебные тяжелые доспехи+
	
	local uniqueItem = {
		[0] = "[Uu]nic",
		[1] = "UNIC",
		[2] = "[Uu]niq",
		[3] = "UNIQ",
		[4] = "[Uu]nique",
		[5] = "UNIQUE",
		[6] = "_[Uu]ni",
		[7] = "_UNI",
		--[] = "",
	}
	
	---[[
	--tes3.messageBox{ message = "ok_0->" }
	local equip = {} -- создаём новую пустую таблицу
	for i, node in pairs(tes3.player.object.equipment) do
		-- запоминаем id и ссылки на надетые на ГГ вещи
		equip[node.object.id] = node
	end
	
	for i, stack in pairs(tes3.player.object.inventory) do
		if (stack.object) then
		
			local obj_id = stack.object.id
			local obj_s = stack.object
			
			if (equip[obj_id] or string.find(obj_id,'Gold_') or controlFreez(obj_id)) then goto continue end
			
			if (string.find(obj_id,'A_RZZ')) then --возврат вещей в rzz
				tes3.transferItem{from=tes3.player, to=tomb.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			
			----------сортировка ingredient------------
			if (stack.object.objectType == tes3.objectType.ingredient) then --
				
				local artefactIngred = {
					[0] = "eyeball_unique",
					[1] = "_pinetear",
					[2] = "poison_PelagiadWell",
					[3] = "udyrfrykte_heart",
					[4] = "innocent_heart",
					[5] = "wolf_heart",
					[6] = "treated_bittergreen_uniq",
					--[] = "",
				}
				local uniqueIngred = {
					[0] = "craft_quest",
					[1] = "guar_hide_vd",
					[2] = "nirnroot_red",
					[3] = "skel_cursed_raw_ebony_01",
					[4] = "spider_venom",
					[5] = "swamp_slime",
					[6] = "dragon",
					[7] = "Dae_cursed_",
					--[] = "",
				}
				
				for i = 0,#artefactIngred do--артефакты 
					if string.find(obj_id, artefactIngred[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueIngred do--уникальные вещи
					if string.find(obj_id, uniqueIngred[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				tes3.transferItem{from=tes3.player, to=mumia_1.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------сортировка зелий------------
			if (stack.object.objectType == tes3.objectType.alchemy) then --
				
				artefactAlchemy = {
					[0] = "potion_t_no_baldness",
					[1] = "lovepotion_unique",
					[2] = "lycanthropycure",
					[3] = "bk_colony_Toralf",
					--[] = "",
				}
				uniqueAlchemy = {
					[0] = "a_arena",
					[1] = "elixir_exploration",
					[2] = "potion_ancient_brandy_02",
					[3] = "potion_test_invisible",
					[4] = "p_heroism_s",
					[5] = "p_Imperfect_Elixir",
					[6] = "p_swift_02",
					[7] = "sk_potion_",
					[8] = "ps_strong_",
					--[] = "",
				}
				
				for i = 0,#artefactAlchemy do--артефакты 
					if string.find(obj_id, artefactAlchemy[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueAlchemy do--уникальные вещи
					if string.find(obj_id, uniqueAlchemy[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				tes3.transferItem{from=tes3.player, to=mumia_2.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------сортировка алхимических аппаратов------------
			if (stack.object.objectType == tes3.objectType.apparatus) then --
				tes3.transferItem{from=tes3.player, to=barrel_1.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------сортировка книг------------
			if (stack.object.objectType == tes3.objectType.book) then --
				
				local docItem = {
					[0] = "[Nn]ote",
					[1] = "chargen",
					[2] = "_[Aa][12]_",
					[3] = "report",
					[4] = "recipe",
					[5] = "notice",
					[6] = "stronghold",
					[7] = "orders",
					[8] = "papers",
					[9] = "pass",
					[10] = "mail",
					[11] = "contract",
					[12] = "message",
					[13] = "[Ll]ist",
					[14] = "[Pp]lan",
					[15] = "letter",
					[16] = "intro",
					[17] = "welcome",
					[18] = "miungei",
					[19] = "recommend",
					[20] = "BMtrial",
					[21] = "raving",
					[22] = "Vulpris",
					[23] = "talos",
					[24] = "bk_Nerano",
					[25] = "piratetreasure",
					[26] = "sc_Erna",
					[27] = "Indie",
					[28] = "jeleen",
					[29] = "bk_land",
					[30] = "fur_armor",
					[31] = "leaflet",
					[32] = "taxrecord",
					[33] = "bk_thelostprophecy",
					[34] = "bk_tiramgadarscredentials",
					[35] = "bk_dispelrecipe_tgca",
					[36] = "[Aa]urane",
					[37] = "bk_AlchemistsFormulary",
					[38] = "bk_thesevencurses",
					[39] = "Stockcert",
					[40] = "property",
					[41] = "[Pp]age",
					[42] = "[Jj]ournal",
					[43] = "invoice",
					[44] = "elone",
					[45] = "_BM",
					[46] = "Boethiah",
					[47] = "bk_vivec[_s]",
					[48] = "sc_paper",
					[49] = "bk_And_To",
					[50] = "vd_melvoscode",
					[51] = "paper_roll",
					[52] = "A_RMS_",
					[53] = "diary",
					--[] = "",
				}
				
				local artefactDoc = {
					[0] = "writ_",
					[1] = "hiddenkiller",
					[2] = "lycanthropycure",
					[3] = "bk_colony_Toralf",
					[4] = "EggOfTime",
					[5] = "hanginggardenswasten",
					[6] = "DivineMetaphysics",
					[7] = "Ajira",
					---[] = "",
				}
				
				for i = 0,#artefactDoc do--артефакты 
					if string.find(obj_id, artefactDoc[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#docItem do--документы 
					if string.find(obj_id, docItem[i]) then
						tes3.transferItem{from=tes3.player, to=small_6.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				if (string.find(obj_id,'sc_') and not string.find(obj_id,'sc_GrandfatherFrost') and not string.find(obj_id,'unclesweet')) then --свитки
					tes3.transferItem{from=tes3.player, to=small_3.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (string.find(obj_id,'[Bb]ook[Ss]kil')) then --волшебные книги
					tes3.transferItem{from=tes3.player, to=crate_1.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				tes3.transferItem{from=tes3.player, to=mumia_3.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			---------сортировка инструменты-------------
			if (stack.object.objectType == tes3.objectType.lockpick or stack.object.objectType == tes3.objectType.probe or stack.object.objectType == tes3.objectType.repairItem) then --
				tes3.transferItem{from=tes3.player, to=mumia_4.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			---------сортировка боеприпасов-------------
			if (stack.object.objectType == tes3.objectType.ammunition) then
				
				local uniqueAmmo = {
					[0] = "_sadri",
					[1] = "steel_Arrow_Freezing_Cold",
					[2] = "arena_Ebony_arrow",
					[3] = "Divine",
					[4] = "craft_",
					[5] = "_thirsk",
					[6] = "Arrow_Divine_Light",
					[7] = "daedric_",
					--[] = "",
				}
				
				if (string.find(obj_id,'_Carnius')) then--артефакты 
					tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueAmmo do--уникальные вещи
					if string.find(obj_id, uniqueAmmo[i]) then
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				if (stack.object.type == 12 or string.find(obj_id,'[Aa]rrow')) then --стрелы
					tes3.transferItem{from=tes3.player, to=small_1.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.type == 13) then
					tes3.transferItem{from=tes3.player, to=small_2.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
			end
			---------сортировка оружия-------------
			if (stack.object.objectType == tes3.objectType.weapon) then
				
				local artefactWeapon = {
					[0] = "saber_elberoth",
					[1] = "BM Nordic Pick",
					[2] = "_carnius",
					[3] = "dagger_wolfgiver",
					--[] = "",
				}
				
				local uniqueWeapon = {
					[0] = "[Aa]iran",
					[1] = "azura",
					[2] = "Bipolar",
					[3] = "BM frostgore",
					[4] = "_bloodska",
					[5] = "_spurius",
					[6] = "_mtas",
					[7] = "_seasplitter",
					[8] = "crosierstllothis",
					[9] = "dagoth dagger",
					[10] = "_ttgd",
					[11] = "_tgamg",
					[12] = "Fury",
					[13] = "s_Oath",
					[14] = "nerevarblade_01_flame",
					[15] = "OAAB_w_resin_staff",
					[16] = "OAAB_w_TMora_",
					[17] = "_ttsa",
					[18] = "_Agustas",
					[19] = "daedric_claymore_al",
					[20] = "daedric_longsword_fyr",
					[21] = "Dagger of Judgement",
					[22] = "dagger_soultrap",
					[23] = "halberd_soultrap",
					[24] = "_salandas",
					[25] = "_redas",
					[26] = "_aoz",
					[27] = "_volendrung",
					[28] = "dwarven_mace_eydis",
					[29] = "_aradraen",
					[30] = "_elanande",
					[31] = "_auriel",
					[32] = "_siri",
					[33] = "_tges",
					[34] = "_trebonius",
					[35] = "_volrina",
					[36] = "Gravedigger",
					[37] = "Greed",
					[38] = "_nigga",
					[39] = "Slurring",
					[40] = "_banden",
					[41] = "_visthakai",
					[42] = "solvistapp",
					[43] = "snow",
					[44] = "_sjoring",
					[45] = "Stormkiss",
					[46] = "sunder",
					[47] = "terminus",
					[48] = "trader_",
					[49] = "we_",
					[50] = "Wind of Ahaz",
					[51] = "cleaverstfelms",
					[52] = "caper",
					[53] = "_magebane",
					[54] = "sk_kleymor_02",
					[55] = "sk_dragonp_",
					[56] = "keening",
					[57] = "Almalexia",
					[58] = "Karpal's Friend",
					--[] = "",
				}
				
				for i = 0,#artefactWeapon do--артефакты 
					if string.find(obj_id, artefactWeapon[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue 
					end
				end
				
				for i = 0,#uniqueWeapon do--уникальные вещи
					if string.find(obj_id, uniqueWeapon[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true} 
						goto continue
					end
				end
				
				if (stack.object.type == 9 or stack.object.type == 10 or stack.object.type == 11) then --метательное
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_5.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=barrel_2.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.type == 5 or stack.object.type == 6) then -- посохи и копья
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_6.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=barrel_3.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.type == 7 or stack.object.type == 8 or stack.object.type == 4 or stack.object.type == 3) then --топоры, молоты и дубинки
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=barrel_4.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.type == 0 or stack.object.type == 1 or stack.object.type == 2) then --клинки
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_8.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=barrel_5.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
			end
			---------сортировка одежда-------------
			if (stack.object.objectType == tes3.objectType.clothing) then --
			
				local artefactRopa = {
					[0] = "ring_erna",
					[1] = "infectious",
					[2] = "amulet_delyna",
					[3] = "sarandas_shoes_2",
					[4] = "mazed_band",
					--[] = "",
				}
				
				local uniqueRopa = {
					[0] = "artifact",
					[1] = "Akatosh",
					[2] = "[Aa]zura",
					[3] = "aryon",
					[4] = "_aundae",
					[5] = "_Arobar",
					[6] = "almsivi",
					[7] = "admonition",
					[8] = "_Aesliip",
					[9] = "Aaran_eye",
					[10] = "amulet_gem_feeding",
					[11] = "amulet_Pop00",
					[12] = "amulet_quarra",
					[13] = "Adusamsi",
					
					[14] = "bm_ring_marksman",
					[15] = "balmolagmer",
					[16] = "_berne",
					[17] = "bm_amuls",
					[18] = "bm_black_glove",
					[19] = "blood ring",
					[20] = "blindfold",
					
					[21] = "[Cc]aius",
					[22] = "Crystal_Ball",
					
					[23] = "domination",
					[24] = "drake's pride",
					[25] = "_dagoth",
					[26] = "Daedric_special",
					
					[27] = "sanguine",
					[28] = "shirt_hair",
					[29] = "slippers_of_doom",
					[30] = "st roris",
					[31] = "sarandas",
					[32] = "shadows",
					[33] = "soul ring",
					[34] = "Stendarran",
					[35] = "_Starfire",
					[36] = "Sheogorath",					
					[37] = "seizing",
					[38] = "Septim",
					
					[39] = "Helseth",					
					[40] = "hircine",
					[41] = "hortator",
					
					[42] = "teeth",
					[43] = "thong",
					[44] = "_tmbVivec",
					
					[45] = "mana_",
					[46] = "mantle of woe",
					[47] = "mazed_band_end",
					[48] = "madstone",
					[49] = "moon",
					[50] = "Mara",
					
					[51] = "robe_02_elanande",
					[52] = "Robe_whitewalk",
					[53] = "ring_view",
					[54] = "rilms",
					[55] = "Robe_01_Red",
					
					[56] = "_elranrel",
					[57] = "[Zz]enithar",
					[58] = "_zeht",
					[59] = "_inari",
					[60] = "OAAB_c_TMora_",
					[61] = "ondusi's",
					[62] = "levitating",
					[63] = "foe-",
					[64] = "_gaenor",
					[65] = "verbosity",
					[66] = "Nuccius",
					[67] = "malipu_ataman's_belt",
					--[] = "",
				}
				
				for i = 0,#artefactRopa do--артефакты 
					if string.find(obj_id, artefactRopa[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue 
					end
				end
				
				for i = 0,#uniqueRopa do--уникальные вещи
					if string.find(obj_id, uniqueRopa[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true} 
						goto continue
					end
				end
				
				if (string.find(obj_id,'[Rr]ing') or string.find(obj_id,'[Aa]mulet') or string.find(stack.object.mesh,'[Rr]ing') or string.find(stack.object.mesh,'[Aa]mulet') or string.find(stack.object.mesh,'RING') or string.find(stack.object.mesh,'AMULET')) then--кольца и амулеты
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=small_9.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=small_4.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.enchantment) then
					tes3.transferItem{from=tes3.player, to=mumia_9.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				tes3.transferItem{from=tes3.player, to=sack_1.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------сортировка доспехи------------
			if (stack.object.objectType == tes3.objectType.armor) then
			
				local uniqueArmor = {
					[0] = "wraithguard",
					[1] = "wolfwalkers",
					[2] = "veloths_shield",
					[3] = "trader_",
					[4] = "sk_gretta",
					[5] = "uvenim",
					[6] = "shadow",
					[7] = "undaunted",
					[8] = "rainment_valor",
					[9] = "bagpack",
					[10] = "eddard",
					[11] = "Helmet_ber",
					[12] = "Helmet_heartfang",
					[13] = "_snow",
					[14] = "bonedancer",
					[15] = "s_al",
					[16] = "_en",
					[17] = "boneweave",
					[18] = "_HTNK",
					[19] = "_htab",
					[20] = "clavicusvile",
					[21] = "_verm",
					[22] = "_ttrm",
					[23] = "_technic",
					[24] = "_kzamchend",
					[25] = "_Nchunaks",
					[26] = "_soscean",
					[27] = "_auriel",
					[28] = "gauntlet_horny",
					[29] = "[Gg]auntlet_of_[Gg]lory",
					[30] = "_balen",
					[31] = "_Endyne",
					[32] = "hircine",
					[33] = "Almalexia",
					[34] = "_mage",
					[35] = "_galbedir",
					[36] = "Mountain",
					[37] = "_Antumbra",
					[38] = "tenpaceboots",
					[39] = "trollbone_tshield",
					[40] = "sk_mask_",
					[41] = "azura",
					[42] = "ward of akavir",
					--[] = "",
				}
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue 
					end
				end
				
				for i = 0,#uniqueArmor do--уникальные вещи
					if string.find(obj_id, uniqueArmor[i]) then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true} 
						goto continue
					end
				end
				
				if (stack.object.weightClass == 0) then --легкие
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_10.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=crate_3.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.weightClass == 1) then --средние
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_11.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=crate_4.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (stack.object.weightClass == 2) then --тяжелые
					if (stack.object.enchantment) then
						tes3.transferItem{from=tes3.player, to=mumia_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
					tes3.transferItem{from=tes3.player, to=crate_5.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
			end
			----------сортировка хлама------------
			if (stack.object.objectType == tes3.objectType.miscItem) then --
				
				local artefactXlam = {
					[0] = "artifact",
					[1] = "devote",
					[2] = "bladepiece",
					[3] = "lucky_coin",
					[4] = "ark_cube",
					[5] = "wraithguard_no_equip",
					[6] = "goblet_dagoth",
					[7] = "uniq_egg_of_gold",
					[8] = "ashmask",
					[9] = "goblet_04_dagoth",
					[10] = "skull_griss",
					[11] = "Skull_Llevule",
					[12] = "skull_Skaal",
					[13] = "_hrmm",
					[14] = "dwrv_weather",
					[15] = "fury",
					[16] = "BM_waterlife_UNIQUE1",
					[17] = "BM_Seeds_UNIQUE",
					[18] = "BM_bearheart_UNIQUE",
					[19] = "Misc_BM_ClawFang_UNIQUE",
					[20] = "skull_oddfrid",
					[21] = "fakesoulgem",
					--[] = "",
				}
				local domXlam = {
					[0] = "goblet",
					[1] = "plate",
					[2] = "[Pp]itcher",
					[3] = "bowl",
					[4] = "[Cc]up",
					[5] = "flask",
					[6] = "platter",
					[7] = "vase",
					[8] = "fork",
					[9] = "knife",
					[10] = "spoon",
					[11] = "tankard",
					[12] = "pot",
					[13] = "glass",
					[14] = "_mug",
					[15] = "break",
					[16] = "ladle",
					[17] = "[Bb]ottle",
					[18] = "statue",
					[19] = "coin00",
					[20] = "broom",
					[21] = "fishing_pole",
					[22] = "[Pp]illow",
					[23] = "6th_ash",
					--[] = "",
				}
				
				local uniqueXlam = {
					[0] = "sigil_stone",
					[1] = "dwembox_",
					--[] = "",
				}
				
				if (string.find(obj_id,'index_') or string.find(obj_id,'key_hircine') or string.find(obj_id,'dwrv_ark_key') or string.find(obj_id,'mamaea') or string.find(obj_id,'key_sphere')) then--особые ключи 
					tes3.transferItem{from=tes3.player, to=small_10.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (string.find(obj_id,'[Kk]ey_')) then--ключи
					tes3.transferItem{from=tes3.player, to=small_5.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				for i = 0,#artefactXlam do--артефакты 
					if string.find(obj_id, artefactXlam[i]) then
						tes3.transferItem{from=tes3.player, to=small_7.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				for i = 0,#uniqueItem do--уникальные вещи
					if string.find(obj_id, uniqueItem[i]) and not string.find(obj_id,'[Pp]illow') then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue 
					end
				end
				
				for i = 0,#uniqueXlam do--уникальные вещи
					if string.find(obj_id, uniqueXlam[i]) and not string.find(obj_id,'[Pp]illow') then 
						tes3.transferItem{from=tes3.player, to=small_12.id, item=obj_s, count=stack.count, playSound=true}
						goto continue 
					end
				end
				
				for i = 0,#domXlam do--домашняя утварь 
					if string.find(obj_id, domXlam[i]) then
						tes3.transferItem{from=tes3.player, to=crate_2.id, item=obj_s, count=stack.count, playSound=true}
						goto continue
					end
				end
				
				if (string.find(obj_id,'SoulGem')) then--камни душ
					tes3.transferItem{from=tes3.player, to=small_8.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				if (string.find(obj_id,'bellows')) then--инструмент ремесленика
					tes3.transferItem{from=tes3.player, to=mumia_4.id, item=obj_s, count=stack.count, playSound=true}
					goto continue
				end
				
				tes3.transferItem{from=tes3.player, to=sack_2.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------сортировка светильников------------
			if (stack.object.objectType == tes3.objectType.light) then
				tes3.transferItem{from=tes3.player, to=crate_6.id, item=obj_s, count=stack.count, playSound=true}
				goto continue
			end
			----------------------
		end
		::continue::
    end
	--tes3.messageBox{ message = "Сортировка завершена" }
end

---[[ Возврат игроку предметов
this.resort = function()
	local containers = {}
	containers[0] = tes3.getReference("A_RZZ_crate_1")--волшебные книги+
	containers[1] = tes3.getReference("A_RZZ_crate_2")--домашняя утварь+
	containers[2] = tes3.getReference("A_RZZ_crate_3")--легкие доспехи+
	containers[3] = tes3.getReference("A_RZZ_crate_4")--средние доспехи+
	containers[4] = tes3.getReference("A_RZZ_crate_5")--тяжелые доспехи+
	containers[5] = tes3.getReference("A_RZZ_crate_6")--светильники+
	containers[6] = tes3.getReference("A_RZZ_sack_1")--одежда+
	containers[7] = tes3.getReference("A_RZZ_sack_2")--хлам+
	containers[8] = tes3.getReference("A_RZZ_barrel_1")--алхимич. аппараты+
	containers[8] = tes3.getReference("A_RZZ_barrel_1_tmp")--алхимич. аппараты+
	containers[9] = tes3.getReference("A_RZZ_barrel_2")--метательное оружие+
	containers[10] = tes3.getReference("A_RZZ_barrel_3")--посохи и копья+
	containers[11] = tes3.getReference("A_RZZ_barrel_4")--топоры, молоты и дубинки+
	containers[12] = tes3.getReference("A_RZZ_barrel_5")--клинки+
	containers[13] = tes3.getReference("A_RZZ_chest_small_1")--стрелы+
	containers[14] = tes3.getReference("A_RZZ_chest_small_2")--болты+
	containers[15] = tes3.getReference("A_RZZ_chest_small_3")--свитки+
	containers[16] = tes3.getReference("A_RZZ_chest_small_4")--кольца и амулеты+
	containers[17] = tes3.getReference("A_RZZ_chest_small_5")--ключи+
	containers[18] = tes3.getReference("A_RZZ_chest_small_6")--документы+
	containers[19] = tes3.getReference("A_RZZ_chest_small_7")--артефакты+
	containers[20] = tes3.getReference("A_RZZ_chest_small_8")--камни душ+
	containers[21] = tes3.getReference("A_RZZ_chest_small_9")--волшебные кольца и амулеты+
	containers[22] = tes3.getReference("A_RZZ_chest_small_10")--особые ключи+
	containers[22] = tes3.getReference("A_RZZ_chest_small_12")--особые ключи+
	containers[23] = tes3.getReference("A_RZZ_mumia_1")--ингридиенты+
	containers[24] = tes3.getReference("A_RZZ_mumia_2")--зелья+
	containers[25] = tes3.getReference("A_RZZ_mumia_3")--книги+
	containers[26] = tes3.getReference("A_RZZ_mumia_4")--инструменты+
	containers[27] = tes3.getReference("A_RZZ_mumia_5")--волшебное метательное оружие+
	containers[28] = tes3.getReference("A_RZZ_mumia_6")--волшебные посохи и копья+
	containers[29] = tes3.getReference("A_RZZ_mumia_7")--волшебные топоры, молоты и дубинки+
	containers[30] = tes3.getReference("A_RZZ_mumia_8")--волшебные клинки+
	containers[31] = tes3.getReference("A_RZZ_mumia_9")--волшебная одежда+
	containers[32] = tes3.getReference("A_RZZ_mumia_L10")--волшебные легкие доспехи+
	containers[33] = tes3.getReference("A_RZZ_mumia_M11")--волшебные средние доспехи+
	containers[34] = tes3.getReference("A_RZZ_mumia_H12")--волшебные тяжелые доспехи+
	containers[35] = tes3.getReference("A_RZZ_crate_7")--ингридиенты буфер+
	containers[36] = tes3.getReference("A_RZZ_crate_8")--зелья буфер+
	containers[37] = tes3.getReference("A_RZZ_chest_small_3_tmp")--свитки буфер+
	containers[38] = tes3.getReference("A_RZZ_chest_small_9_tmp")--кольца и амулеты буфер+
	containers[38] = tes3.getReference("A_RZZ_chest_s_12_tmp")--редкие предметы буфер+
	
	for i = 0,#containers do
		for __, items in pairs(containers[i].object.inventory) do
			if (items.object) then
				tes3.transferItem{from=containers[i], to=tes3.player, item=items.object, count=items.count, playSound=true}
			end
		end
	end
end

---[[ Заморозка предметов в инвентаре
this.Freez = function()
	data.A_RZZ.itemFreez = {}
	for i, stack in pairs(tes3.player.object.inventory) do
		if (stack.object) then
			data.A_RZZ.itemFreez[i] = stack.object.id
		end
	end
	data.A_RZZ.isFreez = true
end

---[[ Разморозка предметов в инвентаре
this.antiFreez = function()
	data.A_RZZ.itemFreez = nil
	data.A_RZZ.isFreez = nil
end

return this