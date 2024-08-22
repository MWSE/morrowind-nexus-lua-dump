local this = {}
this.configPath = "Tea Merchants"
this.defaultConfig = {
	barterGoldFix = true,
	logLevel = "INFO",
	teaMerchants = {
		-- manually picked merchants that have teaTypes available
		["anarenen"] = true, -- Ald'ruhn, heather/comberry
		["andil"] = true, -- Tel Vos, black anther/gold kanet/stoneflower/kresh fiber/scathecraw
		["andilu drothan"] = true, -- Vivec Foreign Quarter, trama root/gold kanet/comberry/heather
		["anis seloth"] = true, -- Sadrith Mora, coda flower/hackle-lo/trama root/heather
		["ajira"] = true, -- Balmora, black anther/comberry/heather
		["aurane frernis"] = true, -- Vivec Foreign Quarter, black anther/coda flower
		["bildren areleth"] = true, -- Tel Aruhn, bittergreen/stoneflower/kresh fiber/heather
		["cocistian quaspus"] = true, -- Buckmoth, scathecraw/fire petal/bittergreen/kresh fiber/stoneflower
		["danoso andrano"] = true, -- Ald'ruhn, roobrush/coda flower
		["daynali dren"] = true, -- Tel Mora, black anther/gold kanet/hackle-lo/trama root
		["felara andrethi"] = true, -- Tel Aruhn, chokeweed/comberry
		["galuro belan"] = true, --	Vivec Telvanni Canton, fire petal/stonflower/scathecraw/kresh fiber
		["irna maryon"] = true, -- 	Tel Aruhn, roobrush/scathecraw/fire petal
	},
}

return mwse.loadConfig(this.configPath, this.defaultConfig)
