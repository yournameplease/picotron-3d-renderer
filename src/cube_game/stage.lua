local scene = require("src.scene")

-- half screen vectors
FOCAL_LENGTH = 2
U_0 = SCREEN_WIDTH / 2
V_0 = SCREEN_HEIGHT / 2
-- ALPHA_U = F * U_0
-- ALPHA_V = -F * V_0
ALPHA_U = 128
ALPHA_V = 128


---@alias TileFlags integer

---@class Stage
---@field scene Scene
---@field tiles TileFlags[][][]
---@field camera Camera

local Stage = {}
Stage.__index = Stage

local stage = {}

function stage.new(m, w, h, d)
  local origin = vec(0, -h / 2,  d/2)

  
  local self = setmetatable({
    tiles = {}
  }, Stage)


  local scene_builder = scene.builder()
    
    scene_builder:add_billboard(
      vec(-3, -4, 5),
      5
    )
  local getm = function(x, y, z)
    return m:get(x + y * w, z) or 0
  end
  
  for x = 0, w-1 do
    self.tiles[x] = {}
    for y = 0, h-1 do
      self.tiles[x][y] = {}
      for z = 0, d-1 do
        local tile = getm(x, y, z)
        
        self.tiles[x][y][z] = fget(tile)

        for x_step = -1, 1, 2 do
          local neighbor = getm(x+x_step, y, z)
          if neighbor == 0 and not fget(neighbor, 0) then
            local o = origin + vec(x + 0.5 * x_step, y + 0.5 * x_step, z + 0.5 * x_step)
            local i_hat = vec(0, x_step, 0)
            local j_hat = vec(0, 0, x_step)
            scene_builder:add_plane(o, i_hat, j_hat, tile)
          end
        end
        for y_step = -1, 1, 2 do
          local neighbor = getm(x, y+y_step, z)
          if neighbor == 0 and not fget(neighbor, 0) then
            local o = origin + vec(x + 0.5 * y_step, y + 0.5 * y_step, z + 0.5 * y_step)
            local i_hat = vec(y_step, 0, 0)
            local j_hat = vec(0, 0, y_step)
            scene_builder:add_plane(o, i_hat, j_hat, tile)
          end
        end
        for z_step = -1, 1, 2 do
          local neighbor = getm(x, y, z+z_step)
          if neighbor == 0 and not fget(neighbor, 0) then
            local o = origin + vec(x + 0.5 * z_step, y + 0.5 * z_step, z + 0.5 * z_step)
            local i_hat = vec(z_step, 0, 0)
            local j_hat = vec(0, z_step, 0)
            scene_builder:add_plane(o, i_hat, j_hat, tile)
          end
        end
      end
    end

    scene_builder:add_axes(vec(0, 0, 0))
    -- scene_builder:add_axes(origin)
    self.scene = scene_builder:build()

    self.camera = {
      pos = vec(0, 5, -5),
      -- pitch = 0, roll = 0, yaw = 0.25
      pitch = -0.2, roll = 0, yaw = 0
    }
    self.scene.camera = self.camera
    

    return self
  end

    
end

return stage
