	
-- to do : support 2 modifier keys for killkey
-- to do : long GMST stings
-- disabled NPCs
-- hud turns on when menu is opened
-- find cell name with coord
-- scroll pages
-- weather in int cells

local modConfigMenu = {};
local pane;
local mb = tes3.messageBox;
local log = mwse.log;
local iNPCtype = tes3.objectType.npc;
local iCreatureType = tes3.objectType.creature;
local iContainerType = tes3.objectType.container;
local iDoorType = tes3.objectType.door;
local tMainAttributes = {health = 'Health', magicka = 'Magicka', fatigue = 'Fatigue', encumbrance = 'Encumbrance'};
local menuTabs = {};
local tItemList = {};
local tItemButtons = {};
local tSoulGemList = {};
local tCreatureList = {};
local tWeatherList = {};
local weatherController;
local tCreatureBlocks = {};
local tPlayerAttributes = {};
local tPlayerSkills = {};
local tSpellList = {};
local tSpellButtons = {};
local tPlayerSpellButtons = {};
local tCellList = {}; 
local tCellButtons = {};
local tNPClist = {}; 
local tNPCbuttons = {};
local tGMSTs = {};
local tGMSTbuttons = {}; 
local tkeyPressFuctions = {};
local tFactionList = {}; 
local tFactionButtons = {};
local tPlayerFactionButtons = {};
local hud;
local itemScrollable;
local leftSpellScrollable;
local rightSpellScrollable;
local cellRightScrollable;
local cellLeftScrollable;
local gmstScrollable;


local config = {godMode = false, collision = true, fow = true, ai = true, wireframe = false, vanityMode = false, autoUnlock = false, soulGem, itemCount = 1, hud = true};

local savedConfig = mwse.loadConfig('CheatMenuConfig');
if not savedConfig or (savedConfig and not savedConfig.killHostilesKey) then
	savedConfig = {killKey = {keyCode = tes3.scanCode.k, isShiftDown = true, isAltDown = false, isControlDown = false}, killHostilesKey = {keyCode = tes3.scanCode.l, isShiftDown = true, isAltDown = false, isControlDown = false}};
end

local functions = require('CheatMenu.functions');
functions.savedConfig = savedConfig;
functions.config = config;
functions.tkeyPressFuctions = tkeyPressFuctions;

local SortByName = function(a,b) return a.name < b.name; end


local function NormalizeToRange(iValue, iOldMin, iOldMax, iNewMin, iNewMax)
    
	local iOldRange = iOldMax - iOldMin;
	local iNewValue;

	if iOldRange == 0 then
		iNewValue = iNewMin;
	else
		local iNewRange = iNewMax - iNewMin;
		iNewValue = ((iValue - iOldMin) * iNewRange) / iOldRange + iNewMin;
	end

	return math.floor(iNewValue);
end


local function FindUIelement(t, n)
	
	n = n:lower();

	for i, v in pairs(t) do
		-- log('FindUIelement %s %s', v.name, v.parent.name);
		if v.name and v.name:lower() == n then
			-- v:triggerEvent('mouseScrollDown');
			-- v:triggerEvent('mouseScrollUp');
			log('found %s', n);
			return v;
		elseif v.text and string.len(v.text) > 0 then
			v.text = v.text:lower();
			-- if string.find(v.text, n, 1, true) or string.find(v.text, '%name', 1, true) then
				-- log('FindUIelement found %s %s', v, v.text );
					-- v.visible = false;
			-- return v;
			-- end
		end
		if v.children then
	        local e = FindUIelement(v.children, n);
            if e then
                return e;
            end
		end
	end
end


local function PairsByKeys (t, f)
-- this is 9 times faster than table.sort
	local a = {};
	for n in pairs(t) do
		table.insert(a, n);
	end
	table.sort(a, f);
	local i = 0;      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1;
		if a[i] == nil then
			return nil;
		else 
			return a[i], t[a[i]];
		end
	end
	return iter;
end


local function GetCellName(cell) 

	local sCellName = cell.id;
	if not cell.isInterior then
		sCellName = sCellName..' '..cell.gridX..' '..cell.gridY;
	end
	return sCellName;
end


local function MakeCellList()

	local t = {};
    for k, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
		t[GetCellName(cell)] = cell;
		-- table.insert(tCellList, cell);
		-- log(' %s ', GetCellName(cell));
	end
	-- local SortCellsByName = function(a,b) return GetCellName(a) < GetCellName(b) ; end
	-- table.sort(tCellList, SortCellsByName);
	for name, cell in PairsByKeys(t) do
		table.insert(tCellList, cell);
	end
end


local function MakeNPClist()

	local t = {};
	for NPC in tes3.iterateObjects(tes3.objectType.npc) do
		-- log('%s    %s', NPC, NPC.name );
		-- table.insert(tNPClist, obj);
		t[NPC.name] = NPC;
	end
	-- table.sort(tNPClist, SortByName);
	for name, NPC in PairsByKeys(t) do
		table.insert(tNPClist, NPC);
	end
