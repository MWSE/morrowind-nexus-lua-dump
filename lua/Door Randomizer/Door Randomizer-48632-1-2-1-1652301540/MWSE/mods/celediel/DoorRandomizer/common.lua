local this = {}

this.modName = "Door Randomizer" -- or something
this.author = "Celediel"
this.version = "1.2.0"
this.modInfo = "When a cell-change door is activated, its destination is randomized, based on various configuration options"
this.configPath = string.gsub(this.modName, "%s+", "")
this.cellTypes = {
    interior = 0,
    exterior = 1,
    both = 2,
    match = 3
}

this.log = function(...) mwse.log("[%s] %s", this.modName, string.format(...)) end

return this
