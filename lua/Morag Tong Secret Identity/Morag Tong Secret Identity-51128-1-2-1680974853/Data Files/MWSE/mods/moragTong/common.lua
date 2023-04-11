local common = {}

common.dictionary = {}

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("moragTong.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

common.dictionary = loadTranslation()

function common.setExpelled(faction, expelled)
    if (expelled) then
        if not faction.playerExpelled then
            faction.playerExpelled = true
            local sExpelledMessage = tes3.findGMST(tes3.gmst.sExpelledMessage).value
            tes3.messageBox("%s%s", sExpelledMessage, faction.name)
        end
    else
        faction.playerExpelled = false
    end
end

local hideBy = {
    Robe = {
        Cuirass = true,
        Greaves = true,
        ["Left Bracer"] = true,
        ["Right Bracer"] = true,
        Boots = true,
        Shirt = true,
        Pants = true,
        Skirt = true
    },
    Cuirass = {
        Shirt = true,
    },

    Skirt = {
        Pants = true,
        Greaves = true,
    }

}


function common.hasRevealingItems()
    local items = {}
    local hiddenItems = {}
    for _, stack in pairs(tes3.player.object.equipment) do
        --mwse.log(stack.object.slotName)
        if common.config.moragTongItems[stack.object.id] then
            items[stack.object.slotName] = true
        end
        if hideBy[stack.object.slotName] then
            for itemSlot, status in pairs(hideBy[stack.object.slotName]) do
                hiddenItems[itemSlot] = true
            end
        end
    end
    for itemSlot, _ in pairs(items) do
        if not hiddenItems[itemSlot] then
            --mwse.log("has  revealing items")
            return true
        end
    end
    --mwse.log("no revealing items")
    return false
end

return common