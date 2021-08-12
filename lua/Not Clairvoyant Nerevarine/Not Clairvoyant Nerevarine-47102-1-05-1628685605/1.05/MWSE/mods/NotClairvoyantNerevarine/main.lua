	
local bBackgroundTopicRevealName = true; 
local tKnownIDs;
local tTradedItems;
local iNPCtype = tes3.objectType.npc;
local iBookType = tes3.objectType.book;
local iDoorType = tes3.objectType.door;
local iContType = tes3.objectType.container;
local iAlchType = tes3.objectType.alchemy;
local iMiscType = tes3.objectType.miscItem;
local lastNPC, sLastNPCname, sLastNPCraceName, lastNPCdisp;
local dialogMenuTitle;
local bRegisteredMenuEnter = false;
local bBartering = false; 
local tExceptionIDs = {};
local tVisitedCells ;
local bFoundName = false;
local tDoorsToHide = {};
local mapMenu, miniMap;
local secondTimer;
local tKeyMeshes = {};
local config = mwse.loadConfig('NotClairvoyantNerevarine_config') or {barterRevealOnlyNames = true};
local modConfig = require("NotClairvoyantNerevarine.configMenu");
modConfig.config = config;
local sBook, sScroll, sRolledPaper, sPaper, sParchment, sNote, sKey, sBrew;
local loc = require("NotClairvoyantNerevarine.localization");
local sLang; -- = tes3.getLanguage();
local mb = tes3.messageBox;
local log = mwse.log;
-- local bEnteredDialog = false;

local function tryHideID(tooltip, uiid)
	local element = tooltip:findChild(tes3ui.registerID(uiid))
	if element ~= nil then
		element.visible = false
		return true
	end
	return false
end


local function GetCellName(cell) 

	local sCellName = cell.id;
	if not cell.isInterior then
		sCellName = sCellName..' '..cell.gridX..' '..cell.gridY;
	end
	return sCellName;
end


local function HideDoorMarker(t)

	for i, v in pairs(t) do
		-- if v.name == 'MenuMap_active_door' then
			local doorRef = v:getPropertyObject("MenuMap_object");

			if doorRef and doorRef.destination and doorRef.destination.cell then
					-- mwse.log('destination.cell %s', doorRef.destination.cell);
				if not tVisitedCells[GetCellName(doorRef.destination.cell)] then
					-- mwse.log(' hide %s', doorRef.destination.cell);
					v.visible = false;
				end
			end

			if v.children then
				HideDoorMarker(v.children);
			end
		-- end
	end
end


local function OnInfoGetText(e)
	-- mb('OnInfoGetText %s', e.info.id);
	if not lastNPC or not dialogMenuTitle then
		-- mb('lastNPC nil');
		return;
	end
	-- mb('OnInfoGetText  %s', sLastNPCname);
	if tKnownIDs[lastNPC.id] then
		return;
	end
	local text = e:loadOriginalText():lower();

	if text and string.len(text) > 0 then
		-- mb('disposition %d', e.info.disposition);
		-- mb('OnInfoGetText  %s', lastNPC.id);
		if string.find(text, '%name', 1, true) or string.find(text, sLastNPCname:lower(), 1, true) then
			tKnownIDs[lastNPC.id] = true;
			-- mb('OnInfoGetText %s', dialogMenuTitle.text);
			-- mwse.log('OnInfoGetText  %s', dialogMenuTitle.text);
			dialogMenuTitle.text = sLastNPCname;
			-- dialogMenuTitle = nil;
		end
	end
end

-- fires only for infos that have something in the result box
local function OnInfoResponse(e)
	-- mb('OninfoResponse ');
	local NPC = e.reference.baseObject;
	if not dialogMenuTitle or tKnownIDs[NPC.id] then
		return;
	end

	if bBackgroundTopicRevealName and e.dialogue.id == 'Background' then
		-- mb('disposition %d', e.info.disposition);
		if e.reference.object.disposition >= e.info.disposition then
			tKnownIDs[NPC.id] = true;
			dialogMenuTitle.text = NPC.name;
		-- mb('OninfoResponse text %s', e.info.text);
		end
	else
		local text = e.info.text:lower();
		if text and string.len(text) > 0 then
			-- mb('disposition %d', e.info.disposition);
			-- mb('OnInfoGetText  %s', lastNPC.id);
			if string.find(text, '%name', 1, true) or string.find(text, sLastNPCname:lower(), 1, true) then
				tKnownIDs[NPC.id] = true;
				dialogMenuTitle.text = sLastNPCname;
			end
		end
	end
