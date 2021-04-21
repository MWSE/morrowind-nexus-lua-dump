	

local mb = tes3.messageBox;
local log = mwse.log;
local this = {};
local sYes;
local sNo;
local spaceBetweenElements = 11;
local bDropdownOpen = false;
local bSecondTimerTick = false;
local tDefaultInputText = {['Type in a name'] = true, ['Type in a gmst ID'] = true};

local tKeyCodes = {[2] = '1', [3] = '2', [4] = '3', [5] = '4', [6] = '5', [7] = '6', [8] = '7', [9] = '8', [10] = '9', [11] = '0', [12] = '-', [13] = '=', [43] = '\\', [16] = 'q', [17] = 'w', [18] = 'e', [19] = 'r', [20] = 't', [21] = 'y', [22] = 'u', [23] = 'i', [24] = 'o', [25] = 'p', [30] = 'a', [31] = 's', [32] = 'd', [33] = 'f', [34] = 'g', [35] = 'h', [36] = 'j', [37] = 'k', [38] = 'l', [44] = 'z', [45] = 'x', [46] = 'c', [47] = 'v', [48] = 'b', [49] = 'n', [50] = 'm', [57] = ' ', [26] = '[', [27] = ']', [39] = ';', [40] = "'", [51] = ',', [52] = '.', [53] = '/', 
[71] = '7', [72] = '8', [73] = '9', [75] = '4', [76] = '5', [77] = '6', [79] = '1', [80] = '2', [81] = '3', [82] = '0', [74] = '-', [83] = '.'};

local tShiftKeyCodes = {[2] = '!', [3] = '@', [4] = '#', [5] = '$', [6] = '%', [7] = '^', [8] = '&', [9] = '*', [10] = '(', [11] = ')', [12] = '_', [13] = '+', [43] = '|', [16] = 'Q', [17] = 'W', [18] = 'E', [19] = 'R', [20] = 'T', [21] = 'Y', [22] = 'U', [23] = 'I', [24] = 'O', [25] = 'P', [30] = 'A', [31] = 'S', [32] = 'D', [33] = 'F', [34] = 'G', [35] = 'H', [36] = 'J', [37] = 'K', [38] = 'L', [44] = 'Z', [45] = 'X', [46] = 'C', [47] = 'V', [48] = 'B', [49] = 'N', [50] = 'M', [57] = ' ', [26] = '{', [27] = '}', [39] = ':', [40] = '"', [51] = '<', [52] = '>', [53] = '?'};

local tNumberKeyCodes = {[2] = '1', [3] = '2', [4] = '3', [5] = '4', [6] = '5', [7] = '6', [8] = '7', [9] = '8', [10] = '9', [11] = '0', [12] = '-',  
[71] = '7', [72] = '8', [73] = '9', [75] = '4', [76] = '5', [77] = '6', [79] = '1', [80] = '2', [81] = '3', [82] = '0', [74] = '-', [52] = '.', [83] = '.'}; 
 
local activeInputString = {};
local config;
local savedConfig;
local savedConfigKey;
local keyBindButton;
this.tkeyPressFuctions = {};

local function GetKeybindName(scancode)
    return tes3.findGMST(tes3.gmst.sKeyName_00 + scancode).value;
end


local function CaptureKey(e)
	
	local key;
	if e.isShiftDown then
		key = tShiftKeyCodes[e.keyCode]
	else
		key = tKeyCodes[e.keyCode]
	end
	if key then
		activeInputString.input.text = activeInputString.input.text..key;
		-- skipAnimKeyButton.widget.state = 1;
	elseif e.keyCode == 14 then -- backspace
		activeInputString.input.text = activeInputString.input.text:sub(1, -2);
	end
end


local function BackspaceTimerExpired()
	-- mb('BackspaceTimerExpired');
	if activeInputString and activeInputString.input then
		activeInputString.input.text = '';
	end
end


local function BackspaceKeyUp()
	-- mb('BackspaceKeyUp');
	event.unregister("keyUp", BackspaceKeyUp, {filter = 14});
	if activeInputString and activeInputString.input then
		if activeInputString.backspaceTimer then
			activeInputString.backspaceTimer:cancel();
		end
		if string.len(activeInputString.input.text) > 0 then
			activeInputString.input.text = activeInputString.input.text:sub(1, -2);
		end
	end
end


