return mwse.loadConfig("DesignedForWhom", {
	blocklistToggle = true,
    alwaysLog = false,
    showInGame = true,
    cleanPlugins = true,
    separateLog = false,
	blocklist = {
        ["morrowind.esm"] = true,
        ["tribunal.esm"] = true,
        ["bloodmoon.esm"] = true,
    },
    stringTable = {
        ["bodyPartSkip"] = "\nPlayer changing bodyparts.\nSkipping %s as %s is in our blocklist.\n%s",
        ["bodyPartMEF"] = "\nPlayer changing bodyparts.\nDetected male player equipping female bodypart.\nBody %s from mod %s\n%s",
        ["bodyPartFEM"] = "\nPlayer changing bodyparts.\nDetected female player equipping male bodypart.\nBody %s from mod %s\n%s",
        ["objectSkip"] = "\nPlayer changing bodyparts.\nNo bodyPart attached to object.\nSkipping %s as %s is in our blocklist.",
        ["objectEquip"] = "\nPlayer changing bodyparts.\nNo bodyPart attached to object.\nObject %s from mod %s."
    }
})