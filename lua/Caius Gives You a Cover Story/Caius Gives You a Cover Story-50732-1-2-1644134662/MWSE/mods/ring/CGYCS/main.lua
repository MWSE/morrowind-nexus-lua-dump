local interop = require("ring.cgycs.interop")
local logger = require("logging.logger")

--- @param e infoGetTextEventData
local function showSkillThing(e)
  -- For each faction loaded in game, create a new entry in numberOfSkills.
  -- Then, check each faction skill against player's major skills.
  -- Store number of matching skills
  local highSkills = 0
  local highIndex
  local minSkills = 2
  local numberOfSkills = {}
  local bestApproachableFaction = ""
  local bestUnapproachableFaction = ""
  local bestApproachableFactionCount = 0
  local bestUnapproachableFactionCount = 0

  logger:info("[CGYCS] Comparing faction skills to player skills")
  for _, faction in ipairs(tes3.dataHandler.nonDynamicData.factions) do
    logger:debug("  Comparing faction: " .. faction.name)
    numberOfSkills[faction.id] = 0
    for _, skill in ipairs(faction.skills) do
      if (table.find(tes3.player.object.class.majorSkills, skill)) then
        numberOfSkills[faction.id] = numberOfSkills[faction.id] + 1
        logger:trace("    " .. skill .. " matches!")
      else
        logger:trace("    " .. skill .. " does not match!")
      end
    end
    logger:debug("    Total matching skills for " .. faction.name .. ": " .. numberOfSkills[faction.id])
  end

  -- Find faction with most matching skills
  for factionID, skills in pairs(numberOfSkills) do
    if (skills > highSkills and skills > minSkills) then 
        highSkills = skills
    end
  end

  for factionID, skills in pairs(numberOfSkills) do
    local factionName = tes3.getFaction(factionID).name
     if (
       skills == highSkills
       and interop.joinable[factionName]
       and interop.approachable[factionName]
       and (not interop.racist[factionName] or tes3.player.object.race.name == "Dunmer")
      ) then 
        bestApproachableFaction = bestApproachableFaction .. "the " .. factionName .. ", "
		bestApproachableFactionCount = bestApproachableFactionCount + 1
     end
 
     if (
       skills == highSkills
       and interop.joinable[factionName]
       and not interop.approachable[factionName]
       and (not interop.racist[factionName] or tes3.player.object.race.name == "Dunmer")
      ) then 
        bestUnapproachableFaction = bestUnapproachableFaction .. "the " .. factionName .. ", "
		bestUnapproachableFactionCount = bestUnapproachableFactionCount + 1
     end
  end
    logger:debug("  Best approachable faction skill matches for this character: " .. bestApproachableFaction)
    logger:debug("  Best unapproachable faction skill matches for this character: " .. bestUnapproachableFaction)
	
  if (bestApproachableFactionCount > 1 and bestUnapproachableFactionCount > 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be one of these factions: " .. bestApproachableFaction .. 
	  "or, if you feel like you can handle the risk, information from one of these factions would be useful: " .. bestUnapproachableFaction .. 
	  "but be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."
  elseif (bestApproachableFactionCount == 1 and bestUnapproachableFactionCount == 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be " .. bestApproachableFaction .. 
	  "or, if you feel like you can handle the risk, information from " .. bestUnapproachableFaction .. 
	  "would be useful. But be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."
  elseif (bestApproachableFactionCount > 1 and bestUnapproachableFactionCount == 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be one of these factions: " .. bestApproachableFaction .. 
	  "or, if you feel like you can handle the risk, information from " .. bestUnapproachableFaction .. 
	  "would be useful. But be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."
  elseif (bestApproachableFactionCount == 1 and bestUnapproachableFactionCount > 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be " .. bestApproachableFaction .. 
	  "or, if you feel like you can handle the risk, information from one of these factions would be useful: " .. bestUnapproachableFaction .. 
	  "but be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."
  elseif (bestApproachableFactionCount > 1 and bestUnapproachableFactionCount == 0) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be one of these factions: " .. bestApproachableFaction .. 
	  "or you could try freelance adventuring. But be warned, travelling in Vvardenfell is no stroll in the garden."  
  elseif (bestApproachableFactionCount == 0 and bestUnapproachableFactionCount > 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, if you feel like you can handle the risk, information from one of these factions would be useful: " .. bestUnapproachableFaction .. 
	  "but be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."
  elseif (bestApproachableFactionCount == 1 and bestUnapproachableFactionCount == 0) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, a safe bet for you would be " .. bestApproachableFaction .. 
	  "or you could try freelance adventuring. But be warned, travelling in Vvardenfell is no stroll in the garden."  
  elseif (bestApproachableFactionCount == 0 and bestUnapproachableFactionCount == 1) then
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, if you feel like you can handle the risk, information from " .. bestUnapproachableFaction .. 
	  "would be useful. But be warned: should you be found out the Imperial City's Prison will seem like a fond memory compared to what they will do."  
  else
	  e.text = e:loadOriginalText() .. "\n\nBased on your skills, I cannot really recommend any faction. You could try freelance adventuring. But be warned, travelling in Vvardenfell is no stroll in the garden."  
  end
  
  
end

local function getInfo(topic, id)
    local dialogue = tes3.findDialogue({ topic = topic })
    if (dialogue) then
        for _, info in ipairs(dialogue.info) do
            if (info.id == id) then
                return info
            end
        end
    end
end

local function onInitialized()
    local desiredInfo = getInfo("Orders", "2090431221919117613")
    assert(desiredInfo, "Can't find Caius' dialogue entry to extend.")
    if (desiredInfo) then
        event.register(tes3.event.infoGetText, showSkillThing, { filter = desiredInfo })
    end
	mwse.log("[CGYCS]Caius Gives You a Cover Story initialized")
end
event.register(tes3.event.initialized, onInitialized)