end


local function OnUIevent(e) 
	mb('OnUIevent id %d', e.block.id);
	mb('OnUIevent name %s', e.block.name);
	mb('OnUIevent text %s', e.block.text);
	-- log('dialogue.id %s', e.dialogue.id);
	-- e.passes = true;
	-- log('actor %s, source %s, reference %s, dialogue %s, info %s, passes %s', e.actor, e.source, e.reference, e.dialogue, e.info.id, e.passes);
end


local function OnInfoFilter(e) 
	if not e.passes then
		return;
	end
	if not e.dialogue then
		mb('dialogue nil');
		return;
	end
	if not e.dialogue.id then
		mb('dialogue.id nil');
		return;
	end
	mb('dialogue.id %s', type(e.dialogue.id));
	-- log('dialogue.id %s', e.dialogue.id);
	-- e.passes = true;
	-- log('actor %s, source %s, reference %s, dialogue %s, info %s, passes %s', e.actor, e.source, e.reference, e.dialogue, e.info.id, e.passes);
end


local function OnLoaded()
	-- mwse.log('OnLoaded');

	if not tes3.player.data.NCN_knownIDs then
		tes3.player.data.NCN_knownIDs = {};
	end
	tKnownIDs = tes3.player.data.NCN_knownIDs;

	-- if not tes3.player.data.NCN_tradedItems then
		-- tes3.player.data.NCN_tradedItems = {};
	-- end
	-- tTradedItems = tes3.player.data.NCN_tradedItems;

	if not tes3.player.data.NCN_visitedCells then
		tes3.player.data.NCN_visitedCells = {};
	end
	tVisitedCells = tes3.player.data.NCN_visitedCells;
	
    -- secondTimer = timer.start{ iterations = -1, duration = 1, callback = secondTimerTick};
	-- HideDoorMarker(mapMenu);
	HideDoorMarker(miniMap);
end


local function GetMeshName(obj)

	local dir, name = obj.mesh:match("(.-)([^\\]+)$");
	name = name:lower();
	name = name:gsub(".nif", "");
	return name;
end


local function GetBookName(book)

	if book.type == 0 then
		return sBook;
	else
		local sMeshName = GetMeshName(book);

		if string.find(sMeshName, "paper_roll", 1, true) then
			return sRolledPaper;
		elseif string.find(sMeshName, "paper_plain", 1, true) then
			return sPaper;
		elseif string.find(sMeshName, "parchment", 1, true) then
			return sParchment;
		elseif string.find(sMeshName, "scroll", 1, true) then
			return sScroll;
		else
			return sNote;
		end
	end
end


local function IsKey(obj)
	
	if obj.objectType ~= iMiscType then
		return false;
	end

	return tKeyMeshes[GetMeshName(obj)];
end


local function OnCellChanged(e)
    -- for i, cell in ipairs(tes3.getActiveCells()) do
		-- local sCellName = GetCellName(cell);
	-- mb('OnCellChanged %s' , e.cell);
	-- mwse.log('OnCellChanged %s' , e.cell);
	tVisitedCells[GetCellName(e.cell)] = true;
	-- e.previousCell
	-- HideDoorMarker(mapMenu);
	HideDoorMarker(miniMap);
end


