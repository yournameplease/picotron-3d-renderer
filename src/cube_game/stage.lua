local scene = require("src.scene")

-- half screen vectors
FOCAL_LENGTH = 2
U_0 = SCREEN_WIDTH / 2
V_0 = SCREEN_HEIGHT / 2
-- ALPHA_U = F * U_0
-- ALPHA_V = -F * V_0
ALPHA_U = 128
ALPHA_V = 128


---@class Actor
---@field v0 integer
---@field face integer
---@field half_w number
---@field height number
---@field pos Vec3
---@field angle number


---@class Player : Actor
---@field speed number
---@field fric number

---@alias TileFlags integer

---@class Stage
---@field scene Scene
---@field tiles TileFlags[][][]
---@field camera Camera
---@field actors Actor[]
---@field player Player

local Stage = {}
Stage.__index = Stage

local stage = {}

function stage.new(m, w, h, d, n)
  local origin = vec(-w / 2, -h / 2,  -d/2)

  
  local self = setmetatable({
    tiles = {},
    actors = {},
  }, Stage)


  local scene_builder = scene.builder()
    
  local getm = function(x, y, z)
    if x < 0 or y < 0 or z < 0 then return 0 end
    if x >= w or y >= h or z >=d then return 0 end
    
    return m:get(x + y * w, (d * n)+ d-1-z) or 0
  end
  
  for x = 0, w-1 do
    self.tiles[x] = {}
    for y = 0, h-1 do
      self.tiles[x][y] = {}
      for z = 0, d-1 do
        local tile = getm(x, y, z)
        printh("TILE:"..x .. "," .. y .. "," .. z .. ": ".. tile)
        
        self.tiles[x][y][z] = fget(tile)

        if tile ~= 0 then
          for x_step = -1, 1, 2 do
            local neighbor = getm(x+x_step, y, z)
            if neighbor == 0 or not fget(neighbor, 0) then
              printh("got it "..x .. "," .. y .. "," .. z .. "," .. x_step)
              local offset = (x_step + 1) / 2
              local o = origin + vec(x + offset, y, z)
              local i_hat = offset == 0 and vec(0, 1, 0) or vec(0, 0, 1)
              local j_hat = offset == 0 and vec(0, 0, 1) or vec(0, 1, 0)
              scene_builder:add_plane(o, i_hat, j_hat, tile)
            end
          end
          for y_step = -1, 1, 2 do
            local neighbor = getm(x, y+y_step, z)
            if neighbor == 0 or not fget(neighbor, 0) then
              local offset = (y_step + 1) / 2
              local o = origin + vec(x, y + offset, z)
              local i_hat = offset == 0 and vec(0, 0, 1) or vec(1, 0, 0)
              local j_hat = offset == 0 and vec(1, 0, 0) or vec(0, 0, 1)
              scene_builder:add_plane(o, i_hat, j_hat, tile)
            end
          end
          for z_step = -1, 1, 2 do
            local neighbor = getm(x, y, z+z_step)
            if neighbor == 0 or not fget(neighbor, 0) then
              local offset = (z_step + 1) / 2
              local o = origin + vec(x, y, z + offset)
              local i_hat = offset == 0 and vec(1, 0, 0) or vec(0, 1, 0)
              local j_hat = offset == 0 and vec(0, 1, 0) or vec(1, 0, 0)
              scene_builder:add_plane(o, i_hat, j_hat, tile)
            end
          end
        end
      end
    end
  end

  -- player
  self.player = {
    v0 = #scene_builder.vertices,
    face = #scene_builder.faces,
    pos = vec(0, 1, 0),
    angle = 0,
    half_w = 0.3,
    height = 0.8,
  }
  scene_builder:add_plane(vec(0, 0, 0), vec(2*self.player.half_w, 0, 0), vec(0, self.player.height, 0), 33, true)

  add(self.actors, self.player)

  -- scene_builder:add_axes(vec(0, 0, 0))
  -- scene_builder:add_axes(origin)
  self.scene = scene_builder:build()

  self.camera = {
    -- pos = vec(0, 1, -d * 1.5),
    pos = vec(0, 0, 0),
    -- pitch = 0, roll = 0, yaw = 0.25
    -- I assume something is wrong, this should be pi/6
    pitch = -math.pi / 5.3, roll = 0, yaw = -math.pi / 4
  }
  self.scene.camera = self.camera
  

  return self
    
end

function Stage:update(dt)


end

function Stage:draw()
  for _,a in ipairs(self.actors) do
    local v0 = a.v0
    local pos = a.pos
    local ang = a.angle
    local h_step = vec(a.half_w * math.cos(ang), 0, a.half_w * math.sin(ang))
    -- local h_step = vec(a.half_w * math.sin(ang), 0, a.half_w * math.cos(ang))
    -- local h_step = vec(a.half_w, 0, 0)
    local v_step = vec(0, a.height, 0)

    color(8)
    print(tostr(pos) .. ", " .. tostr(h_step) .. ", " .. tostring(v_step))
    
    self.scene.vertices:move(v0 + 1, pos + h_step + v_step)
    self.scene.vertices:move(v0 + 3, pos - h_step + v_step)
    self.scene.vertices:move(v0 + 0, pos + h_step)
    self.scene.vertices:move(v0 + 2, pos - h_step)
  end

  self.scene:draw()
end

return stage