local function KeyPressed(e)

	local key;
	if e.isShiftDown then
		key = tShiftKeyCodes[e.keyCode]
	else
		key = tKeyCodes[e.keyCode]
	end
	if key then
		activeInputString.input.text = activeInputString.input.text..key;
		-- skipAnimKeyButton.widget.state = 1;
	elseif e.keyCode == 14 then -- backspace
		event.register("keyUp", BackspaceKeyUp, {filter = 14});
		activeInputString.backspaceTimer = timer.start{type = timer.real, duration = 1, iterations = 1, callback = BackspaceTimerExpired};
		-- activeInputString.input.text = activeInputString.input.text:sub(1, -2);
	end
end


local function NumberKeyPressed(e)

	local key = tNumberKeyCodes[e.keyCode]

	if key then
		activeInputString.input.text = activeInputString.input.text..key;
		-- skipAnimKeyButton.widget.state = 1;
	elseif e.keyCode == 14 then -- backspace
		event.register("keyUp", BackspaceKeyUp, {filter = 14});
		activeInputString.backspaceTimer = timer.start{type = timer.real, duration = 1, iterations = 1, callback = BackspaceTimerExpired};
		-- activeInputString.input.text = activeInputString.input.text:sub(1, -2);
	end
end


local function SubmitInputCapture()
	-- remove leading and trailing spaces
	activeInputString.input.text = string.gsub(activeInputString.input.text, '^%s*(.-)%s*$', '%1');
	-- activeInputString.input.borderRight = 11;
	if activeInputString.callback then
		if string.len(activeInputString.input.text) > 0 then
			activeInputString.callback(activeInputString.input.text);
		else
			activeInputString.input.text = activeInputString.initialValue;
			if string.len(activeInputString.input.text) == 0 then
				activeInputString.input.text = 'Type in a name';
			end
		end
	end
	event.unregister('keyDown', KeyPressed);
	event.unregister('keyDown', NumberKeyPressed);
	event.unregister("keyDown", SubmitInputCapture, {filter = tes3.scanCode.enter}); 
	event.unregister("keyDown", SubmitInputCapture, {filter = tes3.scanCode.numpadEnter}); 
	if activeInputString.cursor then
		activeInputString.cursor:destroy();
		activeInputString.cursor = nil;
		activeInputString.inputCursorTimer:cancel();
	end
	-- StopInputCapture();
	activeInputString = {};
end


local function StopInputCapture()

	-- mb('StopInputCapture');
	event.unregister('keyDown', CaptureKey); 
	event.unregister('keyDown', KeyPressed);
	event.unregister('keyDown', NumberKeyPressed);
	event.unregister("keyDown", SubmitInputCapture, {filter = tes3.scanCode.enter}); 
	event.unregister("keyDown", SubmitInputCapture, {filter = tes3.scanCode.numpadEnter}); 

	if activeInputString.cursor then
		activeInputString.cursor:destroy();
		activeInputString.cursor = nil;
		if activeInputString.inputCursorTimer then
			activeInputString.inputCursorTimer:cancel();
		end
	end
	if activeInputString.input then
		activeInputString.input.text = activeInputString.initialValue;
		if string.len(activeInputString.input.text) == 0 then
			activeInputString.input.text = 'Type in a name';
		end
	end

	activeInputString = {};
end


local function OpenCategory(clickedButton)

	StopInputCapture();
	for button, page in pairs(this.menuTabs) do
		page.visible = false;
		button.widget.idle = tes3ui.getPalette("normal_color");
		button.widget.over = tes3ui.getPalette("normal_over_color");
		button:triggerEvent('mouseLeave');
	end

	clickedButton.widget.idle = tes3ui.getPalette("magic_color");
	clickedButton.widget.over = tes3ui.getPalette("magic_color");
	clickedButton:triggerEvent('mouseLeave');
	-- tes3.worldController.menuClickSound:play();
	this.menuTabs[clickedButton].visible = true;
end


local function CreateCategoryButton(block, label)
	local button = block:createButton{text = label};
	-- button.absolutePosAlignX = 0.4;
	-- button.paddingTop = 2;
	button:register("mouseClick", function() OpenCategory(button); end)
	return button;
end


