local content = require('openmw.content')

if not content then return end

if not content.gameSettings then return end

content.gameSettings.records["sLevelUpMsg"] = ""
