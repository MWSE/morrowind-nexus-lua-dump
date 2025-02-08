local defaultConfig = {
	usewl = false,
	nwlvalue = 10,
	static = false,
	staticvd = 0,
	prediction = false,
	predrange = 50,
	target = 60,
	agro = 1,
	delta = false,
	threshold = 10,
	changerate = 1,
	smooth = true,
	smoothagro = 2,
	wlthres = 40,
	autoadd = true,
	usegridlist = true
}
return mwse.loadConfig("DFPSO", defaultConfig)