local function FindUIelement(t, n)
	
	n = n:lower();

	for i, v in pairs(t) do

		if v.name and v.name == n then
			-- mwse.log('found %s', n);
			-- return v;
			-- cant compare strings, number of books in stack is in there
		elseif v.text and string.len(v.text) > 0 then
			v.text = v.text:lower();
			-- if string.len(v.text) > 0 then
				-- mwse.log('FindUIelement text %s %s', v, v.text );
			-- end  PartDragMenu_title
			if string.find(v.text, n, 1, true) or string.find(v.text, '%name', 1, true) then
					-- mwse.log('destination.cell %s', v.destination.cell);
				-- mwse.log('FindUIelement found %s %s', v, v.text );
					-- v.visible = false;
			-- return v;
			end
		end
		if v.children then
	        local e = FindUIelement(v.children, n);
            -- if e then
                -- return e; MenuDialog_hyper
            -- end
		end
	end
end


local function HideTooltip(t, oldName, newName)

	for i, v in pairs(t) do
		-- mwse.log('element %s %s', v, type(v));
			-- if v.text and string.len(v.text) > 0 then
				-- mwse.log('text %s', v.text );
			-- end
		if not bFoundName and v.text and string.find(v.text, oldName, 1, true) then
			-- mwse.log('found name %s %s', oldName, newName );
			if newName then
				v.text = newName;
			end
			bFoundName = true;
		elseif bFoundName then
			-- mwse.log('hide %s', v);
			v.visible = false;
		end

		if v.children then
			HideTooltip(v.children, oldName, newName);
		end
	end
end


local function OnEquip(eventData)

	if eventData.item.objectType == iAlchType then
		tKnownIDs[eventData.item.id] = true;
		-- mb('OnEquip %s',eventData.item);
	end
end


local function OnUIobjectTooltip(eventData)
	-- mwse.log('OnUIobjectTooltip %s', eventData.tooltip);
	-- mb('OnUIobjectTooltip %s', eventData.tooltip);
	bFoundName = false;
	local obj = eventData.object;
	local ref = eventData.reference;
	-- local block = eventData.tooltip:createBlock{};
	-- block.autoWidth = true;
	-- block.autoHeight = true;
	-- block:createLabel{text = 'count  '..tostring(eventData.count)};
	-- block:createLabel{text = 'tKnownIDs  '..tostring(tKnownIDs[obj.id] )};
	if not bBartering then
		-- if not tTradedItems[obj.id] then
			-- mb('not traded %s', obj.id);
			-- tryHideID(eventData.tooltip, "HelpMenu_value")
		-- end

		-- HideTooltip(eventData.tooltip.children, 'Value', '_Value_');
		if IsKey(obj) and not tKnownIDs[obj.id] then
			HideTooltip(eventData.tooltip.children, obj.name, sKey);
				-- find any not digit character. player made potion ID has only digits 
		-- elseif obj.objectType == iAlchType and not tKnownIDs[obj.id] and string.match(obj.id, '%D') then
		-- not brewed potions have obj.sourceMod 
		elseif obj.objectType == iAlchType and not tKnownIDs[obj.id] and obj.sourceMod then
			-- mb('iAlchType');
			-- local potionNameElement = FindUIelement(eventData.tooltip.children, obj.name);
			HideTooltip(eventData.tooltip.children, obj.name, sBrew);

		elseif obj.objectType == iBookType and not tKnownIDs[obj.id] then

		-- local bookNameElement = FindUIelement(eventData.tooltip.children, obj.name);
		-- local castTypeElement = FindUIelement(eventData.tooltip.children, 'HelpMenu_castType');
		-- local enchantmentElement = FindUIelement(eventData.tooltip.children, 'HelpMenu_enchantmentContainer');

			local sName = GetBookName(obj);
		-- if sLang = 'eng' then
			-- local count = math.max(eventData.count, ref and ref.stackSize or 1);
			-- if count > 1 then
				-- sName = sName..'s';
			-- end
		-- end
			HideTooltip(eventData.tooltip.children, obj.name, sName);
		elseif obj.objectType == iNPCtype and not tKnownIDs[obj.baseObject.id] then
			for k, v in pairs(eventData.tooltip.children[1].children ) do
				if v.text and v.text == obj.baseObject.name then
					v.text = obj.race.name;
				end
			end
		elseif obj.objectType == iDoorType and ref.destination and ref.destination.cell then

			if not tVisitedCells[GetCellName(ref.destination.cell)] then
				for k, v in pairs(eventData.tooltip.children[1].children ) do
					-- mwse.log('k %s v %s', k, v);
					if v.name == 'HelpMenu_destinationTo' or v.name == 'HelpMenu_destinationCell' then
						v.visible = false;
					end
				end
			end	
		end	

	elseif bBartering and config.barterRevealOnlyNames and not tKnownIDs[obj.id] and obj.sourceMod then
		-- mwse.log('bBartering');
		if obj.objectType == iAlchType or obj.objectType == iBookType then
			HideTooltip(eventData.tooltip.children, obj.name);
		end
	end	
