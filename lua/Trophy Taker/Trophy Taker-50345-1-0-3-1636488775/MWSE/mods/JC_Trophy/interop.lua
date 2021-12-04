local config = require ("JC_Trophy.trophies_config")
require("table")
local this = {}

function this.addNameLink (id, itemgroup) 
	config.nameLinks[id] = itemgroup
end

function hasKey(tab, key)
    return tab[key]~=nil
end

function this.addItem(groupname, item)
	mwse.log(hasKey(config.creatureTrophies, groupname))
	if not hasKey(config.creatureTrophies, groupname) then
		config.creatureTrophies[groupname] = {item}
	else
		mwse.log(config.creatureTrophies[groupname])
		table.insert(config.creatureTrophies[groupname],item)
	end
	
end

return this