--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- MWSE Journal Search and Edit by Svengineer99
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
  _______ _                 _                          _  
 |__   __| |               | |                        | | 
    | |  | |__   __ _ _ __ | | _____    __ _ _ __   __| | 
    | |  | '_ \ / _` | '_ \| |/ / __|  / _` | '_ \ / _` | 
    | |  | | | | (_| | | | |   <\__ \ | (_| | | | | (_| | 
    |_|  |_| |_|\__,_|_| |_|_|\_\___/  \__,_|_| |_|\__,_|
   _____              _ _ _     _            
  / ____|            | (_) |   | |         _ 
 | |     _ __ ___  __| |_| |_  | |_ ___   (_)
 | |    | '__/ _ \/ _` | | __| | __/ _ \     
 | |____| | |  __/ (_| | | |_  | || (_) |  _ 
  \_____|_|  \___|\__,_|_|\__|  \__\___/  (_)
  
  Hrnchamd for UI Inspector, Text input example, research, MWSE dev support, ..
  NullCascade and team for MWSE lua scripting development and docs
  NullCascode, Greatness7, Petethegoat, Merlord, Mort, Remiros, Abot, ... for
     Released and unreleased lua scripting references
     Morrowind Modding Discord MWSE chat discussion, help, inspiration.
     	       Link to join: https://discord.gg/kVRSwkE
  Merlord for Easy MCM
  Danae for playtesting feedback
  
]]--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--[[
 __          __              _                               _ 
 \ \        / /             (_)                             | |
  \ \  /\  / /_ _ _ __ _ __  _ _ __   __ _    __ _ _ __   __| |
   \ \/  \/ / _` | '__| '_ \| | '_ \ / _` |  / _` | '_ \ / _` |
    \  /\  / (_| | |  | | | | | | | | (_| | | (_| | | | | (_| |
     \/  \/ \__,_|_|  |_| |_|_|_| |_|\__, |  \__,_|_| |_|\__,_|
                                      __/ |                    
  _____  _          _       _        |___/                     
 |  __ \(_)        | |     (_)                      _ 
 | |  | |_ ___  ___| | __ _ _ _ __ ___   ___ _ __  (_)
 | |  | | / __|/ __| |/ _` | | '_ ` _ \ / _ \ '__|     
 | |__| | \__ \ (__| | (_| | | | | | | |  __/ |     _ 
 |_____/|_|___/\___|_|\__,_|_|_| |_| |_|\___|_|    (_)
                                                                 
  Not well optimized, organized, commented; sometimes hacky scripting below.

  No reflection of MWSE devs and other scripters superior example and practice.

  Not recommended as a reference unless no other can be found.

]]--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local config = require("sve.journal.config")[1]
local journalEdits = nil -- saved edits [Date/Topic Header Text][page][count]
local bookArtImages = {} -- contentPaths already found in game or BookArt/Journal folder

-- main function
local function onMenuJournalActivated()
   if config.enabled == false then return end

   -- shared variables
   local inputString = "" -- current journal search or edit string 
   local searchIndex = 0 -- # search index for visible pages text
   local direction = false -- direction of search
   local activeHyperText = { "", "", "" } -- orig, marked/modified, marked-blink(not used)
   local activeHyperTextElement = nil -- modified search or edit hypertext element
   local journalEditIndex = 0 -- edit mode Header index 0:search mode
   local imageIndex = 0 -- inserted page image index
   local journalEditableElements = {} -- editable text elements visible on current pages { headerText, element, key}
   local journalHeaderColor = nil -- 0.624,0,0 didn't match any getPalette color, so extract on the fly
   local pageTurnTimer = nil -- master timer for page turn delays
   local headerText = "" -- last date or topic header
   local currentPage = 0 -- last odd page
   local splitPage = 0 -- 0=not split, 1=split left, 2=split right
   local mouseClickPrevNext = false -- true if page turned
   local insertedPage = "insertedPage" -- or "insertedPage%s" hyperlink/quest/topic, for non-main-quest inserted topics
   local mainJournalSplitPage = 1 -- flipping from the main journal to topics and back
   local splitLastPage = ""
   local journalBindKey = tes3.worldController.inputController.inputMaps[20].code -- "J" key by default thanks to Petethegoat
  -- helper functions


   local function restoreHyperLinks(text)
      for hyperText, _ in pairs(journalEdits.hyperText) do
         if string.find(string.lower(text), "@*" .. hyperText .. "#*") ~= nil then
            local hHyperText = "[" .. string.sub(hyperText,1,1) .. string.upper(string.sub(hyperText,1,1)) .. "]" .. string.sub(hyperText,2)
	    local subHyperText = hHyperText
	    local i = 0
	    while subHyperText ~= nil and subHyperText ~= "" do
	       local j,k = string.find(subHyperText, " ")
	       if j ~= nil and j < string.len(subHyperText) and j == k then
	          i = i + j 
	          hHyperText = string.sub(hHyperText,1,i) .. "[" .. string.sub(subHyperText,j+1,j+1) ..
		  	       string.upper(string.sub(subHyperText,j+1,j+1)) .. "]" .. string.sub(subHyperText,j+2)
		  subHyperText = string.sub(subHyperText,j+1)
--mwse.log("intermediate hHyperText:%s, subHyperText:%s", hHyperText, subHyperText)		  
	       else
	          subHyperText = nil
	       end
	    end
--mwse.log("HhyperText:%s found!", hHyperText)
	    text = text:gsub("@*" .. hHyperText .. "#*", "@%0#") -- any hypertext with preced/following non-alphabet or s
	    text = text:gsub("@+", "@") -- clean up
	    text = text:gsub("#+", "#") -- clean up
	 end
      end
      return text
   end
      
    local function isKeyComboPressed(keyInfo)
       local inputController = tes3.worldController.inputController
       if inputController:isKeyDown(keyInfo.keyCode) == true
       and ( ( inputController:isKeyDown(tes3.scanCode.lAlt)
            or inputController:isKeyDown(tes3.scanCode.rAlt) ) == keyInfo.isAltDown )
       and ( ( inputController:isKeyDown(tes3.scanCode.lShift)
            or inputController:isKeyDown(tes3.scanCode.rShift) ) == keyInfo.isShiftDown )
       and ( ( inputController:isKeyDown(tes3.scanCode.lCtrl)
            or inputController:isKeyDown(tes3.scanCode.rCtrl) ) == keyInfo.isControlDown ) then
          return true
       end
       return false
    end
    
   local function showActiveHyperTextElementDividers()
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return end
      if activeHyperTextElement == nil then return end
      local parent = activeHyperTextElement.parent
      if parent == nil then return end
      local divider = parent:findChild(tes3ui.registerID("JournalSearch_edit_divider1"))
      if divider == nil then
         if menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")) ~= nil then
	    menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")):destroy()
	    menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2")):destroy()
	 end
	 parent:createDivider({ id = tes3ui.registerID("JournalSearch_edit_divider1") })
	 parent:createDivider({ id = tes3ui.registerID("JournalSearch_edit_divider2") })
      end
      divider = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1"))
      divider.visible = true
      parent:reorderChildren(activeHyperTextElement,divider,1)
      divider = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2"))
      divider.visible = true
      parent:reorderChildren(activeHyperTextElement,divider,1)
      parent:reorderChildren(divider, activeHyperTextElement,1)
   end

   local function flashSearchIndicators()
--mwse.log("flashSearchIndicators()")
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return end
      if activeHyperTextElement == nil then return end
      local divider1 = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1"))
      if divider1 == nil then return end
      divider1.visible = false
      local divider2 = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2"))
      if divider2 == nil then return end
      divider2.visible = false
      timer.start({duration=config.searchIndicatorDuration/1000, type = timer.real, callback = function()
         if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
      	 divider1 = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1"))
	 if divider1 == nil then return end
	 divider1.visible = true
      	 divider2.visible = true
      end})
    end
    
    local function updateNotifyElement(state)
--mwse.log("updateNotifyElement")
       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu == nil then return false end
       local element = menu:findChild(tes3ui.registerID("JournalSearch_notify_label"))
       local divider = menu:findChild(tes3ui.registerID("JournalSearch_notify_divider"))
       if state == nil and element ~= nil and divider ~= nil then
	  element.visible = false
	  divider.visible = false
	  if menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")) ~= nil then
             menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")).visible = false
             menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2")).visible = false
	  end
	  return
       end
       
       if element == nil then
       	  local parent = activeHyperTextElement and activeHyperTextElement.parent or menu:findChild(tes3ui.registerID("MenuBook_page_1"))
       	  if parent == nil then return end
	  element = parent:createLabel({ id = tes3ui.registerID("JournalSearch_notify_label") })
	  divider = parent:createDivider({ id = tes3ui.registerID("JournalSearch_notify_divider") })
	  parent:reorderChildren(0,element,1)
	  parent:reorderChildren(1,divider,1)
       end

       if inputString == "" then
       	  element.visible = false
	  divider.visible = false
       else
          local foo = state and "->" or "-X"
	  local input = menu:findChild(tes3ui.registerID("PartParagraphInput_text_input"))
	  if input == nil then return end
	  local searchStringWithCursor = input.text
	  if searchStringWithCursor == nil then return end
	  while string.len(searchStringWithCursor) > string.len(inputString) + 1 do
	     searchStringWithCursor = searchStringWithCursor:gsub(".|","|")
--mwse.log("searchStringWithCursor \"%s\" -> \"%s\"", input.text, searchStringWithCursor)
	  end
          element.text = searchStringWithCursor .. foo
          element.visible = true
          element.color = tes3ui.getPalette("journal_topic_color")
          divider.visible = true
          divider.color = tes3ui.getPalette("journal_topic_color")
       	  showActiveHyperTextElementDividers()
       end
       menu:updateLayout()
    end

    local nullSpacerHeight = 0
    local function updateContentOpenPages()
--mwse.log("updateContentOpenPages, splitPage:" .. splitPage)
       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu == nil then return false end
       local page_number_element = menu:findChild(tes3ui.registerID("MenuBook_page_number_1"))
       if page_number_element == nil then return end
       local page_number = page_number_element.text
       if string.find(page_number, "%-$") then
       	  page_number = tostring(tonumber(string.sub(page_number,1,-2)) - 1)
	  page_number_element.text = page_number
       end
       -- check if page 2 is empty and if so create dummy element
       local element = menu:findChild(tes3ui.registerID("MenuBook_page_2"))
       if element == nil then return end
       if element.children == nil or #element.children == 0 then
          local child = element:createBlock{ id = tes3ui.registerID("sveJournalBlankEndBlock") }
	  child.visible = false
       end
       -- determine if this is a hyperlink page
       local function isHeaderElement(child)
	  return child.text ~= nil 
	  and ( ( math.abs(child.color[1] - ( journalHeaderColor and journalHeaderColor[1] or 0.624 ) ) < 0.001 
	      and math.abs(child.color[2] - ( journalHeaderColor and journalHeaderColor[2] or 0.000 ) ) < 0.001
	      and math.abs(child.color[3] - ( journalHeaderColor and journalHeaderColor[3] or 0.000 ) ) < 0.001 ) )
       end
       element = menu:findChild(tes3ui.registerID("MenuBook_page_1"))
       if element == nil then return end
       local priorInsertedPage = insertedPage
       for k = 1, #element.children do
--mwse.log("element.children[%d].text = %s", k, tostring(element.children[k].text))
	  local child = element.children[k]
	  -- couldn't find getPalette match for headerText color 0.624, 0.000, 0.000
	  if journalHeaderColor == nil and child.text ~= nil and string.find(child.text, "%)$") ~= nil then
	     journalHeaderColor = { child.color[1], child.color[2], child.color[3] }
	  end
          if isHeaderElement(child) == true then
--mwse.log("  isHeaderElement == true, journalEdits.hyperText[%s] = %s", child.text, tostring(journalEdits.hyperText[string.lower(child.text)]))
-- <=v1.11 only captured non-main journal hypertext pages
--   	     if journalEdits.hyperText[string.lower(child.text)] ~= nil then
-- >=v1.20 should capture all non-main journal pages, presuming the header does not end in ")"
	     if string.find(child.text, "%)$") == nil then
		insertedPage = "insertedPage" .. string.lower(child.text)
--mwse.log("non-main journal header identified: " .. string.lower(child.text) .. ", insertedPage: " ..  insertedPage)
   	     else
		insertedPage = "insertedPage"
	     end
	     if insertedPage ~= priorInsertedPage then
--mwse.log("insertedPage ~= priorInsertedPage")
	        if priorInsertedPage == "insertedPage" then
--mwse.log("save mainJournalSplitPage = " .. splitPage)
		   mainJournalSplitPage = splitPage
		end
	        if journalEdits[insertedPage] == nil or journalEdits[insertedPage][page_number] == nil then
--mwse.log("%s ~= %s -> splitPage = 0", insertedPage, priorInsertedPage)		
		   splitPage = 0
		else
		   if insertedPage == "insertedPage" then
		      splitPage = mainJournalSplitPage
--mwse.log("restore mainJournalSplitPage = " .. splitPage)
		  else
		      splitPage = 1
--mwse.log("starg splitPage:" .. splitPage)
		   end
		end
	     end
	     break
	  end
       end
----mwse.log("         journalEdits[%s][%s] == %s", insertedPage, page_number,
------		   tostring(journalEdits[insertedPage] and journalEdits[insertedPage][page_number] or nil))
       if journalEdits[insertedPage] ~= nil and journalEdits[insertedPage][page_number] ~= nil then
	  if mouseClickPrevNext == true then  -- continue to other half of split page
	     mouseClickPrevNext = false
	     if splitPage == 1 then splitPage = 2 else splitPage = 1 end
	  elseif ( tonumber(page_number) < currentPage or currentPage == 0 )
	  and insertedPage == priorInsertedPage then  -- paging backwards or starting out
	     if menu:findChild(tes3ui.registerID("sveJournalBlankEndBlock")) ~= nil then
	        splitPage = 1
	     else
	        splitPage = 2 -- insert left page
	     end
          elseif tonumber(page_number) > currentPage
	  and insertedPage == priorInsertedPage then -- paging forward
	     splitPage = 1 -- insert right page
	  else -- refresh, keep as before
	  end
   	  local buttonNext = menu:findChild(tes3ui.registerID("MenuBook_button_next"))
	  if buttonNext == nil then return end
   	  local buttonPrev = menu:findChild(tes3ui.registerID("MenuBook_button_prev"))
	  if buttonPrev == nil then return end
          if splitPage == 1 and menu:findChild(tes3ui.registerID("sveJournalBlankEndBlock")) == nil then
	     if buttonNext.visible == false then
	        buttonNext.visible = true
	        splitLastPage = page_number
	     elseif page_number == "1" then
	        buttonPrev.visible = false
	     end
          elseif splitPage == 2 then
	     if buttonPrev.visible == false then
	        buttonPrev.visible = true
	     elseif page_number == splitLastPage then
	        buttonNext.visible = false
	     end
          end	
       else
          splitPage = 0
       end
       local pageSplit = false
       currentPage = tonumber(page_number)
--mwse.log("            splitPage = " .. splitPage .. ", currentPage:" .. currentPage .. ", insertedPage:" .. insertedPage)       
       for key, _ in pairs(journalEditableElements) do
          journalEditableElements[key] = nil
       end
       local journalSearchNotifyElement = menu:findChild(tes3ui.registerID("JournalSearch_notify_label"))
       for j = 1, 2 do
          local foundHeaderThisPage = false
	  local lastSpacerHeightElement = nil
          for i = 1, #element.children do
	     local child = element.children[i]
	     if isHeaderElement(child) and child.name ~= nil and string.find(child.name, "sveJournalNewPage") == nil then
	        if foundHeaderThisPage == true and child.text == headerText and config.hideRedundantDateHeaders == true then
		   child.visible = false
--mwse.log("header child.visible = false")
		else
		   child.text = string.upper(string.sub(child.text,1,1)) .. string.sub(child.text,2) or "" -- capitalize
		   child.visible = true
		   if lastSpacerHeightElement ~= nil then
		      lastSpacerHeightElement.height = lastSpacerHeightElement.height / ( config.topicSpaceCompression / 100 )
--mwse.log(lastSpacerHeightElement.name .. ":full height:" .. lastSpacerHeightElement.height)	     
		      lastSpacerHeightElement = nil
		   end
		end
		headerText = child.text
		foundHeaderThisPage = true
	     elseif child.name == "null" then
		child.visible = true
--mwse.log("null child.visible = false")		   
	        if child.height > nullSpacerHeight then
	     	   child.height = child.height * ( config.topicSpaceCompression / 100 )
		   lastSpacerHeightElement = child
	           nullSpacerHeight = child.height
--mwse.log(child.name .. ".new height:" .. child.height) 
	        end
             elseif child.text ~= nil
	     and child ~= journalSearchNotifyElement then
	        if journalEdits[insertedPage] ~= nil
		and journalEdits[insertedPage][page_number] ~= nil
		and j ~= splitPage and pageSplit == false then
		  local newChild = element:findChild(tes3ui.registerID("sveJournalNewPageText" .. page_number))
		  local newChildH = element:findChild(tes3ui.registerID("sveJournalNewPageText" .. page_number .. "H"))
		  if newChild == nil then
		      newChildH = element:createHypertext({ id = tes3ui.registerID("sveJournalNewPageText" .. page_number .. "H"), text = config.newTextLine })
		      newChild = element:createHypertext({ id = tes3ui.registerID("sveJournalNewPageText" .. page_number), text = config.newTextLine })
--mwse.log("  create sveJournalNewPageText" .. page_number)
		  end
		  newChild.text = restoreHyperLinks(journalEdits[insertedPage][page_number])
		  newChildH.text = journalEdits[insertedPage][page_number .. "H"]
--mwse.log("  update sveJournalNewPageText" .. page_number .. ".text = " .. newChild.text .. ", " ..  newChildH.text)
	    	  pageSplit = true
		  newChildH.visible = true
		  newChildH.color = journalHeaderColor or { 0.624, 0.000, 0.000 }
		  newChild.visible = true
		  newChild.color = tes3ui.getPalette("journal_topic_color")
	      	  table.insert(journalEditableElements, { headerText=insertedPage, element=newChildH, key=page_number .. "H"})
--mwse.log("child:%s journalEditableElements[%d] = { %s, %s, %s}", child.name, #journalEditableElements, insertedPage, child.text, page_number .. "H")
	      	  table.insert(journalEditableElements, { headerText=insertedPage, element=newChild, key=page_number })
--mwse.log("child:%s journalEditableElements[%d] = { %s, %s, %s}", child.name, #journalEditableElements, insertedPage, child.text, page_number)
		  local newChildI = element:findChild(tes3ui.registerID("sveJournalNewPageImage" .. page_number .. "I"))
		  local newChildIT = element:findChild(tes3ui.registerID("sveJournalNewPageText" .. page_number .. "IT"))
		  local contentPath = journalEdits[insertedPage][page_number .. "I"] and journalEdits[insertedPage][page_number .. "I"].contentPath or nil
		  if contentPath ~= nil and bookArtImages[contentPath] ~= nil then
		     if newChildI == nil then
		        newChildI = element:createImage({ id = tes3ui.registerID("sveJournalNewPageImage" .. page_number .. "I"),
				    			  path = "BookArt\\" .. contentPath })
							     --  "BookArt\\EfoulkeFirmament_Warrior.dds"})
--mwse.log("newChildI createImage contentPath:%s, width:%s", tostring(newChildI.contentPath), tostring(newChildI.width))
		     end
		     if newChildIT == nil then
		        newChildIT = element:createHypertext({ id = tes3ui.registerID("sveJournalNewPageText" .. page_number .. "IT"), text = config.newTextLine })
		     end
		     if journalEdits[insertedPage][page_number .. "IT"] == nil then
		        journalEdits[insertedPage][page_number .. "IT"] = config.newTextLine
	             end
		     newChildIT.text = journalEdits[insertedPage][page_number .. "IT"]
		     newChildIT.visible = true
		     newChildIT.color = tes3ui.getPalette("journal_topic_color")
	      	     table.insert(journalEditableElements, { headerText=insertedPage, element=newChildIT, key=page_number .. "IT"})
--mwse.log("child:%s journalEditableElements[%d] = { %s, %s, %s}", child.name, #journalEditableElements, insertedPage, child.text, page_number .. "H")
		     newChildI.contentPath = "BookArt\\" .. contentPath
		     if journalEdits[insertedPage][page_number .. "I"].width ~= nil
		     and journalEdits[insertedPage][page_number .. "I"].height ~= nil then
		        newChildI.width = journalEdits[insertedPage][page_number .. "I"].width
		        newChildI.height = journalEdits[insertedPage][page_number .. "I"].height
			newChildI.scaleMode = true
		     else -- initialize
		        journalEdits[insertedPage][page_number .. "I"].width = newChildI.width
		        journalEdits[insertedPage][page_number .. "I"].height = newChildI.height
			newChildI.scaleMode = true
	             end
--mwse.log("newChildI.contentPath = BookArt\\" .. contentPath)
		     if newChildI.width > config.maxImageWidth then
--mwse.log("   width exceeds max scaling %d->%d", newChildI.width, config.maxImageWidth)			
		        newChildI.height = newChildI.height * ( config.maxImageWidth / newChildI.width)
			newChildI.width = config.maxImageWidth
			newChildI.scaleMode = true
		     end
--mwse.log("	journalEdits.customImageScaling[%s] = %s", contentPath, tostring(journalEdits.customImageScaling[contentPath]))
		     if journalEdits.customImageScaling[contentPath] ~= nil then
--mwse.log("   width %d->%d", newChildI.width, newChildI.width * journalEdits.customImageScaling[contentPath])
		        newChildI.height = newChildI.height * journalEdits.customImageScaling[contentPath]
		        newChildI.width = newChildI.width * journalEdits.customImageScaling[contentPath]
		     end
		     newChildI.justifyText = "center"
		     newChildI.visible = true
		  else
		     if newChildI ~= nil then newChildI.visible = false end
		  end
		elseif child.text ~= nil and child.text ~= "" and ( splitPage == 0 or splitPage == j )
--		and child.name ~= "sveJournalNewPageText" .. page_number then
		and child.name ~= nil and string.find(child.name, "sveJournalNewPage") == nil then
		   child.visible = true
	           local key = string.sub(child.text,1,8) .. string.sub(child.text,-8,-1) .. tostring(string.len(child.text))
	           if journalEdits[headerText] ~= nil and journalEdits[headerText][key] ~= nil then
		      child.text = restoreHyperLinks(journalEdits[headerText][key])
		   else
		      child.text = child.text:gsub("[%.%?!]\n", "%0  ")
		      child.text = child.text:gsub("\n", " ")
		      local text = child.text
		      local i1, i2 = string.find(text, "@.-#")
		      while i2 ~= nil and i2 - i1 > 1 do
		         local hyperText = string.sub(text,i1+1,i2-1)
		         journalEdits.hyperText[string.lower(hyperText)] = true
--mwse.log("journalEdits.hyperText[%s] = true", string.lower(hyperText))
                         text = string.sub(text,i2+1)
		         i1, i2 = string.find(text, "@.-#")
		      end
		   end
	           table.insert(journalEditableElements, { headerText=headerText, element=child, key=key } )
--mwse.log("child:%s journalEditableElements[%d] = { %s, %s, %s}", child.name, #journalEditableElements, headerText, child.text, key)
		end
             end
	     if splitPage ~= 0 and splitPage ~= j
	     and child.name ~= nil and string.find(child.name, "sveJournalNewPage") == nil then
--mwse.log(" child.visible.0 = false : " .. child.name)		   
	        child.visible = false
	     elseif j == splitPage and child.name ~= nil and string.find(child.name, "sveJournalNewPage") ~= nil then
--mwse.log(" child.visible.1 = false : " .. child.name)		   
	        child.visible = false
	     end
	  end
          if j == 1 then
	     if splitPage == 2 then
	        page_number_element.text = tostring(tonumber(page_number_element.text) + 1 ) .. "-"
	     end
	     page_number_element = menu:findChild(tes3ui.registerID("MenuBook_page_number_2"))
	     if page_number_element == nil then return end
             page_number = page_number_element.text 
       	     if string.find(page_number, "%+$") then
	        page_number = tostring(tonumber(string.sub(page_number,1,-2)) + 1)
	  	page_number_element.text = page_number
       	     end
	     element = menu:findChild(tes3ui.registerID("MenuBook_page_2"))
	     if element == nil then return end
	  elseif j == 2 then
	     if splitPage == 1 then
	        page_number_element.text = tostring(tonumber(page_number_element.text) - 1 ) .. "+"
	     end
	  end
       end
       menu:updateLayout()
    end
    
    local function searchOpenPages()
--mwse.log("searchOpenPages")    
       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu == nil then return false end
       
       if activeHyperTextElement ~= nil then activeHyperTextElement.text = activeHyperText[1] end
       
       local searchFor = string.lower(inputString)
       searchFor = searchFor:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") -- escape special characters
       searchFor = searchFor:gsub("[ ,%.%?\n]","@*#*%0@*#*") -- ignore hyperlink @,# before/after words
       searchFor = "@*#*" .. searchFor .. "@*#*" -- ignore hyperlink @,# begin/end text
--mwse.log("inputString:%s -> searchFor:%s", inputString, searchFor)

       local index = 0
       local element = menu:findChild(tes3ui.registerID("MenuBook_page_1"))
       if element  == nil then return false end
       local journalSearchNotifyElement = menu:findChild(tes3ui.registerID("JournalSearch_notify_label"))
       for j = 1, 2 do
          if j == 2 then element = menu:findChild(tes3ui.registerID("MenuBook_page_2")) end
--mwse.log(" page:" .. j)
          for i = 1, #element.children do
             if element.children[i].text ~= nil and element.children[i].visible == true
	     and element.children[i] ~= journalSearchNotifyElement then
--mwse.log(" text:" .. element.children[i].text)
	        if string.find(string.lower(element.children[i].text), searchFor) then
		   local matchString = string.lower(element.children[i].text)
		   local i1 = 0
		   local i2 = 0
		   while i1 ~= nil and ( i1 == 0 or searchIndex >= index ) do
		      matchString = string.sub(matchString,i2+1)
		      i1, i2 = string.find(matchString, searchFor)
		      if i1 ~= nil then index = index + 1 end
		   end
--mwse.log("   match! index=%d >? searchIndex %d", index, searchIndex)
		   if index > searchIndex then
		      activeHyperTextElement = element.children[i]
		      activeHyperText[1] = activeHyperTextElement.text		      
		      activeHyperText[2] = activeHyperTextElement.text		      
		      -- activeHyperText[1] = activeHyperTextElement.text:gsub("%.\n", ".  ")
		      -- activeHyperText[1] = activeHyperText[1]:gsub("!\n", "!  ")
		      -- activeHyperText[1] = activeHyperText[1]:gsub("\n", " ")
		      -- activeHyperText[2] = activeHyperText[1]
		      searchIndex = index
		      i1 = i1 + string.len(activeHyperText[1]) - string.len(matchString)
		      i2 = i2 + string.len(activeHyperText[1]) - string.len(matchString)
--mwse.log("  activeHyperText[1]:%s(%d,%d,%d,%d) searchIndex:%d", activeHyperText[1], i1-1, i1, i2, i2+1, searchIndex)
	              -- if i1 >  then 
		         activeHyperText[2] = string.sub(activeHyperText[2],1,i1-1) .. "->" .. string.sub(activeHyperText[2],i1,-1)
		      -- else
		      --   activeHyperText[2] = "->" .. activeHyperText[2]
		      -- end
--mwse.log("  activeHyperText[2]:%s", activeHyperText[2])
		      element.children[i].text = activeHyperText[2]
		      return true
		   end
	        end
	     end
	  end
       end
       return false
    end

   local function restoreActiveHyperLinkTextElement()
       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu ~= nil and activeHyperTextElement ~= nil then
          activeHyperTextElement.text = activeHyperText[1]
	  local element = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1"))
	  if element == nil then return end
          element.visible = false
	  element = menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2"))
	  if element == nil then return end
          element.visible = false
	  menu:updateLayout()
       end
       activeHyperTextElement = nil
    end          

     local function searchJournal(nextPage)
--mwse.log("searchJournal")

       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu == nil then return end
       if inputString == nil or inputString == "" then return end

       local endFlag = false
       
       if nextPage == true then
          -- turn the page
          restoreActiveHyperLinkTextElement()

          local element = menu:findChild(tes3ui.registerID("MenuBook_page_number_1"))
	  if element == nil then return end
	  local pageNum1 = element.text
     	  if string.find(pageNum1, "-$") then pageNum1 = tostring(tonumber(string.sub(pageNum1,1,-2)) - 1) end
          element = menu:findChild(tes3ui.registerID("MenuBook_page_number_2"))
	  if element == nil then return end
	  local pageNum2 = element.text
     	  if string.find(pageNum2, "+$") then pageNum2 = tostring(tonumber(string.sub(pageNum2,1,-2)) + 1) end
--mwse.log("searchJournal pageNum1:" .. pageNum1 .. ", pageNum2:" .. pageNum2)

          if direction == true then
             element = menu:findChild(tes3ui.registerID("MenuBook_button_next"))
	     if element == nil then return end
	  else
             element = menu:findChild(tes3ui.registerID("MenuBook_button_prev"))
	     if element == nil then return end
          end
	  element:triggerEvent("mouseClick")
	  --tes3.playsound({ sound = "book page2" })
	  searchIndex = 0

	  if ( menu:findChild(tes3ui.registerID("MenuBook_page_number_1")) ~= nil
	       and menu:findChild(tes3ui.registerID("MenuBook_page_number_1")).text == pageNum1 )
	  or ( menu:findChild(tes3ui.registerID("MenuBook_page_number_2")) ~= nil
	       and menu:findChild(tes3ui.registerID("MenuBook_page_number_2")).text == pageNum2 ) then
--mwse.log("searchJournal pageTurn failed for pp.%s,%s splitPage:%d", pageNum1, pageNum2, splitPage)
	     if direction == true and splitPage ~= 1 and menu:findChild(tes3ui.registerID("MenuBook_button_next")).visible == false
	     or direction == false and splitPage ~= 2 and menu:findChild(tes3ui.registerID("MenuBook_button_prev")).visible == false then
--mwse.log("  begin or end, flip direction %s->%s  ", splitPage, tostring(direction), tostring(not direction))
	        direction = not direction
		endFlag = true
	     end
	  else
--mwse.log("searchJournal pageTurn succeeded for pp.%s,%s splitPage:%d", pageNum1, pageNum2, splitPage)
	  end
	  updateContentOpenPages()
       end

       local result = searchOpenPages()
       local function continueSearching()
          return ( isKeyComboPressed(config.prevMatchKeyInfo)
       		 or isKeyComboPressed(config.nextMatchKeyInfo)
         	 or isKeyComboPressed(config.contMatchKeyInfo) )
       end
       local contSearch = continueSearching()
--mwse.log("( result(%s) == false or nextPage(%s) == false ) and contSearch (%s) == true", tostring(result), tostring(nextPage), tostring(contSearch))
       if endFlag == false and ( ( contSearch == true and result == false ) or nextPage == false ) then
--mwse.log("begin timer")	  
          local count = 10
	  if pageTurnTimer ~= nil then pageTurnTimer:cancel() end
          pageTurnTimer = timer.start({duration=config.pageTurnDelay/1000/count, type = timer.real, iterations = count, callback = function()
	  if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
	  if count > 0 and continueSearching() == true then
--mwse.log("count:%d continueSearching():true", count)
		if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
	        count = count - 1
	        if count == 0 and tes3ui.findMenu(tes3ui.registerID("MenuJournal")) ~= nil then
	           searchJournal(true)
		end
	     else
		pageTurnTimer:cancel()
	     end
          end})
       else
--mwse.log("cancel page timer")	  
	  if pageTurnTimer ~= nil then pageTurnTimer:cancel() end
       end
       if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
       if result == true then
          updateNotifyElement(true)
       else
	  if searchIndex > 0 then
	     searchIndex = 0
	     searchJournal(false)
	     flashSearchIndicators()
	     return
          elseif activeHyperTextElement ~= nil then
             restoreActiveHyperLinkTextElement()
	  end
          updateNotifyElement(false)
       end
    end

    local pageTurnTimer2
    local function newSearch(samePage)
--mwse.log("new search(%s)", tostring(samePage))

      timer.start({duration=config.uiLatency/1000, type = timer.real, callback = function()
    -- one frame delay
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return end
      local element = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
      if element == nil then return end
      element.text = ""
      searchIndex = 0
      inputString = ""
      if journalEditIndex ~= 0 then
--mwse.log("  journalEditIndex ~= 0")
	 if menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")) ~= nil
	 and menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2")) ~= nil then 
            menu:findChild(tes3ui.registerID("JournalSearch_edit_divider1")).visible = false
            menu:findChild(tes3ui.registerID("JournalSearch_edit_divider2")).visible = false
      	 end
      	 journalEditIndex = 0
	 if samePage == true then restoreActiveHyperLinkTextElement() else activeHyperTextElement = nil end
         return
      elseif samePage == true then
--mwse.log("  samePage == true")      
         restoreActiveHyperLinkTextElement()
         updateNotifyElement(nil)
      else
         activeHyperTextElement = nil
         updateContentOpenPages()
         element = menu:findChild(tes3ui.registerID("MenuBook_page_number_1"))
	 if element == nil then return end
	 local page_number_1 = element.text
--mwse.log("  samePage == false, page_number_1:" .. page_number_1)    
	 local count = 10
	 if pageTurnTimer2 ~= nil then pageTurnTimer2:cancel() end
         pageTurnTimer2 = timer.start({duration=config.pageTurnDelay/1000/count, type = timer.real, iterations = count, callback = function()
	    if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
	    if count > 0 and menu:findChild(tes3ui.registerID("MenuBook_page_number_1")) ~= nil
	    and menu:findChild(tes3ui.registerID("MenuBook_page_number_1")).text ~= page_number_1 then
               updateContentOpenPages()
	       pageTurnTimer2:cancel()
	    end
         end})
      end
      end})
   end

    local function closeJournal()
       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
       if menu == nil then return end
       local element = menu:findChild(tes3ui.registerID("MenuBook_button_close"))
       if element == nil then return end
       
      local closeButtonIndicator = menu:findChild(tes3ui.registerID("MenuBook_button_close_idle"))
      if closeButtonIndicator == nil then
--mwse.log("MenuJournal MenuExit MenuBook_button_close_idle element == nil")
         return
      else
          closeButtonIndicator = string.find(closeButtonIndicator.contentPath, "close")
          -- element:triggerEvent("mouseClick")
          -- sequence below avoids "Menu Error: Memory pointer corrupted" of above
          element:triggerEvent("mouseDown")
          element:triggerEvent("mouseUp")
          timer.start({duration=config.uiLatency/1000, type = timer.real, callback = function()
       	     if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
	     element = menu:findChild(tes3ui.registerID("MenuBook_button_close"))
	     if element == nil then return end
	     element:triggerEvent("mouseClick") end })
          -- allowing the buttonDown event to end the buttonPress event
          -- convoluated and maybe some better overall method but seems working so OK
	  
	  if closeButtonIndicator ~= true then newSearch(nil) end
       end
    end

   local function saveEdit()
      if journalEditIndex == 0 then return end

      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return false end
      if journalEditableElements[journalEditIndex] == nil then return end
      if journalEditableElements[journalEditIndex].element == nil then return end
      journalEditableElements[journalEditIndex].element.text = inputString

      local headerText = journalEditableElements[journalEditIndex].headerText
      
      if inputString == activeHyperText[1] then
--mwse.log("saveEdit no change to header:%s, text:%s", headerText, inputString)
         return
      end	

      inputString = restoreHyperLinks(inputString)

--mwse.log("new inputString:" .. inputString)
      if journalEdits[headerText] == nil then
         journalEdits[headerText] = {}
      end
      inputString = inputString:gsub("|","") -- strip any stray cursors
      journalEdits[headerText][journalEditableElements[journalEditIndex].key] = inputString
--mwse.log("journalEdits[%s][%s] = %s", headerText, journalEditableElements[journalEditIndex].key, inputString)
      activeHyperTextElement.text = inputString
      menu:updateLayout()
   end
   
   local function newEdit(action)
--mwse.log("newEdit() action:%d, journalEditIndex:%d, #journalEditableElements:%d", action, journalEditIndex, #journalEditableElements)   
      -- action = -2 (top of page 1), +2 (bottom of page 2), -1 (down), +1 (up), +3 (new page), +10/-10 next/prev image
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return false end

      if math.abs(action) == 2 then
         -- exit search
         restoreActiveHyperLinkTextElement()
         updateNotifyElement(nil)
	 searchIndex = 0
         if action == -2 then
	    journalEditIndex = 1
	 else
	    journalEditIndex = #journalEditableElements
	 end
      else
      	 -- first save any modifications
	 saveEdit()
	 
	 if action == -1 then
	    if journalEditIndex < #journalEditableElements then
	       journalEditIndex = journalEditIndex + 1
	    else
	       newSearch(nil)
	       return
	    end
	 elseif action == 1 then
	    if journalEditIndex > 1 then
	       journalEditIndex = journalEditIndex - 1
	    else
	       newSearch(nil)
	       return
	    end
	 elseif math.abs(action) == 100 or math.abs(action) == 101 then
	    if splitPage == 0 then return end
            local page_number_element = menu:findChild(tes3ui.registerID("MenuBook_page_number_" .. ( 3 - splitPage ) ) )
       	    if page_number_element == nil then return end
       	    local page_number = page_number_element.text
       	    if string.find(page_number, "[%-]$") then
       	       page_number = tostring(tonumber(string.sub(page_number,1,-2)) - 1)
       	    elseif string.find(page_number, "[%+]$") then
       	       page_number = tostring(tonumber(string.sub(page_number,1,-2)) + 1)
       	    end
--mwse.log("  page_number %s->%s", page_number_element.text, page_number)
	    if journalEdits[insertedPage][page_number .. "I"] == nil then return end
	    local contentPath = journalEdits[insertedPage][page_number .. "I"].contentPath
	    if contentPath == nil then return end
	    if journalEdits.customImageScaling[contentPath] == nil then
	       journalEdits.customImageScaling[contentPath] = 1.0
--mwse.log("create journalEdits.customImageScaling[%s] = %.2f", contentPath, journalEdits.customImageScaling[contentPath])
	    end
	    local delta = 0.0
	    if math.abs(action) == 100 then
	       delta = ( action / 100 ) * ( config.incrImageScaleStep / 100 )
	    else
	       delta = ( action / math.abs(action) ) * ( config.incrImageFineScaleStep / 1000 )
	    end	       
	    journalEdits.customImageScaling[contentPath] = journalEdits.customImageScaling[contentPath] + delta
--mwse.log("modify journalEdits.customImageScaling[%s] -> %.2f", contentPath, journalEdits.customImageScaling[contentPath])
	    updateContentOpenPages()
	    menu:updateLayout()
	    return
	 elseif math.abs(action) == 10 then
	    if #journalEdits["bookArtImages"] == 0 then
	       tes3.messageBox(config.messageNoBookArt)
	       return
	    end
	    if splitPage == 0 then
	       newEdit(3) -- split the page
	       searchIndex = 0
	    end
	    if action == -10 then
	       if imageIndex < #journalEdits["bookArtImages"] then
	          imageIndex = imageIndex + 1
	       else
	          imageIndex = 0
	       end
	    elseif imageIndex > 1 then 
	       imageIndex = imageIndex - 1
	    elseif imageIndex == 1 then
	       imageIndex = 0
	    else -- if imageIndex == 1
	       imageIndex = #journalEdits["bookArtImages"]
	    end
--mwse.log("  imageIndex -> %d",  imageIndex)
            local page_number_element = menu:findChild(tes3ui.registerID("MenuBook_page_number_" .. ( 3 - splitPage ) ) )
       	    if page_number_element == nil then return end
       	    local page_number = page_number_element.text
       	    if string.find(page_number, "[%-]$") then
       	       page_number = tostring(tonumber(string.sub(page_number,1,-2)) - 1)
       	    elseif string.find(page_number, "[%+]$") then
       	       page_number = tostring(tonumber(string.sub(page_number,1,-2)) + 1)
       	    end
--mwse.log("  page_number %s->%s", page_number_element.text, page_number)
	    if imageIndex > 0 then
	       journalEdits[insertedPage][page_number .. "I"] = journalEdits["bookArtImages"][imageIndex]
--mwse.log("journalEdits[%s][%s].contentPath = %s", insertedPage, page_number .. "I", journalEdits[insertedPage][page_number .. "I"].contentPath)
	    else
	       journalEdits[insertedPage][page_number .. "I"] = nil
--mwse.log("journalEdits[%s][%s] = nil", insertedPage, page_number .. "I")
	    end
	    updateContentOpenPages()
      	    showActiveHyperTextElementDividers()
	    menu:updateLayout()
	    if searchIndex == 0 then -- not edit mode
	       newSearch(nil)
	    end
	    return
	 else -- action == +3
	    if splitPage ~= 0 then -- already split, move to opposite page
	       local parent = journalEditableElements[journalEditIndex].element.parent
	       for i = 1, #journalEditableElements do
--mwse.log("  (3) splitPage=%d, %s ~= %s (%d/%d)", splitPage, parent.name, journalEditableElements[i].element.parent.name, i, #journalEditableElements)	       
	          if parent.name ~= journalEditableElements[i].element.parent.name then
		     journalEditIndex = i
--mwse.log("     journalEditIndex = " .. i)		     
		     break
		  end
	       end
	    else
      	       local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      	       if menu == nil then return end
	       local element = menu:findChild(tes3ui.registerID("MenuBook_page_number_1"))
	       if element == nil then return end
	       local pageNum1 = element.text
	       element = menu:findChild(tes3ui.registerID("MenuBook_page_number_2"))
	       if element == nil then return end
	       local pageNum2 = element.text
	       if journalEdits[insertedPage] == nil then journalEdits[insertedPage] = {} end
	       if journalEdits[insertedPage][pageNum1] ~= nil then return end
	       journalEdits[insertedPage][pageNum1] = config.newTextLine
	       local headerText = ""
	       if insertedPage == "insertedPage" then
	          headerText = tostring(tes3.getGlobal("Day")) .. " " ..
	          	       tes3.findGMST(tes3.getGlobal("Month")).value ..
			       " (" .. tes3.findGMST("sDay").value .. " " .. tostring   (tes3.getGlobal("DaysPassed")) .. ")"
	       else
	          headerText = string.upper(string.sub(insertedPage, 13, 13))
	          if string.len(insertedPage) > 13 then
	             headerText = headerText .. string.sub(insertedPage, 14)
	          end
	       end
	       journalEdits[insertedPage][pageNum1 .. "H"] = headerText
	       journalEdits[insertedPage][pageNum2] = config.newTextLine
	       journalEdits[insertedPage][pageNum2 .. "H"] = headerText
--mwse.log("newEdit(3) journalEdits[%s][%s,%s]=\"\"", insertedPage, pageNum1, pageNum2)
	       splitPage = 1
	       updateContentOpenPages()
	       journalEditIndex = #journalEditableElements
	    end
         end
      end
      
      local input = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
      if input == nil then return end
      if journalEditableElements[journalEditIndex] == nil then return end
      input.text = journalEditableElements[journalEditIndex].element.text
      inputString = input.text
      activeHyperText[1] = input.text
      activeHyperTextElement = journalEditableElements[journalEditIndex].element
      menu:updateLayout()

      local element = menu:findChild(tes3ui.registerID("PartParagraphInput_text_input"))
      if element == nil then return end
      activeHyperTextElement.text = element.text
      showActiveHyperTextElementDividers()
      
      menu:updateLayout()
     
   end

   local hotKeyPressed = false

   local function onKeyPress(e)
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return end
--[[
      -- if MenuJournal_bookmark is visible then reset
      local element = menu:findChild(tes3ui.registerID("MenuJournal_bookmark"))
      if element ~= nil and element.visible == true then
         restoreActiveHyperLinkTextElement()
         updateNotifyElement(nil)
	 searchIndex = 0
         menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input")).text = ""
	 menu:updateLayout()
	 return
      end
]]--

      local input = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
      if input == nil then return end
      
      tes3.enableKey(36)
      input:forwardEvent(e)
      tes3.disableKey(36)

      timer.start({duration=config.uiLatency/1000, type = timer.real, callback = function()
      -- one frame delay to capture the input
      
      if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
      
      if input == nil or input.text == nil then
      elseif hotKeyPressed == true then
      	 input.text = inputString -- redundant left in
      elseif journalEditIndex == 0 then -- search mode
	 local priorInputString = inputString
         inputString = input.text
      	 if inputString == nil then
            return
	 end
--mwse.log("onKeyPress inputString:\"%s\"", inputString)
         if inputString == "" then
      	    updateNotifyElement(nil)
	    restoreActiveHyperLinkTextElement()
         elseif inputString == priorInputString then -- possibly moved cursor
       	    local element = menu:findChild(tes3ui.registerID("JournalSearch_notify_label"))
	    if element ~= nil and element.text ~= "" then
	       element.text = menu:findChild(tes3ui.registerID("PartParagraphInput_text_input")).text .. string.sub(element.text,-2,-1)
	    end
	    inputString = input.text
	    menu:updateLayout()
	 else
	    if string.match(input.text, "[\n\t\f\r\v]") ~= nil then
--mwse.log("onKeyPress newline, tab, etc.")
               input.text = input.text:gsub("[\n\t\f\r\v]", "")
	       menu:updateLayout()
	       inputString = input.text
--mwse.log("trimmed inputString:\"" .. inputString .. "\"")
	    end
            searchIndex = 0
      	    searchJournal(false)
	 end
      else -- edit mode
         if activeHyperTextElement == nil then return end
	 inputString = input.text
--mwse.log("onKeyPress inputString:\"%s\"", inputString)
      	 local element =  menu:findChild(tes3ui.registerID("PartParagraphInput_text_input"))
	 if element == nil then return end
      	 activeHyperTextElement.text = element.text
	 menu:updateLayout()
      end
      end})
   end

   local function onKeyDown(e)

      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then return end
      
      hotKeyPressed = true -- starting point
      
      local function isKeyComboDown(keyInfo)
         if keyInfo.keyCode == e.keyCode
	 and keyInfo.isShiftDown == e.isShiftDown
	 and keyInfo.isAltDown == e.isAltDown
	 and keyInfo.isControlDown == e.isControlDown then
	    return true
	 else
	    return false
	 end
      end	 

--mwse.log("keyDown:" .. e.keyCode)      
      if isKeyComboDown(config.exitKeyInfo) then
	 newSearch(true)
      elseif isKeyComboDown(config.closeKeyInfo) then
         closeJournal()
      elseif journalEditIndex == 0 then -- search mode
         if isKeyComboDown(config.contMatchKeyInfo) then
	    if inputString ~= nil and inputString ~= "" then
	       searchJournal(false)
	       return
	    end
         elseif isKeyComboDown(config.nextMatchKeyInfo) then
	    direction = true
	    if inputString ~= nil and inputString ~= "" then
	       searchJournal(false)
	       return
	    end
         elseif isKeyComboDown(config.nextPageKeyInfo) then
	    local function nextPage()
      	       if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return false end
	       direction = true
   	       local button = menu:findChild(tes3ui.registerID("MenuBook_button_next"))
	       if button == nil then return end
	       if button.visible == true then
		  button:triggerEvent("mouseClick")
	  	  --tes3.playsound({ sound = "book page2" })
	          newSearch(false)
	       end
	       local count = 10
	       if pageTurnTimer ~= nil then pageTurnTimer:cancel() end
               pageTurnTimer = timer.start({duration=config.pageTurnDelay/1000/count, type = timer.real, iterations = count, callback = function()
       	          if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
	          if count > 0 and isKeyComboPressed(config.nextPageKeyInfo) == true then
		     count = count - 1
		     if count == 0 then
	       	     	nextPage()
		     end
		  else
		     pageTurnTimer:cancel()
		  end
	       end})
	    end
            nextPage()
         elseif isKeyComboDown(config.prevMatchKeyInfo) then
	    direction = false
	    if inputString ~= nil and inputString ~= "" then
	       searchJournal(false)
	       return
	    end
         elseif isKeyComboDown(config.prevPageKeyInfo) then
	    local function prevPage()
      	       if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return false end
	       direction = false
   	       local button = menu:findChild(tes3ui.registerID("MenuBook_button_prev"))
	       if button == nil then return end
	       if button.visible == true then
		  button:triggerEvent("mouseClick")
	  	  --tes3.playsound({"book page2", reference=tes3.player})
	          newSearch(false)
	       end
	       local count = 10
	       if pageTurnTimer ~= nil then pageTurnTimer:cancel() end
               pageTurnTimer = timer.start({duration=config.pageTurnDelay/1000/count, type = timer.real, iterations = count, callback = function()
	          if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return end
		  if count > 0 and isKeyComboPressed(config.prevPageKeyInfo) == true then
		     count = count - 1
		     if count == 0 then
	       	     	prevPage()
		     end
		  else
		     pageTurnTimer:cancel()
		  end
	       end})
	    end
            prevPage()
         elseif isKeyComboDown(config.selectEditDownKeyInfo) then
	    newEdit(-2)
         elseif isKeyComboDown(config.selectEditUpKeyInfo) then
	    newEdit(2)
         elseif isKeyComboDown(config.nextImageKeyInfo) then
	    newEdit(10)
         elseif isKeyComboDown(config.prevImageKeyInfo) then
	    newEdit(-10)
         elseif isKeyComboDown(config.incrImageScaleKeyInfo) then
	    newEdit(100)
         elseif isKeyComboDown(config.decrImageScaleKeyInfo) then
	    newEdit(-100)
         elseif isKeyComboDown(config.incrImageFineScaleKeyInfo) then
	    newEdit(101)
         elseif isKeyComboDown(config.decrImageFineScaleKeyInfo) then
	    newEdit(-101)
	 else
	    hotKeyPressed = false
         end
      else -- edit mode
--mwse.log("keyDown edit mode:" .. e.keyCode)      
         if isKeyComboDown(config.saveEditKeyInfo) then
	    saveEdit()
	    newSearch(nil)
         elseif isKeyComboDown(config.selectEditDownKeyInfo) then
	    newEdit(-1)
         elseif isKeyComboDown(config.selectEditUpKeyInfo) then
	    newEdit(1)
         elseif isKeyComboDown(config.nextImageKeyInfo) then
	    newEdit(10)
         elseif isKeyComboDown(config.prevImageKeyInfo) then
	    newEdit(-10)
         elseif isKeyComboDown(config.incrImageScaleKeyInfo) then
	    newEdit(100)
         elseif isKeyComboDown(config.decrImageScaleKeyInfo) then
	    newEdit(-100)
         elseif isKeyComboDown(config.incrImageFineScaleKeyInfo) then
	    newEdit(101)
         elseif isKeyComboDown(config.decrImageFineScaleKeyInfo) then
	    newEdit(-101)
         elseif isKeyComboDown(config.newPageInsertKeyInfo) then
	    newEdit(3)
	 elseif config.newPageInsertKeyInfo.keyCode == tes3.scanCode["keyRight"]
	 and isKeyComboDown( { keyCode = tes3.scanCode["keyLeft"],
	     		       isAltDown = config.newPageInsertKeyInfo.isAltDown,
	     		       isShiftDown = config.newPageInsertKeyInfo.isShiftDown,
	     		       isControlDown = config.newPageInsertKeyInfo.isControlDown, } ) then
	    newEdit(3)
         elseif isKeyComboDown(config.deleteEntryKeyInfo) then
      	    local input = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
	    if input == nil then return end
	    input.text = ""
	    menu:updateLayout()
      	    local element = menu:findChild(tes3ui.registerID("PartParagraphInput_text_input"))
	    if element == nil then return end
      	    activeHyperTextElement.text = element.text
	    menu:updateLayout()
	    inputString = ""
         elseif isKeyComboDown(config.deleteWordKeyInfo) then
      	    local input = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
	    if input == nil then return end
	    local newText = activeHyperTextElement.text:gsub("%s-%S-|%S-%s-", "|")
	    local element = menu:findChild(tes3ui.registerID("PartParagraphInput_text_input"))
	    if element == nil then return end
	    element.text = newText	    
    	    -- menu:findChild(tes3ui.registerID("PartParagraphInput_wrapped_text_holder")).text = newText
     	    activeHyperTextElement.text = newText
	    input.text = newText:gsub("|","")
	    menu:updateLayout()
	    inputString = input.text
	 else
	    hotKeyPressed = false
         end
      end
      if hotKeyPressed == true then
	 return false
      end
   end
 
  -- done note and search shared helper functions
  
   local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
   if menu == nil then return end
   
   local input_block = menu:createBlock{ id = tes3ui.registerID("sveTextInputPopUp_Input_block") }
   input_block.height = 0
   input_block.width = config.cursorUpDownJumpChar * 10  -- 10pt text
   local input_border = input_block:createThinBorder{ id = tes3ui.registerID("sveTextInputPopUp_Input_border") }
   input_border.width = config.cursorUpDownJumpChar * 10  -- 10pt text
   local input = input_border:createParagraphInput{ id = tes3ui.registerID("sveTextInputPopUp_Input") }
   input.width = config.cursorUpDownJumpChar * 10  -- 10pt text
   
   menu.repeatKeys = true
--
--   local input = menu:createParagraphInput{ id = tes3ui.registerID("sveTextInputPopUp_Input") }
--   input.width = config.cursorUpDownJumpChar * 10  -- 10pt text
--   input.height = 0

--mwse.log("input.width:%d", input.width)

   tes3.disableKey(journalBindKey) -- tes3.scanCode.j -- "J" journal exit
   input:register("keyPress", onKeyPress)
   input:register("keyEnter", onKeyPress)

   local buttonNext = menu:findChild(tes3ui.registerID("MenuBook_button_next"))
   if buttonNext == nil then return end
   buttonNext:register("mouseClick", function(e)
--mwse.log("buttonNext:register.mouseClick splitPage = " .. splitPage)   
      	 if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return false end
         if splitPage ~= 1 or menu:findChild(tes3ui.registerID("sveJournalBlankEndBlock")) ~= nil then
   	    buttonNext = menu:findChild(tes3ui.registerID("MenuBook_button_next"))
   	    if buttonNext == nil then return end
            buttonNext:forwardEvent(e)
         else
	    mouseClickPrevNext = true
            updateContentOpenPages()
         end
      end)
      
   local buttonPrev = menu:findChild(tes3ui.registerID("MenuBook_button_prev"))
   if buttonPrev == nil then return end
   buttonPrev:register("mouseClick", function(e)
--mwse.log("buttonPrev:register.mouseClick splitPage = " .. splitPage)   
      	 if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return false end
         if splitPage ~= 2 then
	    buttonPrev = menu:findChild(tes3ui.registerID("MenuBook_button_prev"))
   	    if buttonPrev == nil then return end
            buttonPrev:forwardEvent(e)
         else
	    mouseClickPrevNext = true
            updateContentOpenPages()
         end
      end)

   local function onMouseWheel(e)
--mwse.log("onMouseWheel:register.mouseClick splitPage = " .. splitPage)   
      	 if tes3ui.findMenu(tes3ui.registerID("MenuJournal")) == nil then return false end
         if ( splitPage == 1 and e.delta < 0 )
         or ( splitPage == 2 and e.delta > 0 ) then
	    mouseClickPrevNext = true
            updateContentOpenPages()
	    return false
         else
	    newSearch(nil)
	 end
   end

   event.register("mouseWheel", onMouseWheel)
   event.register("keyDown", onKeyDown)
   event.register("mouseButtonUp", newSearch)

   local function onMenuExit()
      local function suppressCloseHotKeyOnClose()  -- for tab close, suppress FOV change
	 tes3.disableKey(config.closeKeyInfo.keyCode)
	 timer.start({duration=0.5, type = timer.real, callback = function()
         	     tes3.enableKey(config.closeKeyInfo.keyCode)
		     end})
      end
      local menu = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
      if menu == nil then  -- destroyed?
         tes3.enableKey(journalBindKey) -- tes3.scanCode.j -- "J" journal exit
   	 event.unregister("mouseWheel", onMouseWheel)
	 event.unregister("keyDown", onKeyDown)
	 event.unregister("mouseButtonUp", newSearch)
	 suppressCloseHotKeyOnClose()
	 return
      end

      local element = menu:findChild(tes3ui.registerID("MenuBook_button_close_idle"))
      if element == nil then
--mwse.log("MenuJournal MenuExit MenuBook_button_close_idle element == nil")
         return
      elseif string.find(element.contentPath, "close") ~= nil then
--mwse.log("MenuJournal MenuExit")
         tes3.enableKey(36)
   	 event.unregister("mouseWheel", onMouseWheel)
	 event.unregister("keyDown", onKeyDown)
	 event.unregister("mouseButtonUp", newSearch)
      	 local input = menu:findChild(tes3ui.registerID("sveTextInputPopUp_Input"))
	 if input ~= nil then
--mwse.log("MenuJournal MenuExit2")	 
   	    input:unregister("keyPress", onKeyPress)
   	    input:unregister("keyEnter", onKeyPress)
	 end
	 suppressCloseHotKeyOnClose()
      else
         newSearch(nil)
      end
   end
   
   event.register("menuExit", onMenuExit, { doOnce = true })
   
   local element = menu:findChild(tes3ui.registerID("MenuBook_button_close"))
   if element == nil then return end
   element:register("mouseDown", onMenuExit)
   element:register("destroy", onMenuExit)
   
   updateContentOpenPages()
   menu:updateLayout()
   tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
end

local function extractBookArtImages(bookText)
--mwse.log("extractBookArtImages(%s)", bookText)
   if string.find(bookText, "IMG SRC=") ~= nil then
      local i, j = string.find(bookText, "<IMG SRC=\".-\"")
      local count = 0
      while j ~= nil do
         local contentPath = string.sub(bookText, i+10, j-1)
	 if bookArtImages[contentPath] == nil
	 and string.lower(contentPath) ~= "theempire.tga" then -- mismatched file name in vanilla morrowind
	    bookArtImages[contentPath] = true
	    local notBSA = lfs.attributes("Data Files\\BookArt\\" .. contentPath) and true or false
	    table.insert(journalEdits["bookArtImages"], { contentPath = contentPath, notBSA = notBSA } )
--mwse.log("  journalEdits[bookArtImages][%d].contentPath = %s, notBSA = %s", #journalEdits["bookArtImages"], journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].contentPath, journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].notBSA )
      	    bookText = string.sub(bookText, j)
	    local width, height = string.match(bookText, " WIDTH=\"(%d+)\" HEIGHT=\"(%d+)\"")
--mwse.log(" width=%s, height=%s", tostring(width), tostring(height))	    
	    if width ~= nil and height ~= nil then
	       journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].width = tonumber(width)
	       journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].height = tonumber(height)
--mwse.log("  store width:%d, height:%d", journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].width, journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].height)
	    end
	    count = count + 1
	 else
      	    bookText = string.sub(bookText, j)
	 end
--mwse.log("remaining bookText = " .. bookText)	 
      	 i, j = string.find(bookText, "<IMG SRC=\".-\"")
      end
      if count == 1 then
         tes3.messageBox(config.messageNewBookArt)
      elseif count > 1 then
         tes3.messageBox(config.messageNewBookArts)
      end
   end
end      

local function onEquip(e)
--mwse.log("onActivate %s->%s", e.reference.id, e.item.id)
   if e.reference ~= tes3.player then
      return
   end
   if e.item.objectType == tes3.objectType.book then
--mwse.log("onEquip book:%s", e.item.id)
      extractBookArtImages(e.item.text)
   end
end   

local function onActivate(e)
--mwse.log("onActivate %s->%s", e.activator.id, e.target.id)
   if e.activator ~= tes3.player then
--mwse.log("     e.activator ~= tes3.player")
      return
   end
   if e.target.object.objectType == tes3.objectType.book then
--mwse.log("onActivate book:%s", e.target.id)
      extractBookArtImages(e.target.object.text)
   end
end   

local function onLoaded()
   local data = tes3.player.data
   if data.sve == nil then
	data.sve = {}
   end
   if data.sve.journalEdits == nil then
     data.sve.journalEdits = {}
   end
   if data.sve.journalEdits.hyperText == nil then
        data.sve.journalEdits.hyperText = {}
   end
   if data.sve.journalEdits["insertedPage"] == nil then
        data.sve.journalEdits["insertedPage"] = {}
   end
   if data.sve.journalEdits["bookArtImages"] == nil then
        data.sve.journalEdits["bookArtImages"] = {}
   end
   if data.sve.journalEdits.customImageScaling == nil then
      data.sve.journalEdits.customImageScaling = { ["BalmoraRegion_377_253.tga"] = 1.45 }
   end   
   journalEdits = data.sve.journalEdits

   for contentPath, _ in pairs(bookArtImages) do
      bookArtImages[contentPath] = nil
   end
   
   local compact = false
   for index = 1, #journalEdits["bookArtImages"] do
      local image = journalEdits["bookArtImages"][index]
      if image ~= nil and image.notBSA == true
      and lfs.attributes("Data Files\\BookArt\\" .. image.contentPath) == nil then
--mwse.log("Data Files\\BookArt\\" .. image.contentPath .. " missing !!.. mark to remove from journalEdits[\"bookArtImages\"]")
         journalEdits["bookArtImages"][index] = nil
	 compact = true
      else
--mwse.log("valid journalEdits[\"bookArtImages\"][%d].contentPath = %s", index, image.contentPath)
         bookArtImages[image.contentPath] = index
      end
   end
   if compact == true then
      local n = #journalEdits["bookArtImages"]
      local j = 0
--mwse.log("compact removed journalEdit[\"bookArtImages\"] .. " .. n)
      for i = 1, n do
         if journalEdits["bookArtImages"][i] ~= nil then
	    j = j + 1
	    journalEdits["bookArtImages"][j] = journalEdits["bookArtImages"][i]
--mwse.log("Data Files\\BookArt\\%s valid, re-index %d->%d", journalEdits["bookArtImages"][i].contentPath, i, j)
	 else
--mwse.log("Data Files\\BookArt\\nil invalid, skip index %d", i)
	 end
      end
      for i = j + 1, n do
         journalEdits["bookArtImages"][i] = nil
--mwse.log("  prune journalEdits[\"bookArtImages\"][%d] = nil", i)
      end
   end
	    

   local function findBookArt(path)
      for file in lfs.dir(path) do
         if file ~= "." and file ~= ".." then
            local f = path .. "\\" .. file
	    --mwse.log("  " .. f)
            local attr = lfs.attributes(f)
            if attr.mode == "directory" then
--mwse.log("folder found: " .. f)
	       findBookArt(f)
	    else
	       local contentPath = f:gsub("Data Files\\BookArt\\","")
--mwse.log("file found: " .. f .. ", contentPath extracted: " .. contentPath)
	       if contentPath ~= nil and contentPath ~= ""
	       and ( string.endswith(contentPath, ".dds") or string.endswith(contentPath, ".tga") )
	       and bookArtImages[contentPath] == nil then
	          bookArtImages[contentPath] = true
	          table.insert(journalEdits["bookArtImages"], { contentPath = contentPath, notBSA = true } )
--mwse.log("  journalEdits[bookArtImages][%d].contentPath = %s, notBSA = true", #journalEdits["bookArtImages"], journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].contentPath)
	          local width, height = string.match(contentPath, "_(%d+)_(%d+)%.[dt][dg][sa]$")
--mwse.log(" 1st chance width=%s, height=%s", tostring(width), tostring(height))	    
	          if width ~= nil and height ~= nil then
	             journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].width = tonumber(width)
	             journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].height = tonumber(height)
--mwse.log("  store width:%d, height:%d", journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].width, journalEdits["bookArtImages"][#journalEdits["bookArtImages"]].height)
	          end
	       end
	    end
         end
      end
   end
--mwse.log("findBookArt(\"Data Files\\BookArt\\Journal\")")
   findBookArt("Data Files\\BookArt\\Journal")

end

local function onInitialized()
   event.register("loaded", onLoaded)
   event.register("activate", onActivate)
   event.register("equip", onEquip)
   event.register("uiActivated", onMenuJournalActivated, { filter = "MenuJournal" } )

--mwse.log("[Journal Search and Edit] Initialized")
end
event.register("initialized", onInitialized)

-- thanks and credit to Merlord for Easy MCM and Greatness7 for usage reference
-- Create a placeholder MCM page if the user doesn't have easyMCM installed.
local function placeholderMCM(element)
    element:createLabel{text="This mod requires the EasyMCM library to be installed."}
    local link = element:createTextSelect{text="Go to EasyMCM Nexus Page"}
    link.color = tes3ui.getPalette("link_color")
    link.widget.idle = tes3ui.getPalette("link_color")
    link.widget.over = tes3ui.getPalette("link_over_color")
    link.widget.pressed = tes3ui.getPalette("link_pressed_color")
    link:register("mouseClick", function()
        os.execute("start https://www.nexusmods.com/morrowind/mods/46427?tab=files")
    end)
end
local function registerModConfig()
    local easyMCM = include("easyMCM.modConfig")
    local mcmData = require("sve.journal.mcm")
    local modData = easyMCM and easyMCM.registerModData(mcmData)
    mwse.registerModConfig(mcmData.name, modData or {onCreate=placeholderMCM})
end
event.register("modConfigReady", registerModConfig)

-- dev rolling to do list
  -- hide/skip search for page redundant MenuBook_hypertext with PartHyperText_plain_text children (16 Last Seed...)
  -- edit key code brings up hidden paragraph entry
   --o if no change in string the skip search mechanic
   --o only 0.2s latency check if enter key held down
   --o insert a bit of space after header, a bit less between items
   --o fix -X on wrap around search on same page
   --o [, ] for next/previous search, shift- for next/previous page search
   --o left/right arrow for page advancement, held down to continue
   --o try paragraph instead of text entry for search

   --o backspace not clearing the notify_element
   --o link follow->back not regnerating text -- check for element destroyed, or any mouse click?
   --o progressive spacing shrinking

   --o down arrow to switch to editting mode, keeping track of header text, header#
     --o save by sve.data.journal[header text][header #]
   --o on current search text or first non-PartHyperText_plain_text child
   --o arrow up/down moving to next/prev entry
   --o PartParagraphInput_text_input.text includes cursor
   --o Save edit to player data

   --o add dividers before/after active edit text
   --o shift-enter/[/] functionality, holding is good enough
   --o shift-arrow up/down to select topic edit
   --o shift-enter no enter for edit
   --o widen sveTextInputPopUp_Input (512) width / menubook_page_1 width (338)
   --o add search dividers, too
   --o strip | if pre-existing
   --? random memory pointer errors
   --x PartParagraphInput_text_input or PartParagraphInput_wrapped_text_holder?
   --x suppress enter or tab key on search
   -- suppress top search bar for first element
   --x suppress next/prev page search on key up (hammer key)
   --o suppress find on search string (self)??
   --o no quotes for search string
   
   --o check for hot keys onKeyDown, if hot then signal to onKeyPressed to ignore
   --o still occasional enter key errantly showing up?
   -- clean up some redundant menu = ...p
   --o stop/start sound every page turn
   --o check no key up during continuations

   --o need way to reset search on any button/hyper press except exit

   --x can keypress event data be used for hot keys?? - no, e.keyCode = nil
   --o latency dependence and optimization
   --o on-close button press refresh if not really exiting
   --o menu check on all events, latencies
   --o don't remove newlines from edited text

   --o don't display < during page flipping?
   --o referesh on auxiliary menu close
   
   --o flash indicator on search fail

   -- future add page mechanic:
      -- shift right arrow inserts a page between 17-18: 17a-18a
      -- new pages are populated with a standard date header and text element
      -- new journal text saved to journalEdits[page_number_1]["a"] and [page_number_1]["b"]
      -- whenever "next" increments to 17-18 then 17-17a, 18-18a are displayed
      -- by hiding/unhiding standard elements and adding/hiding new ones
      --

  -- only refresh if all matches are in the same element
  
  --o store table of hyperlink text elements on every page turn
  --o strip/restore hyperlink text elements on edit start/save
  
  -- not replacing \n in edit string?
  -- paragraph width defining up/down arrow jump
  --o pages with no header text inherit from last one defined

  --o Header text customizeable
  --o prev button on page 1
  --o mouse wheel detect on page 1 , Last
  --o page number 147+, 148-
  --o hyperLink inserted pages by hyperlink vs header text search
  --o repeatkeys = true on menu?
  --o use [,] for search prev,next
  --o new page header default to topic hyperText, if applicable
  --o topic hyperText,not normal text
  --o single page 2- header initially hidden ?? -- detected as subsequent one
  --o for insered page topics, default to entering the first page
  --o returning to the main journal, restore splitpage state
  --o capaitalize topic Headings
  --o customizable paragraph width
  --o continue search over inserted pages
  --o strip | before saving
  --o flipping back 2 pages on business topic split

  --o don't show 2+ if 2 is empty
  --o test sounds
  --o CTD on new game or reload seems due to UI Expansion
  --o topics entering second page, returning first page
  --o add existence checks after all UI element findChild, just in case destroyed
  --x suppress partial word hyperlinks, such as st*ring#
  --o suppress close menu key bind for ~pageTurnDelay to avoid tab->view change on close
  --o search original journal entries for new hypertext, and insert into edits
  --o image placement relative to header
  --o auto-image sizeing?
  --o adding to non-split page turn after initial page correct, multiple copies disabled.
  --o international language support (config)
  --o journalEdits.customImageScaling = { contentPath = "bk_guide_to_balmora", scale = 1.2 }
  -- flag and check for found new book art non-bsa