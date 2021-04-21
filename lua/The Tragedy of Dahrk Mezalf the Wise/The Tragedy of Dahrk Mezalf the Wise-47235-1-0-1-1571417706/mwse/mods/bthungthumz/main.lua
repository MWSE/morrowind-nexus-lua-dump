local cube = require("bthungthumz.puzzleCube");
local puzzle;
local inPuzzle = false;

local scriptOverride = function()  
  if tes3.getJournalIndex({ id = "adv_puzzlecube_bthungthumz" }) < 20 then
    mwse.log("Setting journal index: puzzle examined");
    tes3.updateJournal({ id = "adv_puzzlecube_bthungthumz", index = 20, showMessage = false });
  end
  
  mwse.log("[Bthungthumz] puzzlecube override executed");
  
  inPuzzle = true;  
  puzzle:showMenu();
  
  -- Only execute once
  mwscript.stopScript({script = "adv_puzzlecube_impl"});
end

event.register("initialized", function ()
  puzzle = cube:create();
  puzzle.onSolved = function ()
    tes3.messageBox("You hear a click and the box opens.  You find a note inside the cube.");
    mwse.log("[Bthungthumz] Puzzle solved");
    
    tes3.addItem({ reference = tes3.player, item = "HT_Note" });
    
    tes3.updateJournal({ id = "adv_puzzlecube_bthungthumz", index = 100 });
  end;
  puzzle.onExit = function ()
    inPuzzle = false;
  end;
  
  mwse.overrideScript("adv_puzzlecube_impl", scriptOverride);
  
  mwse.log("[Bthungthumz] puzzlecube override initialized");
end);

local puzzleWall;
local soundActivator;
local puzzleWallInitialized = false;
local yPositions = { 3022.4, 3075.1, 3127.8, 3180.5 };
local yDiff = 52.7;
local zPositions = { 13850.5, 13805.2, 13759.9, 13714.6 };
local zDiff = -45.3;
local tiles = {};

-- Round towards zero
local function round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end
  
local initPuzzle = function(cell)
  if cell.id ~= "Bthungthumz, Lower Levels" then
    return;
  end;
  
  puzzleWallInitialized = true;
  
  for ref in cell:iterateReferences() do
    if ref.id == "DRP_PuzzleWall" then
      puzzleWall = ref;
    end
    
    if ref.id == "DRP_PuzzleWall_Sound" then
      soundActivator = ref;
    end
    
    local tileNum = string.match(ref.id, "DRP_Puzzlewall_Tile(%d%d)");
    
    if tileNum then
      tiles[tonumber(tileNum)+1] = ref;
    end
  end
  
  if not puzzleWall then
    mwse.log("[Bthungthumz] failed to find puzzle wall static");
  end
  
  if not puzzleWall.data.DRP then
    mwse.log("[Bthungthumz] creating puzzle wall data");
    puzzleWall.data.DRP = {
      state = {{-1,-1,-1,-1},{-1,-1,-1,-1},{-1,-1,-1,-1},{-1,-1,-1,-1}},
      solvedState = {{1,2,3,4},{5,6,7,8},{9,10,11,12},{13,14,15,-1}},
      solved = false
    };
  end
  
  puzzleWall.modified = true;
    
  -- Locate tiles in the grid setup
  for k,tile in ipairs(tiles) do
    local yRel = round((tile.position.y - yPositions[1]) / yDiff);
    local zRel = round((tile.position.z - zPositions[1]) / zDiff);
    
    puzzleWall.data.DRP.state[zRel+1][yRel+1] = k;
    
    -- Reposition the tiles just in case
    tile.position.y = yPositions[yRel+1];
    tile.position.z = zPositions[zRel+1];
    
    tile.modified = true;
  end
  
  -- Locate the empty tile  
  for k,v in ipairs(puzzleWall.data.DRP.state) do
    for j,u in ipairs(v) do
      if u == -1 then
        puzzleWall.data.DRP.emptyTilePos = { x = j, y = k };
        break;
      end
    end
  end
  
