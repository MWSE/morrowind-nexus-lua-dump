local configPath = "Furniture Catalogue"
local defaultConfig = {
	stockAmount = 50,
	debugMode = false,
	furnitureMerchants = {
		["ababael timsar-dadisun"] = true, -- Ashlander, Zainab Camp
		["areas"] = true, -- Clan Quarra, Druscashti, Lower Level
		["marasa aren"] = true, -- Camonna Tong, Balmora, Council Club
		["alveno andules"] = true, -- Hlaalu, Vivec, Hlaalu Pawnbroker
		["ravoso aryon"] = true, -- Hlaalu, Suran, Oran Manor
		["hlendrisa seleth"] = true, -- Telvanni, Tel Uvirith
		["both gro-durug"] = true, -- Thieves Guild, Sadrith Mora, Dirty Muriel's
		["hinald"] = true, -- Thieves Guild, Gnaar Mok, Dreugh-jigger's Rest

		["daynes redothril"] = true, -- Ald'ruhn, Daynes Redothril: Pawnbroker
		["irgola"] = true, -- Caldera, Irgola: Trader
		["fryfnhild"] = true, -- Dagon Fel, The End of the World
		["sunel hlas"] = true, -- Mournhold, Trader
		["ferele athram"] = true, -- Tel Aruhn, Ferele Athram: Trader
		["baissa"] = true, -- Vivec, Foreign Quarter Upper Waistworks
		["mevel fererus"] = true, -- Vivec, St Delyn, Mevel Fererus: Trader
		-- TR
		["tr_m1_fainat masiriran"] = true, -- Ashlander, Firewatch
		["tr_m3_darane navur"] = true, -- Indoril, Almas Thirr, Darane Navur
		["tr_m4_tuls_varalaryn"] = true, -- Redoran, Bodrum, Varalaryn Tradehouse
		["tr_m1_llathros_edri"] = true, -- Telvanni, Port Telvannis, Llathros Edri: Pawnbroker

		["tr_m1_kobin_delas"] = true, -- Ranyon-ruhn
		["tr_m2_fevras_beran"] = true, -- Alt Bosara, Fevras Beran's General Supplies
		["tr_m2_rathal senoril"] = true, -- Necrom, Rathal Senoril: Trader
		["tr_m2_audania ranius"] = true, -- The Inn Between
		["tr_m2_neldam_volothre"] = true, -- Verulas Pass, Neldam Volothre: Trader
		["tr_m3_rilver thelas"] = true, -- Aimrah
		["tr_m3_dralin_thiravyn"] = true, -- Enamor Dayn
		["tr_m3_orto rumaria"] = true, -- Old Ebonheart, Orto Rumaria: Outfitter
		["tr_m3_golveso_darys"] = true, -- Sailen, Golveso Darys: Pawnbroker
		["tr_m4_angunas"] = true, -- Andothren, Angunas: Pawnbroker
		["tr_m4_baram hlervi"] = true, -- Arvud, Bazaar
		["tr_m4_malmas habattu"] = true, -- Kurhu
		-- PC
		["pc_1-str_mira"] = true, -- Stirk, Mira's Trade Goods
		-- Sky
		["sky_ire_dsw_semaruc"] = true, -- Dragonstar West, Great Bazaar
		["sky_ire_kw_jolnor"] = true, -- Karthwastern, Jolnor: Trader
		["sky_ire_vs_sorri"] = true, -- Vorngyd's Stand, Barracks
	},
}

---@class furnitureCatalogue.config
---@field stockAmount integer
---@field debugMode boolean
---@field furnitureMerchants table<string, boolean>
local config = mwse.loadConfig(configPath, defaultConfig)
return config
