-- MWScript OnActivate Analyzer for Quickloot Mod
-- Determines if an onActivate script only matters to living actors
-- Used to avoid interfering with quest-relevant or important activations

local MWScriptAnalyzer = {}

-- Commands that only work on living actors (NPCs/creatures)
local livingActorCommands = {
    startcombat = true,
    stopcombat = true,
    setfight = true,
    setflee = true,
    setalarm = true,
    modhello = true,
    hello = true,
    setdisposition = true,
    moddisposition = true,
    startscript = true,
    stopscript = true,
    addspell = true,
    removespell = true,
    setlevel = true,
    modlevel = true,
    setstat = true,
    modstat = true,
    getstat = true,
    setmagicka = true,
    modmagicka = true,
    getmagicka = true,
    setfatigue = true,
    modfatigue = true,
    getfatigue = true,
    sethealth = true,
    modhealth = true,
    gethealth = true,
    resurrect = true,
    setdelete = true,
    forcegreeting = true,
    goodbye = true,
    setpcfacrep = true,
    modpcfacrep = true,
    getpcfacrep = true,
    setpccrimelevel = true,
    modpccrimelevel = true,
    getpccrimelevel = true,
    aifollow = true,
    aiescort = true,
    aitravel = true,
    aiwander = true,
    aiactivate = true,
    restorepc = true,
    wakeuppc = true
}

-- Commands that only work on non-living objects
local nonLivingCommands = {
    lock = true,
    unlock = true,
    setlocklevel = true,
    getlocklevel = true,
    rotate = true,
    rotatex = true,
    rotatey = true,
    rotatez = true,
    setangle = true,
    getangle = true,
    setpos = true,
    getpos = true,
    move = true,
    moveto = true,
    playsound = true,
    playsound3d = true,
    activate = true,
    drop = true
}

-- Quest-relevant commands that suggest important scripts
local questRelevantCommands = {
    journal = true,
    setglobal = true,
    modglobal = true,
    getglobal = true,
    setjournalindex = true,
    getjournalindex = true,
    messagebox = true,
    choice = true,
    startquest = true,
    stopquest = true,
    completequest = true,
    updatequest = true,
    addtopic = true,
    goodbye = true,
    forcegreeting = true,
    setpcfacrep = true,
    modpcfacrep = true,
    setpccrimelevel = true,
    modpccrimelevel = true
}

-- Universal commands that work on any object type
local universalCommands = {
    messagebox = true,
    journal = true,
    set = true,
    getdisabled = true,
    getdistance = true,
    getitemcount = true,
    additem = true,
    removeitem = true,
    equip = true,
    unequip = true,
    cast = true,
    explodespell = true,
    getspell = true,
    setscale = true,
    getscale = true,
    playgroup = true,
    loopgroup = true,
    skipanimation = true,
    placeatpc = true,
    placeatme = true,
    placeitem = true,
    getbuttonpressed = true,
    menumode = true,
    random = true,
    getlev = true,
    getdeadcount = true,
    getpcrank = true,
    setpcrank = true,
    modpcrank = true,
    getpcsleep = true,
    playbink = true,
    disable = true,
    enable = true,
    showmap = true,
    say = true
}

-- Clean a line by removing comments and whitespace
local function cleanLine(line)
    if not line then return "" end
    
    -- Remove comments (everything after ;)
    local commentPos = string.find(line, ";")
    if commentPos then
        line = string.sub(line, 1, commentPos - 1)
    end
    
    -- Trim whitespace
    line = string.gsub(line, "^%s*(.-)%s*$", "%1")
    return line
end

-- Extract the first command from a line
local function extractCommand(line)
    if not line or line == "" then return nil end
    
    -- Match the first word (command) and convert to lowercase
    local command = string.match(string.lower(line), "^%s*(%w+)")
    return command
end

