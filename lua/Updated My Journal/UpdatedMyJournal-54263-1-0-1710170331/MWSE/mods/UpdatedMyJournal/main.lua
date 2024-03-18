local inputMenu = {};
local inputText;
local inputCapture;
local helpString;
local isWriting = false;

local function writeJournalEntry() 

	isWriting = true;

    inputMenu = tes3ui.createMenu{ id = KRX_ID_JournalEntryCaptureMenu, fixedFrame = true };
	inputMenu.alpha = 1;
	
	local helpString;
	helpString = "Write the new journal entry and press Alt+Enter to save it. Press Escape to cancel.";

    local label = inputMenu:createLabel{ text = helpString };
    label.borderBottom = 11;
	
	local inputBlock = inputMenu:createBlock{};
	inputBlock.width = 800;
	inputBlock.autoHeight = true;

	inputCapture = inputBlock:createParagraphInput{};
	inputCapture.width = 800;
	inputCapture.widget.lengthLimit = 450;
	
	tes3ui.acquireTextInput(inputCapture);
end

local function saveJournalEntry()
	inputText = inputCapture.text;
	tes3ui.leaveMenuMode(KRX_ID_JournalEntryCaptureMenu);
	inputMenu:destroy();
	tes3.addJournalEntry({ text = inputText });
	tes3.messageBox({ message = "Your journal has been updated." });
	tes3ui.findMenu('MenuJournal'):destroy();
end

local function onKeyDown(e)
	if (tes3ui.findMenu('MenuJournal') == nil) then return end;
	
    if (e.isAltDown and e.keyCode == tes3.scanCode.enter) then
		if (isWriting) then
			isWriting = false;
			saveJournalEntry();
		else
			tes3ui.enterMenuMode(KRX_ID_JournalEntryCaptureMenu);
			writeJournalEntry();
		end
	else
		if (e.keyCode == tes3.scanCode.esc) then
			isWriting = false;
			tes3ui.leaveMenuMode();
			inputMenu:destroy();
			tes3ui.findMenu('MenuJournal'):destroy();
		end
    end
end

local function onEnterJournal(e)
	if (e.menu.name == "MenuJournal") then
		event.register("keyDown", onKeyDown);
	end
end

local function onExitJournal(e)
	event.unregister("keyDown", onKeyDown);
end

local function initialize()	
    KRX_ID_JournalEntryCaptureMenu = tes3ui.registerID("KRX_JournalEntryCaptureMenu");
	event.register("menuEnter", onEnterJournal);
	event.register("menuExit", onExitJournal);
end

event.register("initialized", initialize);