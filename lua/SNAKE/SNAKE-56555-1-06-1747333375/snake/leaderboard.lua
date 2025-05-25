local leaderboard = {}

function leaderboard.initialize()
    if not jsonInterface.load(SnakeGame.cfg.leaderboardFile) then
        jsonInterface.save(SnakeGame.cfg.leaderboardFile, { scores = {} })
    end
end

function leaderboard.getScores()
    local leaderboardData = jsonInterface.load(SnakeGame.cfg.leaderboardFile)
    if not leaderboardData then
        leaderboardData = { scores = {} }
        jsonInterface.save(SnakeGame.cfg.leaderboardFile, leaderboardData)
    end
    return leaderboardData.scores
end

function leaderboard.getLeaderboardPosition(playerName, score)
    local scores = leaderboard.getScores()

    for i, entry in ipairs(scores) do
        if entry.name == playerName and entry.score == score then
            return i
        end
    end

    return nil -- Not found in leaderboard
end

function leaderboard.addScore(playerName, score)
    local leaderboardData = jsonInterface.load(SnakeGame.cfg.leaderboardFile) or { scores = {} }

    -- Add new score
    table.insert(leaderboardData.scores, {
        name = playerName,
        score = score,
        date = os.date("%Y-%m-%d %H:%M:%S")
    })

    -- Sort scores (highest first)
    table.sort(leaderboardData.scores, function(a, b)
        return a.score > b.score
    end)

    -- Trim to max entries
    while #leaderboardData.scores > SnakeGame.cfg.maxLeaderboardEntries do
        table.remove(leaderboardData.scores)
    end

    -- Save updated leaderboard
    jsonInterface.save(SnakeGame.cfg.leaderboardFile, leaderboardData)

    return leaderboard.getLeaderboardPosition(playerName, score)
end

-- function leaderboard.showLeaderboard(pid)
--     local scores = leaderboard.getScores()

--     if #scores == 0 then
--         tes3mp.CustomMessageBox(pid, -1, "No scores recorded yet!", "Close")
--         return
--     end

--     local message = color.Orange .. "LEADERBOARD\n" .. color.White .. "──────────────────────────────\n\n"
--     local fixedNameWidth = 25  -- Total width allotted for names (adjust as needed)

--     for i, entry in ipairs(scores) do
--         -- Format rank as two digits
--         local rankDisplay = string.format("%02d", i)

--         -- Format score as three digits
--         local scoreDisplay = string.format("%03d", entry.score)

--         -- Truncate name if it's too long
--         local displayName = entry.name
--         if string.len(displayName) > fixedNameWidth then
--             displayName = string.sub(displayName, 1, fixedNameWidth)
--         end

--         -- Pad name with spaces to reach the fixed width
--         displayName = displayName .. string.rep("A", fixedNameWidth - string.len(displayName))

--         -- Rank coloring
--         local rowColor = color.White
--         if i == 1 then
--             rowColor = color.Gold
--         elseif i == 2 then
--             rowColor = color.Silver
--         elseif i == 3 then
--             rowColor = SnakeGame.cfg.bronze
--         end

--         message = message .. rowColor ..
--             rankDisplay .. "    " ..
--             scoreDisplay .. "    " ..
--             displayName .. "\n" ..
--             color.Default
--     end

--     message = message .. "\n" .. color.White .. "──────────────────────────────"
--     tes3mp.CustomMessageBox(pid, SnakeGame.cfg.leaderboardId_2, message, "Close")
-- end