end


local function MakeWeatherList()
	-- tWeatherList = {};
	for weather, val in PairsByKeys(tes3.weather) do
		-- log('%s %s', weather, val);
		table.insert(tWeatherList, {label = weather, value = val});
	end
	-- log('CurrentWeather  %s', tes3.getCurrentWeather().index);
end


local function MakeItemList()

    for obj in tes3.iterateObjects(tes3.objectType.weapon) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.armor) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.apparatus) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.book) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.alchemy) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.lockpick) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.probe) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.ingredient) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.miscItem) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.repairItem) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.clothing) do
		table.insert(tItemList, obj);
	end
    for obj in tes3.iterateObjects(tes3.objectType.light) do
		if obj.canCarry then
			table.insert(tItemList, obj);
		end
	end
    for obj in tes3.iterateObjects(tes3.objectType.ammunition) do
		table.insert(tItemList, obj);
	end

	table.sort(tItemList, SortByName);
end


local function MakeSoulGemList()

    for obj in tes3.iterateObjects(tes3.objectType.miscItem) do
		if obj.isSoulGem then
			-- log('%s %s', obj.name, obj.id);
			table.insert(tSoulGemList, {label = obj.name, value = obj.id});
		end
	end
	config.soulGem = tSoulGemList[#tSoulGemList-1].value;
end


local function MakeCreatureList()

    for obj in tes3.iterateObjects(tes3.objectType.creature) do
		if obj.soul > 0 and obj.name and string.len(obj.name) > 0 then
			-- log('%s   %s  %d', obj, obj.name, obj.cloneCount);
			if not tCreatureList[obj.name] or obj.soul > tCreatureList[obj.name].soul then
				tCreatureList[obj.name] = obj;
			end
		end
	end
	-- table.sort(tCreatureList, SortByName);

	-- for name, creature in PairsByKeys(t) do
		-- table.insert(tCreatureList, creature);
	-- end
end


local function MakeSpellList()

	local t = {};
    for spell, v in tes3.iterateObjects(tes3.objectType.spell) do
    -- for k, spell in pairs(tes3.dataHandler.nonDynamicData.spells) do
			-- log('spell  %s   %s ', spell, v);
		if string.len(spell.name) > 0 then
			t[spell.name] = spell;
			-- table.insert(tSpellList, spell);
		-- else
			-- log('duplicate spell name %s %s ', spell.name, spell.id);
		end
	end

	-- table.sort(tSpellList, SortByName);
	for name, spell in PairsByKeys(t) do
		table.insert(tSpellList, spell);
	end
end


local function GetPlayerSpells()
	
	for spell, button in pairs(tPlayerSpellButtons) do		
		if tes3.player.object.spells:contains(spell) then
			button.visible = true;
		-- else
			-- button.visible = false;
		end
	end
end


local function FindSpell(str)

	local iFoundSpells = 0;
	for i, button in pairs(tSpellButtons) do
		if button.text and string.find(button.text:lower(), str:lower()) then
			-- log(' found button %s ', button.buttonText);
			button.visible = true;
			iFoundSpells = iFoundSpells + 1;
		else
			button.visible = false;
		end
	end
	if iFoundSpells > 0 then
		mb('Found %s spells', iFoundSpells);
		timer.frame.delayOneFrame(function() timer.frame.delayOneFrame(function() leftSpellScrollable.widget.positionY = 0; end); end);
	end
end


local function FindCreature(str)

	local iFoundCreatures = 0;
	if string.len(str) > 0 then	
		for name, block in pairs(tCreatureBlocks) do
			-- log('FindCreature name  %s  %s', name, str);
			if string.find(name:lower(), str:lower()) then
				-- log(' found button %s ', button.buttonText);
				block.visible = true;
				iFoundCreatures = iFoundCreatures + 1;
			else
				block.visible = false;
			end
		end
	end
	if iFoundCreatures > 0 then
		mb('Found %s creatures', iFoundCreatures);
	end
end


local function KillPlayerTarget(e)
	if not tes3.menuMode() then -- dont kill service provider when naming custom spell
		-- mb('KillPlayerTarget %s', e.keyCode);
		local bKillKey = false;
		if e.isShiftDown and savedConfig.killKey.isShiftDown then
			bKillKey = true;
		elseif e.isAltDown and savedConfig.killKey.isAltDown then
			bKillKey = true;
		elseif e.isControlDown and savedConfig.killKey.isControlDown then
			bKillKey = true;
		elseif not e.isControlDown and not savedConfig.killKey.isControlDown and not e.isShiftDown and not savedConfig.killKey.isShiftDown and not e.isAltDown and not savedConfig.killKey.isAltDown then
			bKillKey = true;
		end

		if not bKillKey then
			return;
		end

		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			local iType = rayhit.reference.object.objectType;
			if iType == iNPCtype or iType == iCreatureType then
				mb("Killed  %s", rayhit.reference.object.name);
				tes3.setStatistic {reference = rayhit.reference, name = "health", current = 0};
			end
		end
	end
end
tkeyPressFuctions['killKey'] = KillPlayerTarget;


local function KillHostiles(e)

	local bKillKey = false;
	if e.isShiftDown and savedConfig.killKey.isShiftDown then
		bKillKey = true;
	elseif e.isAltDown and savedConfig.killKey.isAltDown then
		bKillKey = true;
	elseif e.isControlDown and savedConfig.killKey.isControlDown then
		bKillKey = true;
	elseif not e.isControlDown and not savedConfig.killKey.isControlDown and not e.isShiftDown and not savedConfig.killKey.isShiftDown and not e.isAltDown and not savedConfig.killKey.isAltDown then
		bKillKey = true;
	end
	if not bKillKey then
		return;
	end

	for actor in tes3.iterate(tes3.mobilePlayer.hostileActors) do
		-- log('hostileActor  %s', actor.reference.id);
		mb("Killed  %s", actor.object.name);
		tes3.setStatistic {reference = actor.reference, name = "health", current = 0};
	end
end
tkeyPressFuctions['killHostilesKey'] = KillHostiles;


local function FindItem(str, parent)
	-- mb('pp.autoHeight %s', pp.autoHeight);
	local iFoundItems = 0;
	if string.len(str) > 0 then
		for i, element in pairs(tItemButtons) do

			if element.text and string.find(element.text:lower(), str:lower()) then
				-- log(' found element %s ', element.buttonText);
				element.visible = true;
				iFoundItems = iFoundItems + 1;
			else
				element.visible = false;
			end
		end
	end
	-- PartScrollBar_bar_back   PartScrollBar_elevator
	if iFoundItems > 0 then
		mb('Found %s items', iFoundItems);
		-- reset scroller position and fix locked scrolling
		timer.frame.delayOneFrame(function() timer.frame.delayOneFrame(function() itemScrollable.widget.positionY = 0; end); end);
	end
end


local function FindCell(str)

	local iFoundCells = 0;
	for i, button in pairs(tCellButtons) do
		if button.text and string.find(button.text:lower(), str:lower()) then
			-- log(' found button %s ', button.buttonText);
			button.visible = true;
			iFoundCells = iFoundCells + 1;
		else
			button.visible = false;
		end
	end
	if iFoundCells > 0 then
		mb('Found %s cells', iFoundCells);
		timer.frame.delayOneFrame(function() timer.frame.delayOneFrame(function() cellLeftScrollable.widget.positionY = 0; end); end);
	end
end


local function FindDoorMarker(cell)

	for ref in cell:iterateReferences(tes3.objectType.static) do
		if ref.object.id == 'DoorMarker' then
			return ref;
		end
	end
end


local function TeleportToCell(cell)

	if cell.isInterior then
		local doorMarkerRef = FindDoorMarker(cell);
		if doorMarkerRef then
			tes3.positionCell{cell = cell, position = doorMarkerRef.position, orientation = doorMarkerRef.orientation};
		end
	else
		local xPos = cell.gridX * 8192;
		local yPos = cell.gridY * 8192;
		mwscript.positionCell{reference = tes3.player, cell = cell.id, x = xPos, y = yPos};
	end
	-- tes3ui.leaveMenuMode();
	tes3.pushKey(tes3.scanCode.escape);
	timer.frame.delayOneFrame(function() tes3.releaseKey(tes3.scanCode.escape); end);
end


local function TeleportToNPC(id)

	local ref = tes3.getReference(id);
	if ref then
		tes3.positionCell{cell = ref.cell, position = ref.position};
		tes3.pushKey(tes3.scanCode.escape);
		timer.frame.delayOneFrame(function() tes3.releaseKey(tes3.scanCode.escape); end);
	else
		log('could not teleport to  %s', id);
	end
end


local function FindNPC(str)

	local iNPCsFound = 0;
	for i, button in pairs(tNPCbuttons) do
		if button.text and string.find(button.text:lower(), str:lower()) then
			-- log(' found button %s ', button.buttonText);
			button.visible = true;
			iNPCsFound = iNPCsFound + 1;
		else
			button.visible = false;
		end
	end
	if iNPCsFound > 0 then
		mb('Found %s NPCs', iNPCsFound);
		timer.frame.delayOneFrame(function() timer.frame.delayOneFrame(function() cellRightScrollable.widget.positionY = 0; end); end);
	end
end


local function FindGMST(str)

	local iGMSTsFound = 0;
	str = str:lower();
	for i, block in pairs(tGMSTbuttons) do
		-- log('block.children[1].text %s ', block.children[1].text);
		local gmstName = block.children[1].text;
		if gmstName and string.find(gmstName:lower(), str) then
			block.visible = true;
			iGMSTsFound = iGMSTsFound + 1;
		else
			block.visible = false;
		end
	end
	if iGMSTsFound > 0 then
		mb('Found %s GMSTs', iGMSTsFound);
		timer.frame.delayOneFrame(function() timer.frame.delayOneFrame(function() gmstScrollable.widget.positionY = 0; end); end);
	end
end


local function SetStat(name, newVal)
	local int = tonumber(newVal);
	if int then
		mb('%s set to %d', name, int);
		tes3.setStatistic {reference = tes3.player, name = name, current = int};
	else
		mb('Type in a number');
	end
end


local function GetStat(name) 
	-- mb('GetSkill %s', tes3.mobilePlayer[name].current);
	-- if not savedStats[name] then 
		-- savedStats[name] = math.floor(tes3.mobilePlayer[name].base);
	-- end 
	return math.floor(tes3.mobilePlayer[name].current);
end


local function SetSkill(index, str)
	local int = tonumber(str);
	if int then
		mb('%s set to %d', tes3.getSkillName(index), int);
		tes3.setStatistic {reference = tes3.player, skill = index, value = int};
	else
		mb('Type in a number');
	end
end


local function MakePlayerAttributesList()
	for name, index in PairsByKeys(tes3.attribute) do
		table.insert(tPlayerAttributes, name);
	end
	for name_, index_ in PairsByKeys(tes3.skill) do
		table.insert(tPlayerSkills, {name = name_, index = index_});
	end
end


local function CreateCheatsPage(cheatsButton)
	local cheatsPage, cheatsLeftPage, cheatsRightPage = functions.CreateCategoryPage(pane, nil, nil, 15, 15); 			

	functions.CreateYesNoButton(cheatsLeftPage, 'HUD', 'hud', function()
		hud.visible = not hud.visible; end);
	functions.CreateYesNoButton(cheatsLeftPage, 'God Mode', 'godMode', function()
		tes3.runLegacyScript({command = 'tgm'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'Collisions', 'collision', function()
		tes3.runLegacyScript({command = 'tcl'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'Fog of War on Local Map', 'fow', function()
		tes3.runLegacyScript({command = 'tfow'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'NPC and Creature AI', 'ai', function()
		tes3.runLegacyScript({command = 'tai'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'Wireframe mode', 'wireframe', function()
		tes3.runLegacyScript({command = 'twf'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'Vanity mode', 'vanityMode', function()
		tes3.runLegacyScript({command = 'tvm'}); end);
	functions.CreateYesNoButton(cheatsLeftPage, 'Auto Unlock Doors and Containers', 'autoUnlock', function(e)	end);
	functions.CreateButton(cheatsLeftPage, 'Reset Actors', function()
		tes3.runLegacyScript({command = 'ra'}); end);
	functions.CreateButton(cheatsLeftPage, 'Show Every World Map Marker', function()
		tes3.runLegacyScript({command = 'FillMap'}); end);
	functions.CreateButton(cheatsLeftPage, 'Add Every Journal Entry', function()
		mb('This takes some time'); tes3.runLegacyScript({command = 'FillJournal'}) end);
	functions.CreateButton(cheatsLeftPage, 'Character Generation Menu', function()
		 tes3.runLegacyScript({command = 'EnableStatReviewMenu'}) end);
	functions.CreateButton(cheatsLeftPage, 'Remove Player Bounty', function()
		 tes3.runLegacyScript({command = 'SetPCCrimeLevel 0'}) end);

	functions.CreateDropdown(cheatsRightPage, 'Current Weather', tWeatherList, tes3.getCurrentWeather().index, function(newVal) weatherController:switchImmediate(newVal); end);

	-- cheatsRightPage:createLabel{text = 'below dropdownList'};
-- CreateTextInput(page, label, onlyNumbers, initialValue, callback)
	functions.CreateTextInput(cheatsRightPage, 'Time Scale', true, tes3.getGlobal('timescale'), function(newVal) mb('Time scale set to %s', newVal); tes3.setGlobal('timescale', tonumber(newVal)); end);

	functions.CreateKeyBinder(cheatsRightPage, 'Key to kill player target', 'killKey');
	functions.CreateKeyBinder(cheatsRightPage, 'Key to kill every hostile', 'killHostilesKey');
	-- functions.CreateKeyBinder(cheatsRightPage, 'Key to toggle HUD', 'toggleHUDkey');

	menuTabs[cheatsButton] = cheatsPage;
end


local function CreateStatsPage(statsButton)

	local statsPage, statsLeftPage, statsRightPage = functions.CreateCategoryPage(pane, nil, nil, 12);
	menuTabs[statsButton] = statsPage;

	for name, uiName in pairs(tMainAttributes) do
		functions.CreateTextInput(statsLeftPage, uiName, true, GetStat(name), function(newVal) SetStat(name, newVal); end);
	end

	statsLeftPage:createLabel{text = ''};

	for k, name in ipairs(tPlayerAttributes) do
		functions.CreateTextInput(statsLeftPage, name, true, GetStat(name), function(newVal) SetStat(name, newVal); end);
	end

	local rightScrollable = functions.CreateScrollPane(statsRightPage);

	for k, skillData in ipairs(tPlayerSkills) do
		functions.CreateTextInput(rightScrollable, skillData.name, true, GetStat(skillData.name), function(newVal) SetSkill(skillData.index, newVal); end);
	end
end


local function CreateItemsPage(itemsButton)

	local itemsPage, itemsLeftPage, itemsRightPage = functions.CreateCategoryPage(pane, 'Add an item to your inventory', 'Add a filled soulgem to your inventory');
	menuTabs[itemsButton] = itemsPage;
	-- page:createLabel{text = label};
	local leftBlock = itemsLeftPage:createBlock();
	leftBlock.flowDirection = 'top_to_bottom';
	-- leftBlock.flowDirection = 'left_to_right';
	leftBlock.autoWidth = true;
	leftBlock.autoHeight = true;
	-- leftBlock.paddingAllSides = 12;
	leftBlock.paddingTop = 12;
	leftBlock.paddingLeft = 12;
	-- local leftBlockLabel = leftBlock:createLabel{text = 'Add an item to your inventory'};
	-- leftBlockLabel.borderBottom = 11;
	functions.CreateTextInput(leftBlock, 'Item to find:', false, 'Type in a name', function(newVal) FindItem(newVal); end);

-- CreateSlider(page, label, configKey, sliderMin, sliderRange, sliderWidth)
	functions.CreateSlider(leftBlock, 'Item quantity', 'itemCount', 1, 99, 255);

	itemScrollable = functions.CreateScrollPane(itemsLeftPage);
	tItemButtons = {};
	for k, obj in ipairs(tItemList) do
		-- log(' %s %s ', name, spell.id);
		local element = functions.CreateSelectable(itemScrollable, obj.name, function() mb("%s added to your inventory.", obj.name); tes3.addItem{reference = tes3.player, item = obj, count = config.itemCount, playSound = false} end);
		element.visible = false;
		table.insert(tItemButtons, element);
	end
	-- itemScrollable.visible = false;

	local RightBlock = itemsRightPage:createBlock();
	RightBlock.flowDirection = 'top_to_bottom';
	RightBlock.autoWidth = true;
	RightBlock.autoHeight = true;
	-- RightBlock.paddingAllSides = 12;
	RightBlock.paddingTop = 12;
	RightBlock.paddingLeft = 12;
-- CreateDropdown(page, label, list, defaultOption, callback)
	-- rightBlockLabel = RightBlock:createLabel{text = 'Add a filled soulgem to your inventory'};
	-- rightBlockLabel.borderBottom = 11;
	functions.CreateDropdown(RightBlock, 'Soul Gem', tSoulGemList, config.soulGem, function(newVal) config.soulGem = newVal; end)
-- CreateTextInput(page, label, onlyNumbers, initialValue, callback)
	functions.CreateTextInput(RightBlock, 'Creature to place in soulgem:', false, 'Type in a name', function(newVal) FindCreature(newVal); end);

	local rightScrollable = functions.CreateScrollPane(itemsRightPage);

	for name, creature in pairs(tCreatureList) do
		-- log('creature.soul %s', creature.soul);
		local block = rightScrollable:createBlock();
		block.flowDirection = 'left_to_right';
		block.autoWidth = true;
		block.autoHeight = true;
		local element = functions.CreateSelectable(block, name, function() mb('Soulgem with soul of %s added to your inventory', name); mwscript.addSoulGem{reference = tes3.player, creature = creature.id, soulgem = config.soulGem}; end);
		block.visible = false;
		element.borderRight = 16;
		block:createLabel{text = tostring(creature.soul)};
		tCreatureBlocks[name] = block;
	end
end


local function CreateSpellsPage(spellsButton)

	local spellsPage, spellsLeftPage, spellsRightPage = functions.CreateCategoryPage(pane, 'Add a spell to your spell list', 'Remove a spell from your spell list');
	menuTabs[spellsButton] = spellsPage;
	-- local leftBlockLabel = leftBlock:createLabel{text = 'Add an item to your inventory'};
	-- leftBlockLabel.borderBottom = 11;
	local inputField = functions.CreateTextInput(spellsLeftPage, 'Spell to find:', false, 'Type in a name', function(newVal) FindSpell(newVal); end);
	inputField.paddingLeft = 12;
	inputField.paddingTop = 12;

	leftSpellScrollable = functions.CreateScrollPane(spellsLeftPage);
	rightSpellScrollable = functions.CreateScrollPane(spellsRightPage);
	rightSpellScrollable.borderTop = 11;
	tSpellButtons = {};
	tPlayerSpellButtons = {};
	
	for k, spell in pairs(tSpellList) do
		-- log(' %s %s ', name, spell.id);
		local element = functions.CreateSelectable(leftSpellScrollable, spell.name, function() mb('%s added to your spell list.', spell.name); mwscript.addSpell{reference = tes3.player, spell = spell}; tPlayerSpellButtons[spell].visible = true; end);
		element.visible = false;
		tSpellButtons[spell] = element;

		local element1 = functions.CreateSelectable(rightSpellScrollable, spell.name, function() mb('%s removed from your spell list.', spell.name); mwscript.removeSpell{reference = tes3.player, spell = spell}; tPlayerSpellButtons[spell].visible = false; end);
		element1.visible = false;
		tPlayerSpellButtons[spell] = element1;
	end

	GetPlayerSpells();
end


local function CreateTeleportPage(teleportButton);

	local teleportPage, teleportLeftPage, teleportRightPage = functions.CreateCategoryPage(pane);
	menuTabs[teleportButton] = teleportPage;

	local cellInputField = functions.CreateTextInput(teleportLeftPage, 'Teleport to cell:', false, 'Type in a name', function(newVal) FindCell(newVal); end);
	cellInputField.paddingLeft = 12;
	cellInputField.paddingTop = 12;

	cellLeftScrollable = functions.CreateScrollPane(teleportLeftPage);
	tCellButtons = {};
	tNPCbuttons = {};

	for k, cell in pairs(tCellList) do
		local name = GetCellName(cell);
		local element = functions.CreateSelectable(cellLeftScrollable, name, function() TeleportToCell(cell); end);
		element.visible = false;
		table.insert(tCellButtons, element);
	end

	local NPCinputField = functions.CreateTextInput(teleportRightPage, 'Teleport to NPC:', false, 'Type in a name', function(newVal) FindNPC(newVal); end);
	NPCinputField.paddingLeft = 12;
	NPCinputField.paddingTop = 12;
	cellRightScrollable = functions.CreateScrollPane(teleportRightPage);

	for k, NPC in pairs(tNPClist) do
		local element = functions.CreateSelectable(cellRightScrollable, NPC.name, function() TeleportToNPC(NPC.id); end);
		element.visible = false;
		table.insert(tNPCbuttons, element);
	end
end


local function CreateGMSTlist()

	for name_, index in PairsByKeys(tes3.gmst) do
		local gmst_ = tes3.findGMST(index);
        if name_ and gmst_ then
	        -- log("%s: %s", name_, gmst_.id)
			table.insert(tGMSTs, gmst_);
	    end
    end
end



local function SetGMST(gmst, newValue);

	if gmst.type == 's' then
		gmst.value = newValue;
	elseif gmst.type == 'i' then
		gmst.value = math.floor(tonumber(newValue));
	else
		gmst.value = tonumber(newValue);
    end
	mb('%s set to %s', gmst.id, gmst.value);
end


local function CreateGMSTpage(gmstButton);

	local gmstPage, gmstLeftPage = functions.CreateCategoryPageSingle(pane);
	menuTabs[gmstButton] = gmstPage;

	local findGMSTfield = functions.CreateTextInput(gmstLeftPage, 'Game setting to find:', false, 'Type in a gmst ID', function(newVal) FindGMST(newVal); end);
	findGMSTfield.paddingLeft = 12;
	findGMSTfield.paddingTop = 12;
	gmstScrollable = functions.CreateScrollPane(gmstLeftPage);

	tGMSTbuttons = {};
	for _, gmst in ipairs(tGMSTs) do
		local bStringGMST = gmst.type == 's';
		-- log('%s bStringGMST %s', gmstData.name, bStringGMST);
		-- if bStringGMST and string.len(gmst.value) > 22 then
			-- inputFieldBlock = functions.CreateParagraphInput(gmstScrollable, gmst.id, not bStringGMST, gmst.value, function(newVal) SetGMST(gmst, newVal); end);
		-- else
		local inputFieldBlock = functions.CreateTextInput(gmstScrollable, gmst.id, not bStringGMST, gmst.value, function(newVal) SetGMST(gmst, newVal); end);

		inputFieldBlock.visible = false;
		table.insert(tGMSTbuttons, inputFieldBlock);
	end
end


local function GetNumRanks(faction);

	local iNumRanks = 0;
	for k, rank in pairs(faction.ranks) do
		if rank.attributes[1] > 0 then
			iNumRanks = iNumRanks + 1;
		end
	end
	-- log('%s  %s', faction.id, iNumRanks);
	return iNumRanks;
end


local function CreateFactionlist()

	local t = {}
	for k, faction in pairs(tes3.dataHandler.nonDynamicData.factions) do
		-- GetNumRanks(faction);
		-- mwse.log('%s    %s', faction.id, faction.name);
		t[faction.name] = faction;
    end
	for name, faction in PairsByKeys(t) do
		table.insert(tFactionList, faction);
    end
end


local function JoinFaction(faction);

	-- mb('JoinFaction %s', faction.playerJoined);
	local raiseRankButton = tPlayerFactionButtons[faction.id].children[2].children[3];
	local lowerRankButton = tPlayerFactionButtons[faction.id].children[2].children[2];
	local rankLabel = tPlayerFactionButtons[faction.id].children[2].children[1];

	if not faction.playerJoined then
		lowerRankButton.text = 'Leave faction';
		tFactionButtons[faction.id].visible = false;
		tPlayerFactionButtons[faction.id].visible = true;
		local sCommand = 'PCJoinFaction "'..faction.id..'"';
		tes3.runLegacyScript{command = sCommand};
	elseif faction.playerExpelled then
		faction.playerExpelled = false;
		raiseRankButton.text = 'Raise rank';
		lowerRankButton.visible = true;	
	end
	mb('You joined %s', faction.name);
	rankLabel.text = 'current rank: '..tostring(faction.playerRank);
	if GetNumRanks(faction) == 0 then
		raiseRankButton.visible = false;
	end
end


local function LowerRank(faction, rankText);
	-- mb('%s %s', faction.id, faction.playerRank);
	if faction.playerJoined then
		local lowerRankButton = tPlayerFactionButtons[faction.id].children[2].children[2];
		local raiseRankButton = tPlayerFactionButtons[faction.id].children[2].children[3];

		if faction.playerRank > 0 then
			local sCommand = 'PCLowerRank "'..faction.id..'"';
			tes3.runLegacyScript{command = sCommand};
			rankText.text = 'current rank: '..tostring(faction.playerRank);
		else
			if tes3.hasCodePatchFeature(100) then -- faction leaving
				local sCommand = 'PCLowerRank "'..faction.id..'"';
				tes3.runLegacyScript{command = sCommand};
				mb('You left %s', faction.name);
				tFactionButtons[faction.id].visible = true;
				tPlayerFactionButtons[faction.id].visible = false;
			else 
				local sCommand = 'PCExpell "'..faction.id..'"';
				tes3.runLegacyScript{command = sCommand};
				rankText.text = 'current rank: expelled';
				lowerRankButton.visible = false;
				raiseRankButton.text = 'Join faction';
			end
			-- log('playerJoined %s playerExpelled %s', faction.playerJoined, faction.playerExpelled);

		end

		raiseRankButton.visible = true;

		if faction.playerRank == 0 then
			lowerRankButton.text = 'Leave faction';
		end
	end
end


local function RaiseRank(faction, rankText);

	if faction.playerJoined then
		local lowerRankButton = tPlayerFactionButtons[faction.id].children[2].children[2];
		local raiseRankButton = tPlayerFactionButtons[faction.id].children[2].children[3];

		if faction.playerExpelled then
			JoinFaction(faction);
		else
			local sCommand = 'PCRaiseRank "'..faction.id..'"';
			tes3.runLegacyScript{command = sCommand};
			if GetNumRanks(faction) == 0 or #faction.ranks - 1 == faction.playerRank then
				raiseRankButton.visible = false;
			end
			if faction.playerRank > 0 then
				lowerRankButton.visible = true;
			end
			lowerRankButton.text = 'Lower rank';
			rankText.text = 'current rank: '..tostring(faction.playerRank);
		end
	end
end


local function CreateFactionsPage(factionsButton);

	local factionsPage, factionsLeftPage, factionsRightPage = functions.CreateCategoryPage(pane, 'Click a faction to join it.');
	menuTabs[factionsButton] = factionsPage;

	factionsLeftScrollable = functions.CreateScrollPane(factionsLeftPage);
	factionsRightScrollable = functions.CreateScrollPane(factionsRightPage);
	factionsLeftScrollable.borderTop = 11;
	tFactionButtons = {};
	tPlayerFactionButtons = {};

	for k, faction in pairs(tFactionList) do
		local element = functions.CreateSelectable(factionsLeftScrollable, faction.name, function() JoinFaction(faction); end);
		tFactionButtons[faction.id] = element;
		if faction.playerJoined then
			element.visible = false;
		end
	end
	for k, faction in pairs(tFactionList) do
		local block = factionsRightScrollable:createBlock();
		block.flowDirection = 'left_to_right';
		block.autoWidth = true;
		block.autoHeight = true;
		block:createLabel{text = faction.name};
		block.flowDirection = 'top_to_bottom';
		-- log('%s reputation %s playerRank %s', faction.id, faction.ranks[#faction.ranks].reputation, faction.playerRank);
		local rankBlock = block:createBlock();
		rankBlock.flowDirection = 'left_to_right';
		rankBlock.autoWidth = true;
		rankBlock.autoHeight = true;

		local sRank = rankBlock:createLabel{text = 'current rank: '..tostring(faction.playerRank)};
		sRank.borderRight = 12;
		sRank.borderTop = 3;
		local lowerRankButton = functions.CreateButton(rankBlock, 'Lower rank', function() LowerRank(faction, sRank); end);
		local raiseRankButton = functions.CreateButton(rankBlock, 'Raise rank', function() RaiseRank(faction, sRank); end);
		-- block:createLabel{text = ''};

		if faction.playerExpelled then
			sRank.text = 'current rank: expelled';
			lowerRankButton.visible = false;
			raiseRankButton.text = 'Join faction';
		end

		if GetNumRanks(faction) == 0 or #faction.ranks - 1 == faction.playerRank then
			raiseRankButton.visible = false;
		end
		if faction.playerJoined and faction.playerRank == 0 then
			lowerRankButton.text = 'Leave faction';
		end
		tPlayerFactionButtons[faction.id] = block;
		if not faction.playerJoined then
			block.visible = false;
		end
	end
end


function modConfigMenu.onCreate(container)
	-- mb('onCreate');
	menuTabs = {};
	pane = container:createThinBorder{};
	pane.widthProportional = 1.0;
	pane.heightProportional = 1.0;
	-- pane.paddingAllSides = 12;
    pane.flowDirection = 'top_to_bottom';
    -- local header = pane:createLabel{text = 'Cheat Menu New 1.01'};
	-- header.color = tes3ui.getPalette("header_color");
	if tes3.onMainMenu() then
		local header = pane:createLabel{text = 'You have to load a saved game to use this menu.'};
		header.borderTop = 22;
		header.borderLeft = 22;
		return;
	end

	local categoryButtonsBlock = pane:createBlock();
	categoryButtonsBlock.flowDirection = 'left_to_right';
	categoryButtonsBlock.autoWidth = true;
	categoryButtonsBlock.autoHeight = true;

	local cheatsButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Cheats')
	CreateCheatsPage(cheatsButton);

	local statsButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Player Stats');
	CreateStatsPage(statsButton);

	local itemsButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Items');
	CreateItemsPage(itemsButton);
	-- itemsButton:register("mouseClick", onClick);

	local spellsButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Spells');
	CreateSpellsPage(spellsButton);

	local teleportButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Teleport');
	CreateTeleportPage(teleportButton);

	local factionsButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Factions');
	CreateFactionsPage(factionsButton);

	local gmstButton = functions.CreateCategoryButton(categoryButtonsBlock, 'Game Settings');
	CreateGMSTpage(gmstButton);

	functions.menuTabs = menuTabs;
	functions.OpenCategory(cheatsButton);

end


local function KeyPressed(e)

	-- if tes3.onMainMenu() then
		-- return;
	-- end
	-- e.source:forwardEvent(e);	
    mb('KeyPressed %s %s', GetKeybindName(e.keyCode), e.keyCode);

end


local function OnActivateObject(eventData)

	if config.autoUnlock then
		local ref = eventData.target;
		if ref.object.objectType == iContainerType or ref.object.objectType == iDoorType then 

			if tes3.getLocked{reference = ref} then
				tes3.unlock{reference = ref};
			end
			if tes3.getTrap{reference = ref} then
				ref.lockNode.trap = nil;
			end
		end
	end
end


local function Setup()

	for k, func in pairs(tkeyPressFuctions) do
		-- log('tkeyPressFuctions %s', k);
		event.register('keyDown', func, {filter = savedConfig[k].keyCode});
	end
	MakePlayerAttributesList();
	MakeSpellList();
	MakeWeatherList();
	MakeItemList();
	MakeSoulGemList();
	MakeCreatureList();
	MakeCellList();
	MakeNPClist();
	CreateGMSTlist();
	CreateFactionlist();
	weatherController = tes3.getWorldController().weatherController;
end


local function RegisterModConfig()
	-- log('RegisterModConfig %s', isModActive);
	-- if tes3.isModActive('MW Containers Animated.esp') then
		mwse.registerModConfig('Cheat Menu', modConfigMenu);
	-- end
end
 -- fires before initialized event
event.register("modConfigReady", RegisterModConfig);

local function hudActivated(e)
	-- log('OnUIactivated %s ', e.element.name);
	hud = e.element;
end

local function OnInitialized()
	-- for k, faction in pairs(tes3.dataHandler.nonDynamicData.factions) do
		-- mwse.log('%s    %s', faction.name, faction.id);
	-- end

	Setup(); 
	event.register("uiActivated", hudActivated, {filter = 'MenuMulti'}); 
	-- event.register("keyDown", KeyPressed);
	-- event.register("loaded", OnLoaded);
	event.register("activate", OnActivateObject, {priority = -1111});
	-- event.register("keyDown", KeyPressed); 
	log('[Cheat Menu v1.1] lua script loaded');
end
event.register("initialized", OnInitialized);


function modConfigMenu.onClose(container)
	functions.StopInputCapture();
	-- event.unregister('keyDown', KeyPressed);
    mwse.saveConfig('CheatMenuConfig', savedConfig);
end


local function Test()

	-- local target = tes3.getPlayerTarget();
	-- target:updateEquipment();
end
-- event.register("keyDown", Test, {filter = tes3.scanCode.z}); 