local function CreateCategoryPage(pane, leftPageLabel, rightPageLabel, leftPagePadding, RightPagePadding)
	-- tes3.messageBox('CreateCategoryPage');
	local page = pane:createBlock();
	-- page:createLabel{text = label};
	page.flowDirection = 'left_to_right';
	page.widthProportional = 1.0;
	page.heightProportional = 1.0;

	local leftPage = page:createThinBorder();
    leftPage.flowDirection = 'top_to_bottom';
	leftPage.widthProportional = 1.0;
	leftPage.heightProportional = 1.0;
	if leftPageLabel then
		local leftPageLabel_ = leftPage:createLabel{text = leftPageLabel};
		leftPageLabel_.borderTop = 11;
		leftPageLabel_.borderLeft = 11;
	end
	-- leftPage = leftPageBorder:createVerticalScrollPane();
	-- leftPage = leftPageBorder:createBlock();
	if leftPagePadding then
		leftPage.paddingAllSides = leftPagePadding;
	end
	local rightPage = page:createThinBorder();
    rightPage.flowDirection = 'top_to_bottom';
	rightPage.widthProportional = 1.0;
	rightPage.heightProportional = 1.0;
	if rightPageLabel then
		local rightPageLabel_ = rightPage:createLabel{text = rightPageLabel};
		rightPageLabel_.borderTop = 11;
		rightPageLabel_.borderLeft = 11;
	end
	-- rightPage = rightPageBorder:createVerticalScrollPane();
	-- rightPage = rightPageBorder:createBlock();
	if RightPagePadding then
		rightPage.paddingAllSides = RightPagePadding;
	end
    -- rightPage:createLabel{text = ''};

	return page, leftPage, rightPage;
end


local function CreateCategoryPageSingle(pane, label, leftPagePadding)

	local page = pane:createBlock();

	page.flowDirection = 'left_to_right';
	page.widthProportional = 1.0;
	page.heightProportional = 1.0;
	local leftPage = page:createThinBorder();
    leftPage.flowDirection = 'top_to_bottom';
	leftPage.widthProportional = 1.0;
	leftPage.heightProportional = 1.0;

	if label then
		local label_ = leftPage:createLabel{text = label};
		label_.borderTop = 11;
		label_.borderLeft = 11;
	end

	if leftPagePadding then
		leftPage.paddingAllSides = leftPagePadding;
	end

	return page, leftPage;
end


local function CreateScrollPane(parent, label)

	if label then
		local label_ = parent:createLabel{text = label};
		label_.borderBottom = 7;
	end
	local page = parent:createVerticalScrollPane();
	page.paddingLeft = 12;
	return page;
end


local function CreateYesNoButton(page, label, configKey, callback)
	local block = page:createBlock();
	block.flowDirection = 'left_to_right';
	block.autoWidth = true;
	block.autoHeight = true;
	local label_ = block:createLabel{ text = label };
	label_.borderRight = 22;
	label_.borderTop = 3;
	local button = block:createButton{text = config[configKey] and sYes or sNo};

	local function callback_()
		callback();
		config[configKey] = not config[configKey];
		button.text = config[configKey] and sYes or sNo;
		-- mb('configKey %s', config[configKey]);
	end
	button:register('mouseClick', callback_);
	button.borderBottom = spaceBetweenElements;
	return button;
end


local function CreateButton(page, label, callback)

	local button = page:createButton{text = label};
	button:register('mouseClick', callback );
	button.borderBottom = spaceBetweenElements;
	return button;
end


local function CreateSelectable(page, label, callback)

	local selectable = page:createTextSelect{text = label};
	selectable:register('mouseClick', callback );
	return selectable;
end


local function SelectDropdownOption(dropdownList, selectedOption)

	-- mb('SelectDropdownOption %s', selectedOption.label);
	for _, option in ipairs(dropdownList) do
		if option ~= selectedOption then
			option.element.visible = false;
		end
	end
	selectedOption.callback(selectedOption.value);
	-- selectedOption.element:getTopLevelParent():updateLayout();
end


local function ShowDropdown(dropdownList, selectedOption)
	
	if bDropdownOpen then
		 SelectDropdownOption(dropdownList, selectedOption)
	else
		for _, option in ipairs(dropdownList) do
			option.element.visible = true;
		end
		-- selectedOption.element:getTopLevelParent():updateLayout();
	end
	bDropdownOpen = not bDropdownOpen;
end


local function CreateDropdown(page, label, dropdownList, defaultValue, callback)

	local block = page:createBlock();
	block.flowDirection = 'left_to_right';
	block.autoWidth = true;
	block.autoHeight = true;
	block.borderBottom = spaceBetweenElements;

	local label_ = block:createLabel{text = label};
	label_.borderRight = 10;
	label_.borderTop = 5;
	local dropdown = block:createThinBorder();

	dropdown.flowDirection = 'top_to_bottom';
	dropdown.autoHeight = true;
	dropdown.autoWidth = true;
	-- dropdown.widthProportional = 1.0;
	dropdown.heightProportional = 1.0;
	dropdown.paddingTop = 5;
	dropdown.paddingBottom = 5;
	dropdown.paddingRight = 10;
	dropdown.paddingLeft = 10;
	-- dropdown.borderTop = 0;
	-- local listItem1 = page:createTextSelect({ text = 'qqqqqqqqq' })
	for _, option in ipairs(dropdownList) do
		local listItem = dropdown:createTextSelect{ text = option.label };
		option.element = listItem;
		option.callback = callback;
		listItem.widthProportional = 1.0;
		listItem.autoHeight = true;
		-- listItem.borderBottom = 3;
		listItem.widget.idle = tes3ui.getPalette("normal_color");
		listItem.widget.over = tes3ui.getPalette("normal_over_color");
		listItem.widget.pressed = tes3ui.getPalette("normal_pressed_color");
		if option.value ~= defaultValue then
			listItem.visible = false;
		-- else
		end
		listItem:register('mouseClick', function() ShowDropdown(dropdownList, option) end);
	end
	-- dropdown:getTopLevelParent():updateLayout()