function leaderboard.updateAndDisplayLeaderboardBook(pid)
    local scores = leaderboard.getScores()

    -- Ensure scores are sorted by score (highest first)
    table.sort(scores, function(a, b)
        return a.score > b.score
    end)

    -- Create book content with arcade-style formatting
    local bookContent = "<DIV ALIGN=\"CENTER\"><FONT SIZE=\"4\" FACE=\"Daedric\"><BR>\n"
    bookContent = bookContent .. "LEADERBOARD<BR>\n"
    bookContent = bookContent .. "<FONT SIZE=\"2\" FACE=\"Magic Cards\">───────────────────<BR><BR>\n"

    -- Column headers (no color)
    bookContent = bookContent .. "<DIV ALIGN=\"LEFT\"><FONT SIZE=\"3\" FACE=\"Magic Cards\">"
    bookContent = bookContent .. "RANK    SCORE            NAME<BR>\n"
    bookContent = bookContent .. "───────────────────────────────────<BR>\n"
    bookContent = bookContent .. "</FONT></DIV>\n"

    bookContent = bookContent .. "<FONT SIZE=\"3\" FACE=\"Magic Cards\">\n"

    if #scores == 0 then
        bookContent = bookContent .. "<DIV ALIGN=\"CENTER\">NO SCORES RECORDED YET!</DIV><BR><BR>\n"
    else
        -- Create an arcade-style scoreboard
        for i, entry in ipairs(scores) do
            if i > 25 then break end -- Show only top 10 scores

            -- Format rank
            local rankStr
            if i < 10 then
                rankStr = "0" .. i
            else
                rankStr = i
            end

            -- Pad rank to fixed width
            rankStr = " " .. rankStr .. string.rep(" ", 13 - string.len(rankStr))

            -- Format score with leading zeros
            local scoreStr = string.format("%03d", entry.score)
            -- Pad score to fixed width
            scoreStr = scoreStr .. string.rep(" ", 14 - string.len(scoreStr))

            -- Format player name (truncate if too long)
            local nameStr = entry.name

            -- Display the main entry
            bookContent = bookContent .. rankStr .. scoreStr .. nameStr .. "</DIV>\n"

            -- Add divider between entries if not the last entry
            if i < math.min(25, #scores) then
                bookContent = bookContent ..
                    "<FONT COLOR=\"666666\"SIZE=\"1\">- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -</FONT><BR>\n"
            end
        end
    end

    bookContent = bookContent .. "<BR>\n"
    bookContent = bookContent .. "<DIV ALIGN=\"CENTER\"><FONT SIZE=\"2\">───────────────────<BR>\n"
    bookContent = bookContent .. "<FONT SIZE=\"2\">\n"
    bookContent = bookContent .. "<IMG SRC=\"MoragTong.tga\" WIDTH=\"96\" HEIGHT=\"96\"><BR>\n"
    bookContent = bookContent .. "<DIV ALIGN=\"CENTER\"><FONT FACE=\"Daedric\"> I don't like fetcher.<P>\n"
    bookContent = bookContent .. "<DIV ALIGN=\"CENTER\"><FONT FACE=\"Magic Cards\"> Made by skoomabreath for TES3MP version " .. tostring(tes3mp.GetServerVersion()) .. "<BR>\n"

    -- update book record
    local recordStore = RecordStores["book"]
    local bookId = "sg_leaderboard_book"

    recordStore.data.permanentRecords[bookId] = {
        name = "Leaderboard",
        text = bookContent,
        icon = "m\\tx_scroll_03.dds",
        scrollState = true,
        enchantmentId = "",
        enchantmentCharge = 0,
        skillId = -1,
        weight = 0,
        value = 0,
        soul = "",
        count = 1,
        charge = -1
    }

    -- Save the record store and inform connected players
    recordStore:QuicksaveToDrive()

    -- Load the record for this specific player
    tes3mp.ClearRecords()
    tes3mp.SetRecordType(enumerations.recordType.BOOK)
    packetBuilder.AddBookRecord(bookId, recordStore.data.permanentRecords[bookId])
    tes3mp.SendRecordDynamic(pid, false, false)

    -- Directly activate the book for the player
    logicHandler.ActivateObjectForPlayer(pid, SnakeGame.cfg.roomCell, SnakeGame.preCreatedObjects.leaderboard.uniqueIndex)

    return true
end

return leaderboard