-- Check if a line is a block marker (begin/end)
local function isBlockMarker(line)
    local blockType, blockName = string.match(string.lower(line), "^%s*(%w+)%s+(%w+)")
    if blockType and blockName then
        return blockType, blockName
    end
    return nil, nil
end

-- Script control keywords and references
local scriptKeywords = {
    ["return"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["endif"] = true,
    ["if"] = true,
    ["while"] = true,
    ["endwhile"] = true,
    ["player"] = true  -- Reference to player object
}

-- Classify a command
local function classifyCommand(command)
    if not command then return "unknown" end
    
    -- Check if it's a script keyword/control structure
    if scriptKeywords[command] then
        return "script_keyword"
    end
    
    -- Command is already lowercase from extractCommand
    if livingActorCommands[command] then
        return "living_only"
    elseif nonLivingCommands[command] then
        return "non_living_only"
    elseif universalCommands[command] then
        return "universal"
    else
        return "unknown"
    end
end

-- Check if a command is quest-relevant
local function isQuestRelevant(command)
    if not command then return false end
    -- Command is already lowercase from extractCommand
    return questRelevantCommands[command] == true
end

-- Check if a line contains OnActivate condition
local function hasOnActivateCondition(line)
    if not line then return false end
    -- Look for OnActivate == 1 or similar patterns
    return string.match(string.lower(line), "onactivate%s*==%s*1") ~= nil
end

-- Main analysis function
function MWScriptAnalyzer.analyzeScript(scriptContent)
    if not scriptContent then
        return {
            hasOnActivate = false,
            safeToQuickloot = true,
            reason = "No script content"
        }
    end
    
    local lines = {}
    for line in string.gmatch(scriptContent, "[^\r\n]+") do
        table.insert(lines, line)
    end
    
    local inOnActivate = false
    local inOnActivateCondition = false
    local onActivateCommands = {}
    local hasLivingOnly = false
    local hasNonLivingOnly = false
    local hasQuestRelevant = false
    local hasUnknown = false
    local foundOnActivate = false
    
    for i, line in ipairs(lines) do
        local cleanedLine = cleanLine(line)
        if cleanedLine ~= "" then
            local blockType, blockName = isBlockMarker(cleanedLine)
            
            -- Check for begin onactivate block
            if blockType == "begin" and blockName == "onactivate" then
                inOnActivate = true
                foundOnActivate = true
            elseif blockType == "end" and inOnActivate then
                inOnActivate = false
            -- Check for OnActivate condition
            elseif hasOnActivateCondition(cleanedLine) then
                inOnActivateCondition = true
                foundOnActivate = true
            elseif inOnActivateCondition and string.match(string.lower(cleanedLine), "endif") then
                inOnActivateCondition = false
            -- Process commands in either context
            elseif inOnActivate or inOnActivateCondition then
                local command = extractCommand(cleanedLine)
                if command and command ~= "if" and command ~= "endif" and command ~= "else" and command ~= "elseif" then
                    local commandType = classifyCommand(command)
                    local isQuest = isQuestRelevant(command)
                    
                    -- Skip script keywords from analysis
                    if commandType ~= "script_keyword" then
                        table.insert(onActivateCommands, {
                            line = i,
                            command = command,
                            type = commandType,
                            questRelevant = isQuest,
                            fullLine = cleanedLine
                        })
                        
                        -- Track what types of commands we have
                        if commandType == "living_only" then
                            hasLivingOnly = true
                        elseif commandType == "non_living_only" then
                            hasNonLivingOnly = true
                        elseif commandType == "unknown" then
                            hasUnknown = true
                        end
                        
                        if isQuest then
                            hasQuestRelevant = true
                        end
                    end
                end
            end
        end
    end
    
    -- Determine if it's safe to quickloot
    local hasOnActivate = foundOnActivate
    local safeToQuickloot = true
    local reason = "No onActivate found"
    
    if hasOnActivate then
        if hasQuestRelevant then
            safeToQuickloot = false
            reason = "Contains quest-relevant commands"
        elseif hasUnknown then
            safeToQuickloot = false
            reason = "Contains unknown commands - might be important"
        elseif hasLivingOnly and not hasNonLivingOnly then
            safeToQuickloot = true
            reason = "Only affects living actors"
        elseif hasNonLivingOnly or (hasLivingOnly and hasNonLivingOnly) then
            safeToQuickloot = false
            reason = "Affects non-living objects - might interfere with activation"
        else
            -- Only universal commands
            safeToQuickloot = false
            reason = "Universal commands present - potential interference"
        end
    end
    
    return {
        hasOnActivate = hasOnActivate,
        safeToQuickloot = safeToQuickloot,
        reason = reason,
        commands = onActivateCommands,
        analysis = {
            hasLivingOnly = hasLivingOnly,
            hasNonLivingOnly = hasNonLivingOnly,
            hasQuestRelevant = hasQuestRelevant,
            hasUnknown = hasUnknown
        }
    }
end

-- Convenience function for quickloot mod integration
function MWScriptAnalyzer.isSafeToQuickloot(scriptContent)
    local result = MWScriptAnalyzer.analyzeScript(scriptContent)
    return result.safeToQuickloot, result.reason
end

-- Usage example for quickloot mod
function MWScriptAnalyzer.checkObject(object)
    if not object then return true, "No object" end
    
    local script = object.script
    if not script then return true, "No script attached" end
    
    -- Get script content (this depends on your MWSE setup)
    local scriptContent = script.text or script.source
    if not scriptContent then return true, "No script content" end
    
    return MWScriptAnalyzer.isSafeToQuickloot(scriptContent)
end

-- Test function
function MWScriptAnalyzer.test()
    print("=== MWScript OnActivate Analyzer Test ===")
    
    -- Test script 1: Living actor only (safe to quickloot)
    local script1 = [[
begin ExampleNPCScript

begin onActivate
    ; This script only affects living actors
    startcombat player
    setfight 100
    addspell "fire damage"
    messagebox "The NPC attacks!"
end

end
]]
    
    -- Test script 2: Quest relevant (NOT safe to quickloot)
    local script2 = [[
begin ExampleQuestScript

begin onActivate
    ; This script affects quests
    journal "TestQuest" 10
    setglobal questvar 1
    messagebox "Quest updated!"
end

end
]]
    
    -- Test script 3: Container with lock (NOT safe to quickloot)
    local script3 = [[
begin ExampleContainerScript

begin onActivate
    ; This script affects containers
    lock 50
    messagebox "Container is now locked"
    additem "gold_001" 100
end

end
]]
    
    -- Test script 4: OnActivate condition (like your example)
    local script4 = [[
Begin WarlordOren
short nolore
if ( GetJournalIndex "MS_Warlords" > 0 )
	if ( GetJournalIndex "MS_Warlords_a" < 35 )
		if ( OnDeath == 1 )
			Journal MS_Warlords 210
		endif
	endif
endif
if ( GetJournalIndex "MS_Warlords_a" == 35 )
	if ( OnActivate == 1 )
		Journal MS_Warlords_a 40
		Activate
	endif
endif
End WarlordOren
]]
    
    local scripts = {script1, script2, script3, script4}
    local names = {"Living Actor Script", "Quest Script", "Container Script", "Warlord Oren Script"}
    
    for i, script in ipairs(scripts) do
        print("\n--- " .. names[i] .. " ---")
        local safe, reason = MWScriptAnalyzer.isSafeToQuickloot(script)
        print("Safe to quickloot: " .. tostring(safe))
        print("Reason: " .. reason)
        
        local result = MWScriptAnalyzer.analyzeScript(script)
        print("Commands found:")
        for _, cmd in ipairs(result.commands) do
            print("  " .. cmd.command .. " (" .. cmd.type .. ")" .. 
                  (cmd.questRelevant and " [QUEST]" or ""))
        end
    end
end

return MWScriptAnalyzer