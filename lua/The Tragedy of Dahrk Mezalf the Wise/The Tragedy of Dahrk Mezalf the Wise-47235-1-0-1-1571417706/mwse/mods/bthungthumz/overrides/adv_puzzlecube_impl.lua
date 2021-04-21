local this = LuaScript.new();
local cube = require("bthungthumz.puzzleCube");

function this:initialized()
  local puzzle = cube:create();
  puzzle.onSolved = function ()
    tes3.messageBox("You hear a click and the box opens.");
    mwse.log("[Bthungthumz] Puzzle solved");
    
    tes3.addItem({ reference = tes3.player, item = "HT_Note" });
    
    tes3.setJournalIndex({ id = "adv_puzzlecube_bthungthumz", index = 100 });
  end;
  
  mwse.log("[Bthungthumz] puzzlecube override initialized");
end

function this:execute()
  if tes3.getJournalIndex({ id = "adv_puzzlecube_bthungthumz" }) < 20 then
    tes3.setJournalIndex({ id = "adv_puzzlecube_bthungthumz", index = 20 });
  end
  
  mwse.log("[Bthungthumz] puzzlecube override executed");
  
  puzzle:showMenu();
end

return this;