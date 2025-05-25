local common = require("mer.darkShard.common")
local logger = common.createLogger("note")
local Quest = require("mer.darkShard.components.Quest")

local noteId = "afq_note_warning"

---@param e cellChangedEventData
event.register("cellChanged", function(e)
    local cultQuest = Quest.quests.afq_cult
    if e.cell.id:startswith("Vivec") then return end
    if common.config.persistent.noteAdded then return end
    if cultQuest:isAfter(cultQuest.stages.addNote) then
        logger:debug("Adding note %s to player inventory", noteId)
        common.config.persistent.noteAdded = true
        tes3.messageBox("Вы находите записку в своих вещах.")
        tes3.addItem{
            reference = tes3.player,
            item = noteId,
            count = 1
        }
    end
end)