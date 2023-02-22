local defaultConfig = {
    modEnabled = true,
        revelationCount = 10,
		privilegedRank = 7,
		writTargets = {
			["feruren oran"] = "MT_WritOran",
			["sarayn sadus"] = "MT_WritSadus",
			["baladas demnevanni"] = "MT_WritBaladas",
			["tirer belvayn"] = "MT_WritBelvayn",
			["mathyn bemis"] = "MT_WritBemis",
			["dram bero"] = "MT_WritBero",
			["brilnosu llarys"] = "MT_WritBrilnosu",
			["galasa uvayn"] = "MT_WritGalasa",
			["guril retheran"] = "MT_WritGuril",
			["mavon drenim"] = "MT_WritMavon",
			["Navil Ienith"] = "MT_WritNavil",
			["Ranes Ienith"] = "MT_WritNavi",
			["toris saren"] = "MT_WritSaren",
			["therana"] = "MT_WritTherana",
			["larrius varro"] = "MT_WritVarro",
			["idroso vendu"] = "MT_WritVendu",
			["ethal seloth"] = "MT_WritVendu",
			["odaishah yasalmibaal"] = "MT_WritYasalmibaal",
			--[""] = "",
		},
        closedHelmets = {
			smt_hl_op = true
        },

		moragTongItems = {
            common_robe_03_b = true,
            common_shirt_03_b = true,
			T_De_MoragTong_Skirt_01 = true,
			NX9_Tong_Boots = true,
			NX9_Tong_Cuirass = true,
			NX9_Tong_Gauntlet_L = true,
			NX9_Tong_Gauntlet_R = true,
			NX9_Tong_Greaves = true,
			NX9_Tong_Pauldron_L = true,
			NX9_Tong_Pauldron_R = true,
			CS_MMTC = true,
			CS_MMTCB = true,
			CS_MMTCG = true,
			CS_MMTCH = true,
			CS_MMTLPL = true,
			CS_MMTRPL = true,
			CS_MTC = true,
			CS_MTLGN = true,
			CS_MTLPL = true,
			CS_MTRGN = true,
			CS_MTRPL = true,
			smt_boots = true,
			smt_chest = true,
			smt_chest_01 = true,
			smt_greaves = true,
			smt_hl_cl = true,
			smt_hl_op = true,
			smt_pl_l = true,
			smt_pl_r = true,
			smt_wr_l = true,
			smt_wr_r = true
		}
}


for item in tes3.iterateObjects(tes3.objectType.armor) do
	if item.parts and item.parts[1].type == 0 then
        defaultConfig.closedHelmets[item.id] = true
    end

	local id = string.lower(item.id)

	if string.find(id, "morag_tong") or string.find(id, "moragtong") then
		defaultConfig.moragTongItems[item.id] = true
	end
end

local mwseConfig = mwse.loadConfig("moragTong", defaultConfig)

return mwseConfig;