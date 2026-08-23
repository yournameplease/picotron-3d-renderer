local scene = require("src.scene")

---@alias TileFlags integer

---@class Stage
---@field scene Scene
---@field tiles TileFlags[][][]

local Stage = {}
Stage.__index = Stage

local stage = {}

function stage.new(m, w, h, d)
  local self = setmetatable({
    tiles = {}
  }, Stage)


  local scene_builder = scene.builder()
    
  for x = 0, w-1 do
    self.tiles[x] = {}
    for y = 0, h-1 do
      self.tiles[x][y] = {}
      for z = 0, d-1 do
        local tile = m:get(x + y * z, z)
        
        self.tiles[x][y][z] = fget(tile)


        
      end
    end
  end

    
end
