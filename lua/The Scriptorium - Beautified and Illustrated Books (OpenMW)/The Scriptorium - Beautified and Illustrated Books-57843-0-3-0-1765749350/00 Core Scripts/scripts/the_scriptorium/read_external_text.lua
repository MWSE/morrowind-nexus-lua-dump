-- Imports
local vfs = require('openmw.vfs')
local aliases = require('scripts.the_scriptorium.book_aliases')

-- Local constants
local BOOK_FOLDER = "booktexts/"
local FILE_EXTENSION = ".html"

-- Read external text for a given book ID
-- @param bookId: The book identifier (case-insensitive)
-- @return: The content of the external HTML file, or nil if not found
local function readExternalText(bookId)
    if not bookId then
        return nil
    end

    -- Normalize book ID to lowercase for case-insensitive matching
    local normalizedId = bookId:lower()
    
    -- Check if this book ID has an alias pointing to a canonical file
    if aliases[normalizedId] then
        normalizedId = aliases[normalizedId]
        -- print(string.format("[beautiful-illustrated-books] Using alias: %s -> %s", bookId:lower(), normalizedId))
    end
    local filePath = BOOK_FOLDER .. normalizedId .. FILE_EXTENSION
    
    -- Try to open the file
    local file = vfs.open(filePath)
    
    if not file then
        -- print(string.format("[beautiful-illustrated-books] No external content found for: %s", normalizedId))
        return nil
    end

    -- Read entire file content
    local content = file:read("*all")
    file:close()

    if content and content ~= "" then
        -- print(string.format("[beautiful-illustrated-books] Loaded external content for: %s (%d bytes)", normalizedId, #content))
        return content
    else
        -- print(string.format("[beautiful-illustrated-books] External file empty or unreadable: %s", filePath))
        return nil
    end
end

return readExternalText
