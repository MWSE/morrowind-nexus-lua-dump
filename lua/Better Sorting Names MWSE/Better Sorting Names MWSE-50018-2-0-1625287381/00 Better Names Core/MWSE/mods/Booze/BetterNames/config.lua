local this = {}
this.path = "betternames"
local inMemConfig

-- Config Controller Code by Merlord

-- Gets the config file or a value from the config file

	function this.get()

		return inMemConfig or mwse.loadConfig(this.path)
	end

-- Saves the in-memory config to the file, optionally saves a key value pair first

	function this.save(newConfig)

		inMemConfig = newConfig
		mwse.saveConfig(this.path, newConfig)
	end

return this