end


local function OnMenuExit(eventData)

	-- mb('OnMenuExit');
	dialogMenuTitle = nil;
	if bBartering then
		bBartering = false;
		-- event.unregister('menuExit', OnMenuExit); 
		-- event.unregister('uiEvent', OnUIevent); 
	end
end


local function DialogMenuEnter(eventData) 

	-- event.register('menuExit', OnMenuExit);
	if not tKnownIDs[lastNPC.id] then 
		-- bEnteredDialog = true;
		local bRevealName = false;
		local greeting = eventData.menu.children[1].children[2].children[2].children[2].children[1].children[3].children[1].children[1].children[1].children[1].children[1];

		dialogMenuTitle = eventData.menu.children[1].children[2].children[2].children[1].children[2];
		-- mwse.log('DialogMenuEnter  %s', dialogMenuTitle.text);
		if greeting and greeting.text and string.len(greeting.text) > 0 then
			local text = greeting.text:lower();
			-- mwse.log('greeting.text  %s', greeting.text);
			if string.find(text, '%name', 1, true) or string.find(text, sLastNPCname:lower(), 1, true) then
				-- greeting:getTopLevelParent():updateLayout()
				tKnownIDs[lastNPC.id] = true;
				bRevealName = true;
			end
		end

		if not bRevealName then
			dialogMenuTitle.text = sLastNPCraceName;
		end
	end
end



local function OnActivateObject(eventData) 

	local ref = eventData.target;
	lastNPC = nil;
	sLastNPCname = nil;
	sLastNPCraceName = nil;
--[[
	if ref.object.objectType == iBookType and ref:testActionFlag(tes3.actionFlag.useEnabled) then 
		if not tes3.hasOwnershipAccess({ target = ref }) then
			mb('stole book %s', ref.object);
			tes3.triggerCrime{type = tes3.crimeType.theft, victim = ref.itemData.owner, value =ref.object.value}; 

			if ref.itemData and ref.itemData.owner then
				ref.itemData.owner = nil;
			end	reference.stackSize
			tes3.addItem({ reference = tes3.player,	item = ref.object, itemData = ref.itemData,	count = itemData and itemData.count or 1 });
			ref.itemData = nil;
			ref:disable();
			mwscript.setDelete({ reference = ref, delete = true });
			return false;
		end
--]]
	if ref.object.objectType == iNPCtype then 

		lastNPC = ref.baseObject;
		lastNPCdisp = ref.object.disposition;
		sLastNPCname = ref.baseObject.name;
		sLastNPCraceName = ref.object.race.name;
		-- mb('OnActivateObject %s', ref.baseObject.id);
		-- mb('OnActivateObject disposition %d', ref.object.disposition);
			-- mb('health %s', ref.mobile.health.current);
		if not tKnownIDs[ref.baseObject.id] then 

			-- mb('lastNPCname %s', lastNPCname);
			-- ref.baseObject.name = ref.object.race.name;

			-- tries to register twice if NPC script has 'activate'
			if not bRegisteredMenuEnter then
				-- bRegisteredMenuEnter = true;
				-- if ref.mobile.health.current > 0 then
					-- event.register('menuEnter', DialogMenuEnter, { filter = 'MenuDialog' }); 
				-- else
					-- event.register('menuEnter', ContentsMenuEnter, { filter = 'MenuContents' }); 
				-- end	 
			end	
		end
	elseif ref.object.objectType == iContType or ref.object.objectType == iDoorType then 
		if ref.lockNode and ref.lockNode.key then
			if tes3.player.object.inventory:contains(ref.lockNode.key) then
				tKnownIDs[ref.lockNode.key.id] = true;
			end
		end
	end
