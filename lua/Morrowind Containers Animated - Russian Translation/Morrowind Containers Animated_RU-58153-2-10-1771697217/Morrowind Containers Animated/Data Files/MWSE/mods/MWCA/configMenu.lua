
local modConfigMenu = {};
local pane;
local skipAnimKeyButton;
local this = {};
local itemsButtonText = {[0] = 'Пропустить анимацию', 'Скрыть предметы и воспроизвести анимацию', 'Переместить предметы в инвентарь игрока', 'Поместить предметы в контейнер после загрузки игры'};
local tItemsButtonAlign = {[0] = 0.45, 0.605, 0.61, 0.81};

local function RegisterModConfig()
	-- mwse.log('RegisterModConfig %s', isModActive);
	if tes3.isModActive('MW Containers Animated.esp') then
		mwse.registerModConfig("Анимированные контейнеры", modConfigMenu);
	end
end
 -- fires before initialized event
event.register("modConfigReady", RegisterModConfig);


local function GetKeybindName(scancode)
    return tes3.findGMST(tes3.gmst.sKeyName_00 + scancode).value;
end


function modConfigMenu.onClose(container)
    mwse.saveConfig('MWCA_config', this.config);
end


function modConfigMenu.onCreate(container)
	-- mwse.log('config.stayOpen init %s', this.config.stayOpen);
	pane = container:createThinBorder{};
	pane.widthProportional = 1.0;
	pane.heightProportional = 1.0;
	pane.paddingAllSides = 12;
    pane.flowDirection = "top_to_bottom";

    local header = pane:createLabel{ text = 'Анимированные контейнеры в. 2.10' };
	header.color = tes3ui.getPalette("header_color");
    header.borderBottom = 35;

	local stayOpenBlock = pane:createBlock();
	stayOpenBlock.flowDirection = "left_to_right";
	stayOpenBlock.widthProportional = 1.0;
	stayOpenBlock.autoHeight = true;

	stayOpenBlock:createLabel({ text = 'Оставлять контейнер открытым :' });

	local stayOpenButton = stayOpenBlock:createButton({ text = this.config.stayOpen and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value });
	stayOpenButton.absolutePosAlignX = 0.4;
	-- stayOpenButton.paddingTop = 2;
	stayOpenButton:register("mouseClick", function(e)
		this.config.stayOpen = not this.config.stayOpen;
		stayOpenButton.text = this.config.stayOpen and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value;
	end)

	local playSoundBlock = pane:createBlock();
	playSoundBlock.flowDirection = "left_to_right";
	playSoundBlock.widthProportional = 1.0;
	playSoundBlock.autoHeight = true;
	playSoundBlock:createLabel({ text = 'Воспроизводить звук во время анимации :' })

	local playSoundButton = playSoundBlock:createButton({ text = this.config.playSound and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value });
	playSoundButton.absolutePosAlignX = 0.4;
	playSoundButton:register("mouseClick", function(e)
		this.config.playSound = not this.config.playSound;
		playSoundButton.text = this.config.playSound and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value;
	end)

	local itemsBlock = pane:createBlock();
	itemsBlock.widthProportional = 1.0;
	itemsBlock.autoHeight = true;
	itemsBlock.paddingBottom = 13;
	itemsBlock:createLabel({text = "Когда предметы, которые лежат на\nконтейнере мешают анимации :"});
	local itemsButton = itemsBlock:createButton({ text = itemsButtonText[this.config.items] });
	itemsButton.absolutePosAlignX = tItemsButtonAlign[this.config.items];
	itemsButton.paddingLeft = 9;
	itemsButton.paddingRight = 9;

	itemsButton:register("mouseClick", function(e)
		this.config.items = itemsButtonText[this.config.items + 1] and this.config.items + 1 or 0;
		-- tes3.messageBox(itemsButtonText[this.config.items]);
		itemsButton.text = itemsButtonText[this.config.items];
		itemsButton.absolutePosAlignX = tItemsButtonAlign[this.config.items];
		-- pane:updateLayout();
	end)

	local barrelBlock = pane:createBlock();
	barrelBlock.flowDirection = "left_to_right";
	barrelBlock.widthProportional = 1.0;
	barrelBlock.autoHeight = true;
	barrelBlock:createLabel({ text = 'Модель бочки с заклепками :' })

	local playSoundButton = barrelBlock:createButton({ text = this.config.barrelRivet and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value });
	playSoundButton.absolutePosAlignX = 0.4;
	playSoundButton:register("mouseClick", function(e)
		tes3.messageBox('После изменения этой опции вам необходимо перезапустить игру');
		this.config.barrelRivet = not this.config.barrelRivet;
		playSoundButton.text = this.config.barrelRivet and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value;
	end)

	local sliderBlock = pane:createBlock();
	sliderBlock.widthProportional = 1.0;
	sliderBlock.autoHeight = true;
	sliderBlock:createLabel({text = "Процент от времени анимации, которое\nтребуется для отображения содержимого контейнера :"});
	local sliderValue = this.config.animTimeToWait;
	local sliderLabel = sliderBlock:createLabel({ text = tostring(sliderValue) });
    sliderLabel.absolutePosAlignX = 0.57;
    sliderLabel.minWidth = 30;

	local slider = sliderBlock:createSlider({ current = sliderValue, max = 200 , step = 1, jump = 25 });
	slider.borderLeft = 20;
    slider.absolutePosAlignY = 1.0;
	slider.width = 330;
	slider:register("PartScrollBar_changed", function(e)
		this.config.animTimeToWait = slider:getPropertyInt("PartScrollBar_current");
		sliderLabel.text = this.config.animTimeToWait;
	end);



	-- local skipAnimKeyBlock = pane:createBlock();

	-- skipAnimKeyBlock.widthProportional = 0.6;
	-- skipAnimKeyBlock.autoHeight = true;
	-- skipAnimKeyBlock:createLabel({text = 'Container animation will be skipped if\nactivated while this key is pressed down'});

	-- skipAnimKeyBlock.flowDirection = "left_to_right"
	-- skipAnimKeyButton = skipAnimKeyBlock:createButton({ text = GetKeybindName(this.config.skipAnimKey)});
	-- skipAnimKeyButton.absolutePosAlignX = 1.0;
	-- skipAnimKeyButton.paddingTop = 2;
	-- skipAnimKeyButton.borderRight = 6;
	-- skipAnimKeyButton:register("mouseClick", function(e)
		-- tes3.messageBox('mouseClick');
		-- skipAnimKeyButton.widget.state = 4;
		-- pane:updateLayout();
		-- event.register("keyDown", KeybindDown);
	-- end);
end

local function KeybindDown(e)
-- If keycode not ESC
	tes3.messageBox('key pressed %s', GetKeybindName(e.keyCode));
	if e.keyCode ~= 1 then
		this.config.skipAnimKey = e.keyCode;
		skipAnimKeyButton.text = GetKeybindName(e.keyCode);
	end
	skipAnimKeyButton.widget.state = 1;
	pane:updateLayout();
    
    event.unregister("keyDown", KeybindDown);
end

return this;