end


local function CursorTimerTick()
	-- mb('CursorTimerTick');
	if activeInputString.cursor then
		bSecondTimerTick = not bSecondTimerTick;
		if bSecondTimerTick then
			activeInputString.cursor.text = '';
		else
			activeInputString.cursor.text = '_';
		end
	else
		activeInputString.inputCursorTimer:cancel();
	end
end


local function CaptureInput(element, callback, onlyNumbers, initialValue)

	if activeInputString and element ~= activeInputString.input then
		-- mb('CaptureInput %s', element.text);
		StopInputCapture();
		activeInputString.input = element;
		activeInputString.input.text = string.gsub(activeInputString.input.text, '^%s*(.-)%s*$', '%1');
		activeInputString.cursor = element.parent:createLabel{text = '_'};
		-- element.borderRight = 0;
		-- activeInputString.cursor.borderRight = 11;
		activeInputString.callback = callback;
		-- if element.text == 'Type in a name' then
		if tDefaultInputText[element.text] then
			element.text = '';
		end
		activeInputString.initialValue = element.text;

		if onlyNumbers then
			event.register('keyDown', NumberKeyPressed);
		else
			event.register('keyDown', KeyPressed);
		end
		event.register("keyDown", SubmitInputCapture, {filter = tes3.scanCode.enter}); 
		event.register("keyDown", SubmitInputCapture, {filter = tes3.scanCode.numpadEnter}); 
		activeInputString.inputCursorTimer = timer.start{type = timer.real, duration = 0.5, iterations = -1, callback = CursorTimerTick};
	end
end


local function CreateTextInput(page, label, onlyNumbers, initialValue, callback)

	local block = page:createBlock();
	block.flowDirection = 'left_to_right';
	block.autoWidth = true;
	block.autoHeight = true;
	block.borderBottom = spaceBetweenElements;
    local label_ = block:createLabel{text = label};
	label_.borderRight = 12;
	label_.borderTop = 3;
	local border = block:createThinBorder{};
	border.paddingRight = 13;
	border.paddingLeft = 12;
	border.autoWidth = true;
	border.height = 30;
	-- border.childAlignX = 0.5
	border.childAlignY = 0.5;

	local inputField = border:createTextSelect{ text = tostring(initialValue)};

	-- if wrapText then
		-- inputField.autoWidth = true;
		-- inputField.autoHeight = true;
		-- inputField.wrapText = true;
	-- end
	inputField:register('mouseClick', 
		function() CaptureInput(inputField, callback, onlyNumbers, initialValue); end);
	
	return block;
end


local function CreateSlider(page, label, configKey, sliderMin, sliderRange, sliderWidth)

	local labelBlock = page:createBlock();
	labelBlock.flowDirection = 'left_to_right';
	labelBlock.autoWidth = true;
	labelBlock.autoHeight = true;
	-- labelBlock.borderTop = 3;

    local name = labelBlock:createLabel{text = label};
	name.borderRight = 13;
	-- name.borderTop = 3;

	local slider = labelBlock:createSlider{current = config[configKey] - sliderMin, max = sliderRange, step = 1, jump = 10};
	slider.borderBottom = spaceBetweenElements;
	-- mwse.log('page.width %s', page.width);
	slider.width = sliderWidth;
	-- slider.autoHeight = true;
	slider.borderRight = 13;
	slider.borderTop = 5;
	local sliderValue = labelBlock:createLabel{text = tostring(config[configKey])};

	slider:register('PartScrollBar_changed', function(e)
		config[configKey] = slider:getPropertyInt('PartScrollBar_current') + sliderMin;
		sliderValue.text = tostring(config[configKey]);
	end);
end


