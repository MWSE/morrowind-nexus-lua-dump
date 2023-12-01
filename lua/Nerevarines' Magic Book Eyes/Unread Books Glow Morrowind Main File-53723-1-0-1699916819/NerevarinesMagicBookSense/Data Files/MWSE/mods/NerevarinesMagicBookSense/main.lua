


local currentBook
local effectEnchantment = nil
local firstTimeSetup = false
local function getData()
    if tes3.player then
        return tes3.player.data.glowBooks
    end
end

local function onLoad()
	if not(firstTimeSetup) then
		firstTimeSetup = true
		tes3.player.data.glowBooks = tes3.player.data.glowBooks or { }
		tes3.player.data.glowBooks.booksAlreadyRead = tes3.player.data.glowBooks.booksAlreadyRead or {}
	end
	
	for ref in tes3.player.cell:iterateReferences(tes3.objectType.book) do


		local wantedBook = ref.baseObject
		local bookwasRead;

		if(wantedBook.enchantment ~= nil) then
			return
		end
		effectEnchantment = tes3.getObject("distraction_en")
		
		if(wantedBook.script ~= nil) then
			effectEnchantment = tes3.getObject("blind_en")
		end
		
		if(wantedBook.skill >= 0) then
			effectEnchantment = tes3.getObject("fireheart_en")
		end
		
		for _, val in ipairs(getData().booksAlreadyRead) do
			if val.id == wantedBook.id then
				bookwasRead = true
			end
		end
	
		if not (bookwasRead) then
			if not(ref.sceneNode == nil) then
				tes3.worldController:applyEnchantEffect(ref.sceneNode, effectEnchantment)
				ref.sceneNode:updateEffects()
			end
		end
	end
end
event.register("loaded", onLoad)

-- Callback for when a new scene node is created for a reference.
-- We'll use it add a visual effect to trapped objects.
local function onReferenceActivated(e)
	if not(firstTimeSetup) then
		firstTimeSetup = true
		tes3.player.data.glowBooks = tes3.player.data.glowBooks or { }
		tes3.player.data.glowBooks.booksAlreadyRead = tes3.player.data.glowBooks.booksAlreadyRead or {}
	end


    local reference = e.reference
	if(reference.sceneNode == nil) then
		return
	end
    local wantedBook = e.reference.baseObject --- @cast book tes3book
	 if (wantedBook.objectType ~= tes3.objectType.book) then
        return
    end
	if(wantedBook.enchantment ~= nil) then
		return
	end
	
	
	local bookwasRead
	effectEnchantment = tes3.getObject("distraction_en")
	
	if(wantedBook.script ~= nil) then
			effectEnchantment = tes3.getObject("blind_en")
	end
		
	if(wantedBook.skill >= 0) then
		effectEnchantment = tes3.getObject("fireheart_en")
	end
	
	
	for _, val in ipairs(getData().booksAlreadyRead) do
			if val.id == wantedBook.id then
				bookwasRead = true
			end
	end

	if (bookwasRead) then
		reference.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
		reference.sceneNode:updateEffects()
		return;
	end
	
	if not(reference.sceneNode == nil) then
		tes3.worldController:applyEnchantEffect(reference.sceneNode, effectEnchantment)
		reference.sceneNode:updateEffects()
	end

end
event.register(tes3.event.referenceActivated, onReferenceActivated)


local function bookAlreadyRead()
    local hasRead
    for _, val in ipairs(getData().booksAlreadyRead) do
        if val.id == currentBook.id then
            hasRead = true
        end
    end
    return hasRead
end

local function checkBookActivate(e)
    if currentBook then
        local readList = getData().booksAlreadyRead
		if not bookAlreadyRead() then
			table.insert(readList, { id = currentBook.id, name = currentBook.name })
			if (currentBook.sceneNode ~= nil) then
				currentBook.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
				currentBook.sceneNode:updateEffects()
			end
		end
    end
end
event.register("uiActivated", checkBookActivate, { filter = "MenuBook"})


local function checkScrollActivate(e)
    if currentBook then
        local readList = getData().booksAlreadyRead
		if not bookAlreadyRead() then
			table.insert(readList, { id = currentBook.id, name = currentBook.name })
			if (currentBook.sceneNode ~= nil) then
				currentBook.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
				currentBook.sceneNode:updateEffects()
			end
		end
    end
end
event.register("uiActivated", checkScrollActivate, { filter = "MenuScroll"})


local function updateCurrentBook(e)
    currentBook = e.book
end
event.register("bookGetText", updateCurrentBook)



local function menuExitCallback(e)

	for _, cell in pairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences(tes3.objectType.book) do							
			
			local wantedBook = ref.baseObject
			local bookwasRead;
			if(wantedBook.enchantment ~= nil) then
				return
			end
			effectEnchantment = tes3.getObject("distraction_en")
			if(wantedBook.script ~= nil) then
				effectEnchantment = tes3.getObject("blind_en")
			end
			
			if(wantedBook.skill >= 0) then
				effectEnchantment = tes3.getObject("fireheart_en")
			end
			

			
			for _, val in ipairs(getData().booksAlreadyRead) do
				if val.id == wantedBook.id then
					bookwasRead = true
				end
			end

			if (bookwasRead) then
					if not(ref.sceneNode == nil) then
						ref.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
						ref.sceneNode:updateEffects()
					end
			else
				if not(ref.sceneNode == nil) then
						tes3.worldController:applyEnchantEffect(ref.sceneNode, effectEnchantment)
						ref.sceneNode:updateEffects()
				end		
			end
		end
	end
	for ref in tes3.player.cell:iterateReferences(tes3.objectType.book) do


		local wantedBook = ref.baseObject
		local bookwasRead;

		if(wantedBook.enchantment ~= nil) then
			return
		end
		effectEnchantment = tes3.getObject("distraction_en")
		
		if(wantedBook.script ~= nil) then
			effectEnchantment = tes3.getObject("blind_en")
		end
		
		if(wantedBook.skill >= 0) then
			effectEnchantment = tes3.getObject("fireheart_en")
		end
		
		for _, val in ipairs(getData().booksAlreadyRead) do
			if val.id == wantedBook.id then
				bookwasRead = true
			end
		end
	
		if (bookwasRead) then
			if not(ref.sceneNode == nil) then
				ref.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
				ref.sceneNode:updateEffects()
			end
		else
			if not(ref.sceneNode == nil) then
				tes3.worldController:applyEnchantEffect(ref.sceneNode, effectEnchantment)
				ref.sceneNode:updateEffects()
			end		
		end
			
	end
	if(currentBook ~= nil) then
		if (currentBook.sceneNode ~= nil) then
			currentBook.sceneNode:detachEffect(tes3.worldController.enchantedItemEffect)
			currentBook.sceneNode:updateEffects()
		end
	end

end

event.register(tes3.event.menuExit, menuExitCallback)

