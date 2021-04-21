local puzzleCube = {
    bgTexture = "textures/puzzlecube/puzzle_background.dds",
    bgWidth = 1024,
    bgHeight = 1024,

    -- The maximum proportion of the screen that can be taken up by
    -- the menu
    maxSizeProportion = 0.9,

    -- The size in pixels the tile should display on screen at full scale
    tileWidth = 192,
    tileHeight = 192,

    -- The actual size of the tile texture, including the transparent padding
    tileTxWidth = 256,
    tileTxHeight = 256,
    tiles = {
        "textures/puzzlecube/tile1.dds",
        "textures/puzzlecube/tile2.dds",
        "textures/puzzlecube/tile3.dds",
        "textures/puzzlecube/tile4.dds",
        "textures/puzzlecube/tile5.dds",
        "textures/puzzlecube/tile6.dds",
        "textures/puzzlecube/tile7.dds",
        "textures/puzzlecube/tile8.dds",
        "textures/puzzlecube/tile9.dds",
        "textures/puzzlecube/tile10.dds",
        "textures/puzzlecube/tile11.dds",
        "textures/puzzlecube/tile12.dds",
        "textures/puzzlecube/tile13.dds",
        "textures/puzzlecube/tile14.dds",
        "textures/puzzlecube/tile15.dds"
    },

    emptyTexture = "textures/puzzlecube/tile_blank.dds",

    initialState = {{5,2,9,4},{1,-1,3,7},{15,6,14,11},{8,13,10,12}},
    solvedState =  {{1,2,3,4},{5,6,7,8},{9,10,11,12},{13,14,15,-1}},
    emptyTilePos = { x = 2, y = 2 },
    
    solved = false
};

function puzzleCube:create(o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;

    o.state = o.initialState;
    o.dimensions = self:calcDimensions();

    o.gui_ids = {
        container = tes3ui.registerID("bthungthumz_puzzlecube_container");
    };

    return o;
end

function puzzleCube:calcDimensions()
    local o = {};
    o.screenSize = { width = mge.getScreenWidth(), height = mge.getScreenHeight() };
    o.uiScale = mge.getUIScale();

    -- The proportion of the screen taken up by the base textures, unscaled
    o.baseScale = {
        width = self.bgWidth * o.uiScale / o.screenSize.width,
        height = self.bgHeight * o.uiScale / o.screenSize.height
    };
    -- The result calculated scale
    o.scale = 1.0;

    if o.baseScale.height > self.maxSizeProportion then
        o.heightLimited = true;
        o.scale = self.maxSizeProportion / o.baseScale.height;
    end
    if (o.baseScale.width > self.maxSizeProportion)
      and (o.baseScale.width > o.baseScale.height) then
        o.widthLimited = true;
        o.heightLimited = false
        o.scale = self.maxSizeProportion / o.baseScale.width;
    end

    o.bgSize = { width = math.floor(o.scale * self.bgWidth), height = math.floor(o.scale * self.bgHeight) };
    o.tileSize = { width = math.floor(o.scale * self.tileWidth), height = math.floor(o.scale * self.tileHeight) };
    
    -- Other than the three result values, also return intermediates for debugging purposes
    return o;
end

function puzzleCube:showMenu()
    if (tes3ui.findMenu(self.gui_ids["container"]) ~= nil) then
        -- Do not create a second copy of the menu
        return
    end


    local topContainer = tes3ui.createMenu({ id = self.gui_ids["container"], fixedFrame = true });
    topContainer.alpha = 1.0;
    topContainer.paddingAllSides = 0;
    self.topContainer = topContainer;

    local bgImage = topContainer:createImage({ path = self.bgTexture });
    bgImage.width = self.dimensions.bgSize.width;
    bgImage.height = self.dimensions.bgSize.height;
    bgImage.scaleMode = true;
    bgImage.absolutePosAlignX = 0.5;
    bgImage.absolutePosAlignY = 0.5;
    bgImage.consumeMouseEvents = false
    self.bgImage = bgImage;
    
    local puzzleContainer = topContainer:createBlock();
    puzzleContainer.width = self.dimensions.bgSize.width;
    puzzleContainer.height = self.dimensions.bgSize.height;
    self.puzzleContainer = puzzleContainer;

    local puzzleArea = puzzleContainer:createBlock();
    puzzleArea.width = 4*self.dimensions.tileSize.width;
    puzzleArea.height = 4*self.dimensions.tileSize.height;
    puzzleArea.absolutePosAlignX = 0.5;
    puzzleArea.absolutePosAlignY = 0.5;
    puzzleArea.childAlignX = 0.5;
    puzzleArea.flowDirection = "top_to_bottom";
    self.puzzleArea = puzzleArea;
    
    local exitButton = topContainer:createButton();
    exitButton.text = "Exit";
    exitButton.absolutePosAlignX = 0.5;
    exitButton.absolutePosAlignY = 1.0;
    exitButton.borderAllSides = 20;
    exitButton.color = { 0, 0, 0 };
    exitButton.consumeMouseEvents = true;
    exitButton:register("mouseClick", function ()
      tes3ui.leaveMenuMode(self.gui_ids["container"]);
      topContainer:destroy();
    
      if self.onExit ~= nil then
        self.onExit();
      end
    end);

    self:drawTiles(false);
    topContainer:updateLayout();
    tes3ui.enterMenuMode(self.gui_ids["container"]);
end

function puzzleCube:drawTiles(clearFirst)
    if clearFirst then
        self.puzzleArea:destroyChildren();
    end

    for y,row in ipairs(self.state) do
        local rowBlock = self.puzzleArea:createBlock();
        rowBlock.autoWidth = true;
        rowBlock.height = self.dimensions.tileSize.height;
        rowBlock.borderAllSides = 0;

        for x,cell in ipairs(row) do
            local tilePath
            if cell == -1 then
                tilePath = self.emptyTexture;
            else
                tilePath = self.tiles[cell];
            end

            local tile = rowBlock:createImage({ path = tilePath });
            tile.width = self.dimensions.tileSize.width;
            tile.height = self.dimensions.tileSize.height;
            tile.imageScaleX = self.dimensions.scale;
            tile.imageScaleY = self.dimensions.scale;

            tile.consumeMouseEvents = true;
            tile:register("mouseClick", function() self:moveTile(x,y) end);
        end
    end
end

function puzzleCube:moveTile(x,y)
    if self.solved then
      -- Prevent interacting with the puzzle after solving it
      return
    end

    local isAdjacentToSpace = function(x,y)
        return (math.abs(x - self.emptyTilePos.x) == 1 and y == self.emptyTilePos.y)
           or (math.abs(y - self.emptyTilePos.y) == 1 and x == self.emptyTilePos.x);
    end;

    -- If the current tile can't be moved, do nothing.
    if not isAdjacentToSpace(x,y) then
        return;
    end

    -- Switch the current tile with the empty tile
    local tileValue = self.state[y][x];
    
    self.state[self.emptyTilePos.y][self.emptyTilePos.x] = tileValue;
    self.state[y][x] = -1;

    -- Update the coordinates of the empty tile
    self.emptyTilePos = { x = x, y = y };

    -- Redraw the puzzle
    self:drawTiles(true);
    self.topContainer:updateLayout();

    if self:isSolved() then
        self.solved = true;
        
        if self.onSolved ~= nil then
            self.onSolved();
        end
    end
end

function puzzleCube:isSolved()
    for y,row in ipairs(self.state) do
        for x,cell in ipairs(row) do
            if cell ~= self.solvedState[y][x] then
                return false;
            end
        end
    end
    return true;
end

return puzzleCube;