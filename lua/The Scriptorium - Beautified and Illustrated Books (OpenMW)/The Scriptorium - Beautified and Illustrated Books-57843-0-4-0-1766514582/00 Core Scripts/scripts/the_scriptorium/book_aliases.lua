-- Book ID Aliases
-- This file maps book IDs to their canonical file names
-- When multiple books share the same content, you can maintain a single file
-- and create aliases for the other book IDs

-- Format: ["book_id"] = "canonical_file_name" (without .html extension)
-- Both the book_id and canonical_file_name should be in lowercase

local aliases = {
    -- Books
    bk_briefhistoryempire1_oh = "bk_briefhistoryempire1",
    bk_briefhistoryempire2_oh = "bk_briefhistoryempire2",
    bk_briefhistoryempire3_oh = "bk_briefhistoryempire3",
    bk_briefhistoryempire4_oh = "bk_briefhistoryempire4",
    bk_houseoftroubles_o = "bk_houseoftroubles_c",
}

return aliases