end


local function OnBookGetText(eventData) 

	if not tKnownIDs[eventData.book.id] then 
		tKnownIDs[eventData.book.id] = true;
	end
end


local function BarterMenuActivated(eventData) 
	-- mb('OnuiActivated %s', eventData.element);
	
	if not tKnownIDs[lastNPC.id] then 
		local menuTitle = eventData.element.children[1].children[2].children[2].children[1].children[2];
		menuTitle.text = sLastNPCraceName;
	end
	
	if not bBartering then
		bBartering = true;
		-- event.register('menuExit', OnMenuExit);
		-- event.register('uiEvent', OnUIevent);
	end
end


local function Setup() 

	sLang = modConfig.sLang;
	-- mwse.log('sLang %s', sLang);
	sBook = loc.book[sLang];
	sScroll = loc.scroll[sLang];
	sRolledPaper = loc.rolledPaper[sLang];
	sPaper = loc.paper[sLang];
	sParchment = loc.parchment[sLang];
	sNote = loc.note[sLang];
	sKey = loc.key[sLang];
	sBrew = loc.brew[sLang];

	tExceptionIDs['vivec_god'] = true; -- creature
	tExceptionIDs['almalexia'] = true; -- creature
	tExceptionIDs['Almalexia_warrior'] = true; -- creature
	tExceptionIDs['dagoth_ur_1'] = true; -- creature
	tExceptionIDs['dagoth_ur_2'] = true; -- creature
	tExceptionIDs['in_sotha_sil00'] = true; -- activator
	tExceptionIDs['KR_keyring1'] = true;
	tExceptionIDs['KR_keyring'] = true;

	tKeyMeshes['key_standard_01'] = true;
	tKeyMeshes['key_temple_01'] = true;
	tKeyMeshes['misc_dwrv_ark_key00'] = true;

	-- daduke key replacer
	tKeyMeshes['key_00'] = true;
	tKeyMeshes['key_01'] = true;
	tKeyMeshes['key_02'] = true;
	tKeyMeshes['key_03'] = true;
	tKeyMeshes['key_04'] = true;
	tKeyMeshes['key_05'] = true;
	tKeyMeshes['key_06'] = true;
	tKeyMeshes['key_07'] = true;
	tKeyMeshes['key_08'] = true;
	tKeyMeshes['key_09'] = true;
	tKeyMeshes['key_10'] = true;
	tKeyMeshes['key_11'] = true;
	tKeyMeshes['key_12'] = true;
	tKeyMeshes['key_13'] = true;
	tKeyMeshes['key_14'] = true;
	tKeyMeshes['key_15'] = true;
	tKeyMeshes['key_16'] = true;
	tKeyMeshes['key_17'] = true;
	tKeyMeshes['key_18'] = true;
	tKeyMeshes['key_19'] = true;
	tKeyMeshes['key_20'] = true;
	tKeyMeshes['key_21'] = true;
	tKeyMeshes['key_22'] = true;
	tKeyMeshes['key_23'] = true;
	tKeyMeshes['key_24'] = true;
	tKeyMeshes['key_25'] = true;
	tKeyMeshes['key_26'] = true;
	tKeyMeshes['key_27'] = true;
	tKeyMeshes['key_28'] = true;
	tKeyMeshes['key_29'] = true;
	tKeyMeshes['key_30'] = true;
	tKeyMeshes['key_31'] = true;
	tKeyMeshes['key32'] = true;
	tKeyMeshes['key33'] = true;
	tKeyMeshes['key34'] = true;
	tKeyMeshes['key35'] = true;
	tKeyMeshes['key36'] = true;
	tKeyMeshes['key37'] = true;
	tKeyMeshes['key38'] = true;
	tKeyMeshes['key39'] = true;
	tKeyMeshes['key40'] = true;
	tKeyMeshes['key41'] = true;
	tKeyMeshes['key42'] = true;
	tKeyMeshes['key43'] = true;
	tKeyMeshes['key44'] = true;
	tKeyMeshes['key45'] = true;
	tKeyMeshes['key46'] = true;
	tKeyMeshes['key47'] = true;
	tKeyMeshes['key48'] = true;
	tKeyMeshes['key49'] = true;
	tKeyMeshes['key50'] = true;

	-- russian key replacer
	tKeyMeshes['q_key_bronze'] = true;
	tKeyMeshes['q_key_chest'] = true;
	tKeyMeshes['q_key_chest_01'] = true;
	tKeyMeshes['q_key_chest_02'] = true;
	tKeyMeshes['q_key_chest_03'] = true;
	tKeyMeshes['q_key_common'] = true;
	tKeyMeshes['q_key_common_01'] = true;
	tKeyMeshes['q_key_common_02'] = true;
	tKeyMeshes['q_key_common_03'] = true;
	tKeyMeshes['q_key_common_04'] = true;
	tKeyMeshes['q_key_common_05'] = true;
	tKeyMeshes['q_key_common_06'] = true;
	tKeyMeshes['q_key_common_07'] = true;
	tKeyMeshes['q_key_common_08'] = true;
	tKeyMeshes['q_key_common_09'] = true;
	tKeyMeshes['q_key_crypt'] = true;
	tKeyMeshes['q_key_daedric'] = true;
	tKeyMeshes['q_key_daedric_rusty'] = true;
	tKeyMeshes['q_key_daedric_small'] = true;
	tKeyMeshes['q_key_divayth_fyr'] = true;
	tKeyMeshes['q_key_dwemer'] = true;
	tKeyMeshes['q_key_dwemer_chest'] = true;
	tKeyMeshes['q_key_dwemer_dagoth'] = true;
	tKeyMeshes['q_key_dwemer_door'] = true;
	tKeyMeshes['q_key_dwemer_guard'] = true;
	tKeyMeshes['q_key_dwemer_rusty'] = true;
	tKeyMeshes['q_key_ebony'] = true;
	tKeyMeshes['q_key_flat'] = true;
	tKeyMeshes['q_key_head'] = true;
	tKeyMeshes['q_key_imperial'] = true;
	tKeyMeshes['q_key_imperial_secret'] = true;
	tKeyMeshes['q_key_iron'] = true;
	tKeyMeshes['q_key_letter_m'] = true;
	tKeyMeshes['q_key_letter_n'] = true;
	tKeyMeshes['q_key_light'] = true;
	tKeyMeshes['q_key_manor'] = true;
	tKeyMeshes['q_key_old'] = true;
	tKeyMeshes['q_key_old_ashy'] = true;
	tKeyMeshes['q_key_old_big'] = true;
	tKeyMeshes['q_key_room'] = true;
	tKeyMeshes['q_key_rusty'] = true;
	tKeyMeshes['q_key_secret'] = true;
	tKeyMeshes['q_key_shabby'] = true;
	tKeyMeshes['q_key_simple_01'] = true;
	tKeyMeshes['q_key_simple_02'] = true;
	tKeyMeshes['q_key_small'] = true;
	tKeyMeshes['q_key_storehouse'] = true;
	tKeyMeshes['q_key_tomb'] = true;
	tKeyMeshes['q_key_tomb_01'] = true;
	tKeyMeshes['q_key_tomb_02'] = true;
	tKeyMeshes['q_key_tomb_03'] = true;
	tKeyMeshes['q_key_tomb_04'] = true;
	tKeyMeshes['q_key_tomb_chest'] = true;
	tKeyMeshes['q_key_vault'] = true;
	tKeyMeshes['q_key_venim'] = true;
	tKeyMeshes['q_key_warehouse'] = true;
	tKeyMeshes['q_key_wizard'] = true;
