local input = require("openmw.input")
local core = require("openmw.core")

local common = require("scripts.quest_guider_lite.common")
local config = require("scripts.quest_guider_lite.config")

local l10n = core.l10n(common.l10nKey)


local this = {}


this.isGamepad = true


this.keyName = {
    ["LMB"] = l10n("leftMouseButton"),
    ["MMB"] = l10n("middleMouseButton"),
    ["RMB"] = l10n("rightMouseButton"),
    ["MB4"] = l10n("mouseButton4"),
    ["MB5"] = l10n("mouseButton5"),
    ["C_A"] = "A",
    ["C_B"] = "B",
    ["C_X"] = "X",
    ["C_Y"] = "Y",
    ["C_Back"] = "Back",
    ["C_Guide"] = "Guide",
    ["C_Start"] = "Start",
    ["C_LeftStick"] = "Left Stick",
    ["C_RightStick"] = "Right Stick",
    ["C_LeftShoulder"] = "LB",
    ["C_RightShoulder"] = "RB",
    ["C_DPadUp"] = "D-pad Up",
    ["C_DPadDown"] = "D-pad Down",
    ["C_DPadLeft"] = "D-pad Left",
    ["C_DPadRight"] = "D-pad Right",
}


local function splitKeyCombination(comb)
    local keys = {}
    for key in string.gmatch(comb, "[^%s%+]+") do
        table.insert(keys, key)
    end
    return keys
end


---@param combination string?
---@return string?
function this.keyCombinationToString(combination)
    if not combination then return end

    local keys = splitKeyCombination(combination)
    local keyNames = {}
    for _, key in ipairs(keys) do
        local name
        local isKey, keyId = pcall(function ()
            return input.KEY[key]
        end)
        if isKey and keyId then
            name = input.getKeyName(keyId)
        else
            name = this.keyName[key]
        end
        name = name or key

        table.insert(keyNames, name)
    end

    return table.concat(keyNames, " + ")
end


local function isKeyValidToShow(comb)
    if not comb then return false end
    local hasGamepadKey = comb:find("C_") and true or false
    return this.isGamepad == hasGamepadKey
end


function this.getJournalMenuHotkeyInfoStr(allQuestsMode)
    local out = {}
    local keyConfig = config.data.input.keys

    if isKeyValidToShow(keyConfig.nextQuest) and isKeyValidToShow(keyConfig.previousQuest) then
        table.insert(out, l10n("nextPreviousHotkeysStrFormat", {
            next = this.keyCombinationToString(keyConfig.nextQuest),
            previous = this.keyCombinationToString(keyConfig.previousQuest),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("scrollQuestGamepadHotkeys"))
    end

    if isKeyValidToShow(keyConfig.toggleTrackObjects) then
        table.insert(out, l10n("toggleTrackObjectsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTrackObjects),
        }))
    end

    if isKeyValidToShow(keyConfig.toggleTopTopics) then
        table.insert(out, l10n("toggleTopTopicsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTopTopics),
        }))
    end

    if isKeyValidToShow(keyConfig.toggleTracking) then
        table.insert(out, l10n("toggleTrackingHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTracking),
        }))
    end

    if isKeyValidToShow(keyConfig.toggleQuestHidden) then
        table.insert(out, l10n("toggleQuestHiddenHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleQuestHidden),
        }))
    end

    if not allQuestsMode then
        if isKeyValidToShow(keyConfig.toggleQuestPinned) then
            table.insert(out, l10n("toggleQuestPinnedHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleQuestPinned),
            }))
        end
    end

    if allQuestsMode then
        if isKeyValidToShow(keyConfig.toggleStartedHidden) then
            table.insert(out, l10n("toggleStartedHiddenHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleStartedHidden),
            }))
        end
    else
        if isKeyValidToShow(keyConfig.toggleFinishedHidden) then
            table.insert(out, l10n("toggleFinishedHiddenHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleFinishedHidden),
            }))
        end
    end

    if allQuestsMode then
        if isKeyValidToShow(keyConfig.toggleNearby) then
            table.insert(out, l10n("toggleNearbyHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleNearby),
            }))
        end
        if isKeyValidToShow(keyConfig.toggleAllEntries) then
            table.insert(out, l10n("toggleAllEntriesHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.toggleAllEntries),
            }))
        end
    end

    if allQuestsMode then
        if isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            table.insert(out, l10n("journalMenuLocalHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.nearbyMenuLocal),
            }))
        end
    else
        if isKeyValidToShow(keyConfig.nearbyMenuLocal) then
            table.insert(out, l10n("nearbyMenuLocalHotkeyStrFormat", {
                hotkey = this.keyCombinationToString(keyConfig.nearbyMenuLocal),
            }))
        end
    end

    if isKeyValidToShow(keyConfig.topicMenuLocal) then
        table.insert(out, l10n("topicMenuLocalHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.topicMenuLocal),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("closeMenuHotkeyStrFormat", {
            hotkey = "B",
        }))
    end

    if #out <= 2 then return end

    return table.concat(out, l10n("hotkeyInfoSeparator"))
end


function this.getTopicsMenuHotkeyInfoStr()
    local out = {}
    local keyConfig = config.data.input.keys

    if isKeyValidToShow(keyConfig.nextQuest) and isKeyValidToShow(keyConfig.previousQuest) then
        table.insert(out, l10n("nextPreviousTopicHotkeysStrFormat", {
            next = this.keyCombinationToString(keyConfig.nextQuest),
            previous = this.keyCombinationToString(keyConfig.previousQuest),
        }))
    end

    if isKeyValidToShow(keyConfig.toggleTopTopics) then
        table.insert(out, l10n("showMoreTopicsHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleTopTopics),
        }))
    end

    if isKeyValidToShow(keyConfig.toggleAlphabetical) then
        table.insert(out, l10n("toggleAlphabeticalHotkeyStrFormat", {
            hotkey = this.keyCombinationToString(keyConfig.toggleAlphabetical),
        }))
    end

    if this.isGamepad then
        table.insert(out, l10n("closeMenuHotkeyStrFormat", {
            hotkey = "B",
        }))
    end

    if #out <= 1 then return end

    return table.concat(out, l10n("hotkeyInfoSeparator"))
end


return this