local function CaptureKey(e)
	-- esc, alt, shift, control
	if e.keyCode == 1 or e.keyCode == 42 or e.keyCode == 54 or e.keyCode == 56 or e.keyCode == 184 or e.keyCode == 29 or e.keyCode == 157 then

	else
		event.unregister('keyDown', this.tkeyPressFuctions[savedConfigKey], {filter = savedConfig[savedConfigKey].keyCode});
		event.unregister('keyDown', CaptureKey);
		local buttonLabel = '';
		if e.isAltDown then
			buttonLabel = buttonLabel..'Alt + '
		end
		if e.isShiftDown then
			buttonLabel = buttonLabel..'Shift + '
		end
		if e.isControlDown then
			buttonLabel = buttonLabel..'Control + '
		end
		savedConfig[savedConfigKey].isAltDown = e.isAltDown;
		savedConfig[savedConfigKey].isControlDown = e.isControlDown;
		savedConfig[savedConfigKey].isShiftDown = e.isShiftDown;
		buttonLabel = buttonLabel..GetKeybindName(e.keyCode);
		savedConfig[savedConfigKey].keyCode = e.keyCode;
		mb('Key binding changed to "%s"', buttonLabel);
		-- mb('savedConfigKey "%s"', savedConfigKey);
		keyBindButton.text = buttonLabel;
		keyBindButton.widget.idle = tes3ui.getPalette("normal_color");
		keyBindButton.widget.over = tes3ui.getPalette("normal_over_color");
		keyBindButton:triggerEvent('mouseLeave');
		event.register('keyDown', this.tkeyPressFuctions[savedConfigKey], {filter = e.keyCode}); 
	end
end


local function CreateKeyBinder(page, label, savedConfigKey_)

	local block = page:createBlock();
	block.flowDirection = 'left_to_right';
	block.autoWidth = true;
	block.autoHeight = true;
	local label_ = block:createLabel{text = label};
	label_.borderRight = 22;
	label_.borderTop = 3;

	local buttonLabel = '';
	if savedConfig[savedConfigKey_].isAltDown then
		buttonLabel = buttonLabel..'Alt + '
	end
	if savedConfig[savedConfigKey_].isControlDown then
		buttonLabel = buttonLabel..'Control + '
	end
	if savedConfig[savedConfigKey_].isShiftDown then
		buttonLabel = buttonLabel..'Shift + '
	end
	buttonLabel = buttonLabel..GetKeybindName(savedConfig[savedConfigKey_].keyCode);

	local button = block:createButton{text = buttonLabel};
	button:register('mouseClick', function()
		mb('Press a key or a key combination');
		-- mb('savedConfigKey_  %s', savedConfigKey_);
		-- button.widget.idle = tes3ui.getPalette("normal_over_color");
		button.widget.over = tes3ui.getPalette("magic_color");
		button.widget.idle = tes3ui.getPalette("magic_color");
		savedConfigKey = savedConfigKey_;
		keyBindButton = button;
		event.unregister('keyDown', CaptureKey); 
		event.register('keyDown', CaptureKey); 
	end);
	button.borderBottom = spaceBetweenElements;
	-- keyBindButton.borderBottom = spaceBetweenElements;
end


local function Setup()   
	this.CreateParagraphInput = CreateParagraphInput;
	this.CreateCategoryPageSingle = CreateCategoryPageSingle;
	this.CreateScrollPane = CreateScrollPane;
	this.CreateSlider = CreateSlider;
	this.CreateSelectable = CreateSelectable;
	this.OpenCategory = OpenCategory;
	this.CreateCategoryButton = CreateCategoryButton;
	this.CreateCategoryPage = CreateCategoryPage;
	this.CreateYesNoButton = CreateYesNoButton;
	this.CreateButton = CreateButton;
	this.CreateTextInput = CreateTextInput;
	this.CreateDropdown = CreateDropdown;
	this.StopInputCapture = StopInputCapture;
	this.CreateKeyBinder = CreateKeyBinder;
	sYes = tes3.findGMST(tes3.gmst.sYes).value;
	sNo = tes3.findGMST(tes3.gmst.sNo).value;
	config = this.config;
	savedConfig = this.savedConfig;
end

local function OnInitialized()
	Setup();
	-- mwse.log("[Cheat Menu] lua script loaded");
end
event.register("initialized", OnInitialized);

local function Test1()
    -- for k, skill in pairs(tes3.dataHandler.nonDynamicData.skills) do
		-- mwse.log('%s', skill);
	-- end
	-- for skill in tes3.iterate(tes3.mobilePlayer.skills) do
		-- mwse.log('%s', skill);
	-- end
		tes3.messageBox('functions godMode %s', config.godMode);
	-- GetWeatherList();
end
-- event.register("keyDown", Test1, { filter = tes3.scanCode.z}); 

return this; 