end

-- Returns true if the tile coordinates given are orthogonally adjacent to the empty tile
local isAdjacentToSpace = function(x,y)
  local emptyTilePos = puzzleWall.data.DRP.emptyTilePos;
  
  return (math.abs(x - emptyTilePos.x) == 1 and y == emptyTilePos.y)
      or (math.abs(y - emptyTilePos.y) == 1 and x == emptyTilePos.x);
end;

local puzzleIsSolved = function()
  for y,row in ipairs(puzzleWall.data.DRP.state) do
      for x,cell in ipairs(row) do
          if cell ~= puzzleWall.data.DRP.solvedState[y][x] then
              return false;
          end
      end
  end
  
  return true;
end;

local wallStartPos
local wallSpeed = -26;

local moveDown = function(ref, deltaZ)
  local newPos = ref.position:copy();
  
  newPos.z = ref.position.z + deltaZ;
  
  ref.position = newPos;
end;

local moveWall

-- Declaration separated so it can refer to itself... hopefully
moveWall = function(e)
  local deltaPos = e.delta * wallSpeed;
  
  moveDown(puzzleWall, deltaPos);
  
  for _,v in ipairs(tiles) do
    moveDown(v, deltaPos);
  end
  
  if wallStartPos - puzzleWall.position.z > 290 then
    mwscript.stopSound({
      sound = "Door Stone Close",
      reference = soundActivator
    });
    event.unregister("simulate", moveWall);
  end
end;

event.register("activate", function (e)
  if e.activator ~= tes3.player then
    return;
  end
  
  if not puzzleWall or puzzleWall.data.DRP.solved then
    return;
  end
    
  -- Get the number of the tile activated, or nil if not a tile
  local tileNum = string.match(e.target.id, "DRP_Puzzlewall_Tile(%d%d)");
  
  if not tileNum then
    return
  end
  
  tileNum = tonumber(tileNum) + 1;
  
  local x
  local y
  
  -- Get the grid coordinates of the activated tile
  for k,v in ipairs(puzzleWall.data.DRP.state) do
    for j,u in ipairs(v) do
      if tileNum == u then
        x = j;
        y = k;
        break;
      end
    end
  end
  
  local emptyTilePos = puzzleWall.data.DRP.emptyTilePos;
  
  if not isAdjacentToSpace(x,y) then
    return
  end
  
  tes3.playSound({
    sound = "Gate Large Locked"
  });
  
  puzzleWall.data.DRP.state[emptyTilePos.y][emptyTilePos.x] = tileNum;
  puzzleWall.data.DRP.state[y][x] = -1;
  
  local newPos = e.target.position:copy();
  newPos.y = yPositions[emptyTilePos.x];
  newPos.z = zPositions[emptyTilePos.y];
  
  e.target.position = newPos;
  -- tes3.positionCell({ cell = e.target.cell, position = newPos, orientation = e.target.orientation, reference = e.target });
  
  emptyTilePos.x = x;
  emptyTilePos.y = y;
  
  if puzzleIsSolved() then
    mwse.log("[Bthungthumz] puzzle wall solved.");
    tes3.messageBox("The wall slowly opens...");
    puzzleWall.data.DRP.solved = true;
    
    tes3.playSound({
      sound = "Door Stone Close",
      reference = soundActivator,
      loop = true
    });
    -- Delay the wall starting to open for effect
    timer.start({ duration = 0.5, callback = function () 
      wallStartPos = puzzleWall.position.z;
      event.register("simulate", moveWall);
    end});
  end
end);


event.register("loaded", function (e)
  puzzleWallInitialized = false;
  initPuzzle(tes3.getPlayerCell());
end);
    
event.register("cellChanged", function (e)
  if puzzleWallInitialized then
    return;
  end;
  initPuzzle(e.cell);
end);