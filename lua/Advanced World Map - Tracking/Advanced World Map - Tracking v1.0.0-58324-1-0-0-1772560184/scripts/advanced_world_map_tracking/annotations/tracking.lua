---@class AdvancedWorldMap.Event.EVENT
local EVENT = {
    onTrackingTooltipShow = "onTrackingTooltipShow", -- event triggered before showing a tracking marker tooltip; returning true from a handler will prevent the tooltip from being shown
}

---@class AdvancedWorldMap.Event.onTrackingTooltipShowEvent
---@field content Content
---@field markerId string
---@field templateId string?
---@field markerUserData any
---@field templateUserData any
---@field object GameObject?


---@class AdvWMap_tracking.Position
---@field id string? -- nil for exterior cells
---@field pos Vector3

---@class AdvWMap_tracking.onClickCallbackParams
---@field button integer
---@field marker AdvWMap_tracking.MarkerData
---@field template AdvWMap_tracking.TemplateData
---@field object GameObject?

---@class AdvWMap_tracking.TemplateData
---@field path string
---@field pathA string?
---@field pathB string?
---@field layer string? -- default: "marker"
---@field size Vector2
---@field color Color?
---@field anchor Vector2?
---@field tText string|string[]|nil -- tooltip text
---@field tEvent boolean?
---@field temp boolean? -- Default: true
---@field short boolean?
---@field userData any?
---@field visible boolean? -- Default: true
---@field invalid boolean? -- set to true when the template is removed; do not set this manually
---@field onClick fun(e: AdvWMap_tracking.onClickCallbackParams)|string|nil


---@class AdvWMap_tracking.MarkerData
---@field template AdvWMap_tracking.TemplateData|string -- template ID or template data table
---@field positions AdvWMap_tracking.Position[]? -- list of positions to mark
---@field objects GameObject[]? -- list of objects to mark
---@field records string[]? -- object record IDs to mark
---@field types string[]? -- types from openmw.types. E.g., "NPC", "Creature", "Container", etc.
---@field zoomOut boolean? -- default: false. If true, the marker will be shown on zoomed-out map levels.
---@field alive boolean? -- default: false. If true, only alive actors will be marked.
---@field distance number? -- maximum distance from the player for the marker to be visible.
---@field item string? -- item ID. If set, only objects that have this item in their inventory will be marked. Onresolved objects are assumed to have the item.
---@field priority number? -- default: 0. Higher priority markers are shown on top.
---@field temp boolean? -- default: true. If true, the marker will not be saved to the game save.
---@field short boolean? -- default: false. If true, the marker will be removed when the map is closed.
---@field single boolean? if true, position markers will not be grouped
---@field active boolean? -- default: false. If true, the marker will be hidden when the object is no longer active.
---@field activeEx boolean? -- default: false. If true, the marker will be hidden when the object is no longer active in exterior cells
---@field userData any?
---@field invalid boolean? -- set to true when the marker is removed or its object is deleted; do not set this manually
---@field isVisibleFn (fun(marker: AdvWMap_tracking.MarkerData, template: AdvWMap_tracking.TemplateData, object: GameObject?):boolean)|nil -- function to determine if the marker is visible
---@field objValidateFn (fun(marker: AdvWMap_tracking.MarkerData, template: AdvWMap_tracking.TemplateData, object: GameObject):boolean)|nil -- function to validate the object for the marker


---@class AdvWMap_tracking.Interface
---@field version integer
---@field isInitialized fun(): boolean
---@field addMarker fun(params: AdvWMap_tracking.MarkerData): string
---@field removeMarker fun(id: string): boolean
---@field addTemplate fun(params: AdvWMap_tracking.TemplateData): string
---@field removeTemplate fun(id: string): boolean
---@field setTemplateVisibility fun(id: string, isVisible: boolean): boolean
---@field getTemplate fun(id: string): AdvWMap_tracking.TemplateData?
---@field getMarker fun(id: string): AdvWMap_tracking.MarkerData?
---@field isValid fun(id: string): boolean -- returns false if the marker/template has been removed
---@field getMarkers fun(groupId: string): AdvWMap_tracking.MarkerData[] -- returns markers for the specified group (cell ID for position markers, '__objects__' for object markers, '__types__' for type markers, '__records__' for record markers or object ID/type/recordId for object-based markers); returns an empty list if no markers are found
---@field update fun()