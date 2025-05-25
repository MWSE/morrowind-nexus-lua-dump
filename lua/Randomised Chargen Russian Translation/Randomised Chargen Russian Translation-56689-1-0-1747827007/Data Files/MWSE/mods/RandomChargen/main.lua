local rerollText = "Случайный"
local randomText = "Случай."
local rerollAllText = "Случайный выбор всех параметров"

local birthsignScrollUIID = tes3ui.registerID("MenuBirthSign_BirthSignScroll")
local classScrollUIID = tes3ui.registerID("MenuChooseClass_ClassScroll")
local raceListUIID = tes3ui.registerID("MenuRaceSex_RaceList")
local sexButtonUIID = tes3ui.registerID("MenuRaceSex_ChangeSexbuttonBack")
local faceButtonUIID = tes3ui.registerID("MenuRaceSex_ChangeFacebuttonBack")
local hairButtonUIID = tes3ui.registerID("MenuRaceSex_ChangeHairbuttonBack")

local function getRandomListElement(list)
	return list:getContentElement().children[math.random(#list:getContentElement().children)]
end

local function scrollToSelectedElement(list, element)
	local i = 1
	local elementIndex
	local totalHeight = 0
	for _, child in ipairs(list:getContentElement().children) do
		if child == element then
			elementIndex = i
		end
		totalHeight = totalHeight + child.height
		i = i + 1
	end
	if elementIndex then
		list.widget.positionY = ((totalHeight / #list:getContentElement().children) * elementIndex) - element.height
	end
end

local function onMenuChooseClass(e)
	local rand = e.element:createButton{text = rerollText}
	rand.absolutePosAlignX = 0
	rand.absolutePosAlignY = 1
	rand.borderAllSides = 14
	rand:register("mouseClick", function()
		local pick = getRandomListElement(e.element:findChild(classScrollUIID))
		scrollToSelectedElement(e.element:findChild(classScrollUIID), pick)
		pick:triggerEvent("mouseClick")
	end)
	e.element:updateLayout()
end
event.register("uiActivated", onMenuChooseClass, {filter = "MenuChooseClass"})

local function onMenuBirthSign(e)
	local rand = e.element:createButton{text = rerollText}
	rand.absolutePosAlignX = 0
	rand.absolutePosAlignY = 1
	rand.borderAllSides = 12
	rand:register("mouseClick", function()
		local pick = getRandomListElement(e.element:findChild(birthsignScrollUIID))
		scrollToSelectedElement(e.element:findChild(birthsignScrollUIID), pick)
		pick:triggerEvent("mouseClick")
	end)
	e.element:updateLayout()
end
event.register("uiActivated", onMenuBirthSign, {filter = "MenuBirthSign"})

local function onMenuRaceSex(e)
	-- Randomize Race Button
	local rand = e.element:createButton{text = rerollAllText}
	rand.absolutePosAlignX = 0
	rand.absolutePosAlignY = 1
	rand.borderAllSides = 14
	rand:register("mouseClick", function()
		local pick = getRandomListElement(e.element:findChild(raceListUIID))
		scrollToSelectedElement(e.element:findChild(raceListUIID), pick)
		pick.children[1]:triggerEvent("mouseClick")
		if math.random(2) > 1 then
			e.element:findChild(sexButtonUIID):triggerEvent("mouseClick")
		end
		for _ = 1, math.random(64) do
			e.element:findChild(faceButtonUIID):triggerEvent("mouseClick")
			e.element:findChild(hairButtonUIID):triggerEvent("mouseClick")
		end
	end)

	-- Randomize Sex Button
	local block = e.element:findChild(sexButtonUIID).parent
	rand = block:createButton{text = randomText}
	rand.borderAllSides = 0
	rand:register("mouseClick", function()
		if math.random(2) > 1 then
			e.element:findChild(sexButtonUIID):triggerEvent("mouseClick")
		end
	end)

	-- Randomize Face Button
	block = e.element:findChild(faceButtonUIID).parent
	rand = block:createButton{text = randomText}
	rand.borderAllSides = 0
	rand:register("mouseClick", function()
		for _ = 1, math.random(64) do
			e.element:findChild(faceButtonUIID):triggerEvent("mouseClick")
		end
	end)

	-- Randomize Hair Button
	block = e.element:findChild(hairButtonUIID).parent
	rand = block:createButton{text = randomText}
	rand.borderAllSides = 0
	rand:register("mouseClick", function()
		for _ = 1, math.random(64) do
			e.element:findChild(hairButtonUIID):triggerEvent("mouseClick")
		end
	end)
end
event.register("uiActivated", onMenuRaceSex, {filter = "MenuRaceSex"})