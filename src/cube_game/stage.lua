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
---@field is_grounded boolean
---@field can_jump boolean
---@field dy number
---@field dy_max number
---@field dy_jump number
---@field grav number

---@alias TileFlags integer

---@class Stage
---@field scene Scene
---@field w integer
---@field h integer
---@field d integer
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
    w = w,
    h = h,
    d = d,
    h_border = 0x1, -- solid border
    origin = origin,
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
    pos = origin + vec(2, 5, 2),
    angle = 0,
    speed = 0.1,
    half_w = 0.3,
    height = 0.8,
    dy = 0,
    dy_jump = 0.2,
    grav = 0.01,
    dy_max = 0.3,
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

---@param v Vec3
function Stage:mget(v)
  local x = flr(v.x - self.origin.x)
  local y = flr(v.y - self.origin.y)
  local z = flr(v.z - self.origin.z)

  if x < 0 or z < 0 or x >= self.w or z >= self.d then
    return self.h_border
    -- return 0
  end
  if y < 0 or y >= self.h then
    return 0
  end

  return self.tiles[x][y][z]
end

function Stage:try_move(a, dir)
  local hw = a.half_w
  local h = a.height

  local offsets = {
    vec(hw, 0, hw),
    vec(-hw, 0, hw),
    vec(-hw, 0, -hw),
    vec(hw, 0, -hw),
    vec(hw, h, hw),
    vec(-hw, h, hw),
    vec(-hw, h, -hw),
    vec(hw, h, -hw),
  }

  local test_pos = a.pos + dir
  local v_move = true
  for _,o in ipairs(offsets) do
    local tile = self:mget(test_pos + o)
    if tile & 0x01 ~= 0 then
      -- printh("hitting tile: ".. tile)
      v_move = false
      break
    end
  end

  if v_move then
    a.pos.y = test_pos.y
    a.pos.x = a.pos.x + dir.x
    a.pos.z = a.pos.z + dir.z
  end

  
end

function Stage:update(dt)
  self.scene:update(dt)

  local p = self.player

  local joy = {
    x = 0, y = 0
  }
  if btn(0) then joy.x = joy.x - 1 end
  if btn(1) then joy.x = joy.x + 1 end
  if btn(2) then joy.y = joy.y - 1 end
  if btn(3) then joy.y = joy.y + 1 end

  local frame_x = p.speed * vec(math.cos(self.camera.yaw), 0, math.sin(self.camera.yaw))
  local frame_z = p.speed * vec(math.sin(self.camera.yaw), 0, -math.cos(self.camera.yaw))

  local h_step = joy.x * frame_x + joy.y * frame_z 
  self:try_move(p, vec(h_step.x, 0, 0))
  self:try_move(p, vec(0, 0, h_step.z))

  -- if h_step.x ~= 0 and h_step.z ~= 0 then
  --   self.player.angle = math.atan(h_step.z, h_step.x)
  -- end
  p.angle = self.camera.yaw


  p.dy = p.dy - p.grav
  p.dy = mid(-p.dy_max, p.dy, p.dy_max)

  if btnp(5) and p.can_jump then
    p.dy = p.dy_jump
    p.can_jump = false
  end

  local dy = vec(0., p.dy, 0.)
  self:try_move(p, dy)


  do
    self.player.is_grounded = false
    local hw = self.player. half_w
    local dh = 0.3 * self.player.height
    local offsets = {
      vec(hw, -dh, hw),
      vec(-hw, -dh, hw),
      vec(-hw, -dh, -hw),
      vec(hw, -dh, -hw),
    }

    for _,o in ipairs(offsets) do
      local tile = self:mget(self.player.pos + o)
      if tile & 0x01 ~= 0 then
        p.is_grounded = true
        break
      end
    end
  end

  if p.is_grounded then
    self.player.can_jump = true
  end
  
end

function Stage:draw()
  for _,a in ipairs(self.actors) do
    local v0 = a.v0
    local pos = a.pos
    local ang = a.angle
    local h_step = vec(a.half_w * math.cos(ang), 0, a.half_w * math.sin(ang))
    local v_step = vec(0, a.height, 0)

    self.scene.vertices:move(v0 + 1, pos + h_step + v_step)
    self.scene.vertices:move(v0 + 3, pos - h_step + v_step)
    self.scene.vertices:move(v0 + 0, pos + h_step)
    self.scene.vertices:move(v0 + 2, pos - h_step)
  end

  self.scene:draw()
end

return stage