end


local function OnUIpreEvent(e) 
		-- mb('uiPreEvent %s', e.block);
	if e.block.name == 'MenuMap_pane' or e.block.name == 'MenuMap_switch' then
		HideDoorMarker(mapMenu);
		-- HideDoorMarker(miniMap);
	end
end


local function MapMenuActivated(e) 
	mapMenu = e.element.children;
end


local function MiniMapActivated(e) 
	miniMap = e.element.children;
end


local function ContentsMenuActivated(eventData) 
	
	if lastNPC and not tKnownIDs[lastNPC.id] then 
		local menuTitle = eventData.element.children[1].children[2].children[2].children[1].children[2];
		menuTitle.text = sLastNPCraceName;
	end
end


local function OnBarterOffer(e) 
	
	if not e.success then 
		return;
	end
    if #e.buying > 0 then
        -- mwse.log("Buying:");
		-- mb("Buying:");
        for _, tile in ipairs(e.buying) do
            -- log("  %s x%d", tile.item.id, tile.count);
			-- mb("  %s x%d", tile.item.id, tile.count);
			tTradedItems[tile.item.id] = true;
        end
    end
    if #e.selling > 0 then
        -- mwse.log("selling:");
		-- mb("selling:");
        for _, tile in ipairs(e.selling) do
            -- log("  %s x%d", tile.item.id, tile.count);
			-- mb("  %s x%d", tile.item.id, tile.count);
			tTradedItems[tile.item.id] = true;
        end
    end
