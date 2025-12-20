---@meta AdvancedWorldMap.Interface

---@class AdvancedWorldMap.Interface.UIElements
---@field scrollBox fun(params: any): Layout creates a scroll box
---@field button fun(params: any): Layout creates a button
---@field borders fun(): Layout[] creates borders
---@field checkbox fun(params: any): Layout creates a checkbox
---@field interval fun(width: number, height: number): Layout creates an interval

---@class AdvancedWorldMap.Interface
---@field version integer version of the interface
---@field events AdvancedWorldMap.Event event system
---@field openMapMenu fun(inMenuMode: boolean) opens the world map menu
---@field toggleMapMenu fun() toggles the world map menu
---@field getConfig fun() : table gets the current configuration
---@field isDiscovered fun(cellId: string) : boolean checks if the cell with the given ID is discovered
---@field isVisited fun(cellId: string) : number? checks if the cell with the given ID is visited. Returns timestamp or nil
---@field uiElements AdvancedWorldMap.Interface.UIElements