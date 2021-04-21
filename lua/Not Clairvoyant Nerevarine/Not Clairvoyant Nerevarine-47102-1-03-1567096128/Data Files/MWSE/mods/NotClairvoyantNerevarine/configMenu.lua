	

local modConfigMenu = {};
local pane;
local this = {};
local buttonText;
local loc = require("NotClairvoyantNerevarine.localization");
local sLang;


local function GetLanguage()
	local file = io.open("Morrowind.ini","r");
	local lines = file:read("*all")

	if string.find(lines, 'Language=French', 1, true) then
		file:close();
		return 'fre';
	end

	file:close();
	return 'eng';
end


local function RegisterModConfig()
	sLang = GetLanguage();
	this.sLang = sLang;
	if tes3.isModActive('Not Clairvoyant Nerevarine.esp') then
		mwse.registerModConfig(loc.MCMmodName[sLang], modConfigMenu);
	end
end
 -- fires before initialized event
event.register("modConfigReady", RegisterModConfig);


function modConfigMenu.onClose(container)
    mwse.saveConfig('NotClairvoyantNerevarine_config', this.config);
end


function UpdateButtonText(button)
	if this.config.barterRevealOnlyNames then
		button.text = loc.MCMonlyName[sLang];
	else
		button.text = loc.MCMprop[sLang];
	end
end


function modConfigMenu.onCreate(container)
	-- tes3.messageBox('onCreate');
	pane = container:createThinBorder{};
	pane.widthProportional = 1.0;
	pane.heightProportional = 1.0;
	pane.paddingAllSides = 12;
    pane.flowDirection = "top_to_bottom";

    local header = pane:createLabel{ text = 'version 1.03' };
	header.color = tes3ui.getPalette("header_color");
    header.borderBottom = 35;

	local block = pane:createBlock();
	block.flowDirection = "left_to_right";
	block.widthProportional = 1.0;
	block.autoHeight = true;

	block:createLabel({ text = loc.MCMwhenBart[sLang] });
	local button = block:createButton({ text = '' });
	if sLang == 'fre' then
		button.absolutePosAlignX = 0.8;
	else
		button.absolutePosAlignX = 0.3;
	end
	-- button.paddingTop = 2;
	button:register("mouseClick", function(e)
		this.config.barterRevealOnlyNames = not this.config.barterRevealOnlyNames;
		UpdateButtonText(button);
	end);
	UpdateButtonText(button);
--[[
	local ExtLightsOffButton = ExtLightsOffBlock:createButton({ text = this.config.barterRevealOnlyNames and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value });
	ExtLightsOffButton.absolutePosAlignX = 0.4;
	-- ExtLightsOffButton.paddingTop = 2;
	ExtLightsOffButton:register("mouseClick", function(e)
		this.config.barterRevealOnlyNames = not this.config.barterRevealOnlyNames;
		ExtLightsOffButton.text = this.config.barterRevealOnlyNames and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value;
	end)
--]]
end

return this;