end


local function OnInitialized()

	if not tes3.isModActive('Not Clairvoyant Nerevarine.esp') then
		return;
	end

	Setup();
	event.register('menuExit', OnMenuExit);
	-- event.register("infoFilter", OnInfoFilter);
	-- event.register('uiEvent', OnUIevent); 
	-- event.register('barterOffer', OnBarterOffer); 
	event.register('infoResponse', OnInfoResponse);
	event.register('infoGetText', OnInfoGetText); 
	event.register('menuEnter', DialogMenuEnter, { filter = 'MenuDialog' });
	event.register("equip", OnEquip);
	event.register("uiPreEvent", OnUIpreEvent);
	event.register("cellChanged", OnCellChanged);
	-- event.register("uiActivated", DialogMenuActivated, { filter = 'MenuDialog' });
	event.register("uiActivated", ContentsMenuActivated, { filter = 'MenuContents' });
	event.register("uiActivated", BarterMenuActivated, { filter = 'MenuBarter' });
	event.register("uiActivated", MapMenuActivated, { filter = 'MenuMap' });
	event.register("uiActivated", MiniMapActivated, { filter = 'MenuMulti' });
	event.register('bookGetText', OnBookGetText);
	event.register('uiObjectTooltip', OnUIobjectTooltip, { priority = -1111 });
	event.register("loaded", OnLoaded);
	event.register("activate", OnActivateObject, { priority = 1111 });

	mwse.log("[Not Clairvoyant Nerevarine] lua script loaded");
end
event.register("initialized", OnInitialized);


local function OnActivationTargetChanged(eventData)
	local ref = eventData.current;
	if ref then
		
			-- mb('Is Key %s', IsKey(ref.object));

		-- if ref.destination and ref.destination.cell then
			-- mb('leads to %s', ref.destination.cell);
		-- if  ref.itemData and ref.itemData.owner then
			-- mb('owner %s', ref.itemData.owner  );
		-- end
	end
end
-- event.register("activationTargetChanged", OnActivationTargetChanged); 	


local function Test()
	local ref = tes3.getPlayerTarget();
	-- local v = tes3.getPlayerEyeVector()  
	-- mb('sGameLang %s', loc.book[sLang]);

	if ref then
		-- mb('sourceMod %s', ref.object.sourceMod );
		-- local d = string.match(ref.object.id, '%D')

		-- mb('tKnownIDs[obj.id] %s', tKnownIDs[ref.object.id]);
		-- if ref.itemData and ref.itemData.owner then
			-- mb('remove owner %s', ref.itemData.owner);
			-- ref.itemData.owner = nil;
		-- end
	end
end
-- event.register("keyDown", Test, { filter = tes3.scanCode.z }); 



