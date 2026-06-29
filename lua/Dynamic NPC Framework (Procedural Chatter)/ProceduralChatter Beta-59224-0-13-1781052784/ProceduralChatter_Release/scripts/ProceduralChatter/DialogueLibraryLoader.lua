-- DialogueLibraryLoader.lua
-- Runtime loader for dialogue JSON libraries under data/Dialogue/.
-- Assembles Greetings, Goodbyes, SmallTalk, GenericRumors, Generics, UniqueSnippets,
-- UniqueConversations, GenericBlacklist, and Flows from multiple JSON files.

local JsonMergeLoader = require("scripts.ProceduralChatter.JsonMergeLoader")

local DialogueLibraryLoader = {}

local LIBRARIES_PREFIX = "scripts/proceduralchatter/data/dialogue/libraries/"
local FLOWS_PREFIX     = "scripts/proceduralchatter/data/dialogue/conversationflows/"
local ANIMATION_TEMPLATES_PREFIX = "scripts/proceduralchatter/data/dialogue/animationtemplates/"

local loaded = false
local Library = {
    Greetings = {},
    Goodbyes = {},
    SmallTalk = { Snippets = {} },
    GenericRumors = { Snippets = {} },
    Generics = {},
    GenericBlacklist = {},
    UniqueSnippets = {},
    UniqueConversations = {},
    Flows = {},
    AnimationTemplates = {},
}

local function mergeFile(data, path)
    for key, value in pairs(data) do
        if key == "Greetings" and type(value) == "table" then
            JsonMergeLoader.mapMerge(Library.Greetings, value)

        elseif key == "Goodbyes" and type(value) == "table" then
            JsonMergeLoader.mapMerge(Library.Goodbyes, value)

        elseif key == "SmallTalk" and type(value) == "table" then
            if value.Snippets then
                JsonMergeLoader.mapMerge(Library.SmallTalk.Snippets, value.Snippets)
            end

        elseif key == "GenericRumors" and type(value) == "table" then
            if value.Snippets then
                JsonMergeLoader.mapMerge(Library.GenericRumors.Snippets, value.Snippets)
            end

        elseif key == "Generics" and type(value) == "table" then
            for pool, lines in pairs(value) do
                if type(lines) == "table" then
                    if not Library.Generics[pool] then
                        Library.Generics[pool] = {}
                    end
                    JsonMergeLoader.arrayConcat(Library.Generics[pool], lines)
                end
            end

        elseif key == "UniqueSnippets" and type(value) == "table" then
            JsonMergeLoader.mapMerge(Library.UniqueSnippets, value)

        elseif key == "UniqueConversations" and type(value) == "table" then
            JsonMergeLoader.deepMerge(Library.UniqueConversations, value)

        elseif key == "GenericBlacklist" and type(value) == "table" then
            JsonMergeLoader.arrayConcat(Library.GenericBlacklist, value)

        elseif key == "Flows" and type(value) == "table" then
            JsonMergeLoader.mapMerge(Library.Flows, value)

        elseif key == "AnimationTemplates" and type(value) == "table" then
            JsonMergeLoader.mapMerge(Library.AnimationTemplates, value)

        else
            print(string.format("[DialogueLibraryLoader] INFO: unknown bucket '%s' in %s", key, path))
        end
    end
end

function DialogueLibraryLoader.ensureLoaded()
    if loaded then return end
    loaded = true

    local count = JsonMergeLoader.scan(LIBRARIES_PREFIX, mergeFile)
    count = count + JsonMergeLoader.scan(FLOWS_PREFIX, mergeFile)
    count = count + JsonMergeLoader.scan(ANIMATION_TEMPLATES_PREFIX, mergeFile)

    print(string.format("[DialogueLibraryLoader] Scan complete: %d json file(s) loaded", count))
end

function DialogueLibraryLoader.getLibrary()
    DialogueLibraryLoader.ensureLoaded()
    return Library
end

return DialogueLibraryLoader
