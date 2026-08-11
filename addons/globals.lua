---@meta
---@diagnostic disable missing-fields
--- Game-specific globals for Tactics Tales.
--- These are injected at runtime by main.tl / picotron_shim.tl.

---@alias LogLevel "NONE"|"ERROR"|"WARN"|"INFO"|"DEBUG"|"TRACE"
---@alias Angle number
---@alias Path string
---@alias CardinalDirection "up"|"down"|"left"|"right"

---@class StaticConfig
---@field SCREEN_WIDTH integer
---@field SCREEN_HEIGHT integer
---@field MAP_WIDTH integer
---@field MAP_HEIGHT integer
---@field TILE_WIDTH integer
---@field TILE_HEIGHT integer
---@field WALL_HEIGHT integer

--- Logger injected by debug.tl.
---@type Logger
log = {}

--- Global runtime configuration (mutable).
---@type DynamicConfig
DYNAMIC_CONFIG = {}

--- Global static configuration (read-only after init).
---@type StaticConfig
STATIC_CONFIG = {}

--- Data path prefix for asset loading.
---@type string
DATP = ""

--- Shared library table exposed to mods.
---@type {[string]: any}
lib = {}
