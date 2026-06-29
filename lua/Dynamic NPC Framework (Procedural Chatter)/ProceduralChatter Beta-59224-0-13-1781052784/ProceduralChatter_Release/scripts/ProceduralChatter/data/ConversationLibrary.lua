local ConversationLibrary = {}

-- Generics base stays Lua (not exported to JSON)
ConversationLibrary.Generics = require("scripts.ProceduralChatter.data.generic_library")

-- JSON-loaded dialogue libraries
local DialogueLibraryLoader = require("scripts.ProceduralChatter.DialogueLibraryLoader")
local JSONLib = DialogueLibraryLoader.getLibrary()

ConversationLibrary.Greetings = JSONLib.Greetings
ConversationLibrary.SmallTalk = JSONLib.SmallTalk
ConversationLibrary.GenericRumors = JSONLib.GenericRumors
ConversationLibrary.Goodbyes = JSONLib.Goodbyes
ConversationLibrary.GenericBlacklist = JSONLib.GenericBlacklist
ConversationLibrary.UniqueSnippets = JSONLib.UniqueSnippets
ConversationLibrary.UniqueConversations = JSONLib.UniqueConversations
ConversationLibrary.Flows = JSONLib.Flows
ConversationLibrary.AnimationTemplates = JSONLib.AnimationTemplates

-- Merge JSON generics onto the Lua base (concatenate pool arrays)
for pool, lines in pairs(JSONLib.Generics) do
    if type(lines) == "table" then
        if not ConversationLibrary.Generics[pool] then
            ConversationLibrary.Generics[pool] = {}
        end
        for _, line in ipairs(lines) do
            table.insert(ConversationLibrary.Generics[pool], line)
        end
    end
end

return ConversationLibrary
