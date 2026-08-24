local faces = require("src.face")
local lines = require("src.line")
local vertices = require("src.vertex")
local billboards = require("src.billboard")
local ud_util = require("src.userdata")
local dither = require("src.dither")
local lighting = require("src.lighting")

local IS_ISO = true
local BUFFER_MAX = 1024
local buf = userdata("f64", BUFFER_MAX)

COLOR_TABLE_ADDRS = {
  [0] = 0x8000,
  0x9000,
  0xA000,
  0xB000,
}

function apply_color_table(color_table_sprite, idx)
  idx = idx or 0
	local sprite=get_spr(color_table_sprite)
	--copy the sprite into the address 0x8000 in memory
	memmap(sprite,COLOR_TABLE_ADDRS[idx])
	--poke the bit that makes it work for shapes(circ,rect etc.), the bit for sprites
	--is already set by default.
	poke(0x550b,0x3f)
	--the color table got copied and will be used. This is the same color table 
	--that pal() modifies.
end

function apply_color_tables()
  apply_color_table(8, 0)
  -- apply_color_table(8, 1)
  apply_color_table(10, 2)
  -- apply_color_table(10, 3)
end

---@param v Vertex
---@return Vertex
function vector_normalize(v)
  local mag = v:dot(v) ^ 0.5
  if mag < EPSILON then
    return vec(0, 0, 0)
  end
  return vec(v.x / mag, v.y / mag, v.z / mag)
end

---@class Camera
---@field pos Vertex
---@field pitch number
---@field roll number
---@field yaw number

---@class SceneBuilder
---@field vertices Vertex[]
---@field faces Face[]
---@field lines Line[]
---@field billboards Billboard[]
local SceneBuilder = {}
SceneBuilder.__index = SceneBuilder

---@class Scene
---@field t number
---@field vertices Vertices
---@field vertices_screen Vertices
---@field lines Lines
---@field faces Faces
---@field billboards Billboards
---@field world_to_cam userdata
---@field cam_to_screen userdata
---@field world_to_screen userdata
---@field camera Camera
---@field camera_prev Camera
---@field camera_next Camera
---@field camera_anim_t number
---@field camera_anim_dur number
---@field camera_anim_easing function
---@field lighting LightingRamp
local Scene = {}
Scene.__index = Scene

function Scene:update(dt)
  self.t = self.t + dt


  if self.camera_anim_dur and self.camera_anim_t <= self.camera_anim_dur then
    self.camera_anim_t = self.camera_anim_t + dt
    local t = self.camera_anim_t / self.camera_anim_dur
    self.camera.pos = vec(
      self.camera_anim_easing(self.camera_prev.pos.x, self.camera_next.pos.x, t),
      self.camera_anim_easing(self.camera_prev.pos.y, self.camera_next.pos.y, t),
      self.camera_anim_easing(self.camera_prev.pos.z, self.camera_next.pos.z, t)
    )
    self.camera.pitch = self.camera_anim_easing(self.camera_prev.pitch, self.camera_next.pitch, t)
    self.camera.roll = self.camera_anim_easing(self.camera_prev.roll, self.camera_next.roll, t)
    self.camera.yaw = self.camera_anim_easing(self.camera_prev.yaw, self.camera_next.yaw, t)
  end
end

function Scene:animate_camera(new, duration, easing)
  self.camera_prev = {
    pos = self.camera.pos:copy(),
    pitch = self.camera.pitch,
    roll = self.camera.roll,
    yaw = self.camera.yaw,
  }
  self.camera_next = new
  self.camera_anim_dur = duration
  self.camera_anim_t = 0
  self.camera_anim_easing = easing
end

function Scene:draw(debug)
  profile("draw_setup")
  local light = vector_normalize(vec(cos(1 / 20), -2, sin(0.2 + 1 / 20)))
  
  local a = self.camera.pitch
  local b = self.camera.yaw
  local g = self.camera.roll
  self.world_to_cam:set(0, 0,
    math.cos(b)*math.cos(g), -math.cos(b)*math.sin(g), math.sin(b), -self.camera.pos.x, -- magic minus sign :O
    -math.cos(a)*math.sin(g)-math.sin(a)*math.sin(b)*math.cos(g), -math.cos(a)*math.cos(g)+math.sin(a)*math.sin(b)*math.sin(g), math.sin(a)*math.cos(b), self.camera.pos.y,
    math.sin(a)*math.sin(g)-math.cos(a)*math.sin(b)*math.cos(g), math.sin(a)*math.cos(g)+math.cos(a)*math.sin(b)*math.sin(g), math.cos(a)*math.cos(b), -self.camera.pos.z,
    0, 0, 0, 1
  )
  self.world_to_cam:transpose(true)

  self.world_to_cam:matmul(self.cam_to_screen, self.world_to_screen)

  profile("draw_setup")
  profile("transform_vertices")
  color(5)
  self.vertices:transform(self.vertices_screen.data, self.world_to_screen)


  if not IS_ISO then
    self.vertices_screen.data.div(1, self.vertices_screen.data, self.vertices_screen.data, 2, 2, 1, 4, 4, self.vertices_screen.length)
    -- self.vertices_screen.data:div(self.vertices_screen.data, true, 3, 2, 1, 4, 4, v_proj.length)
    self.vertices_screen.data:mul(self.vertices_screen.data, true, 2, 0, 1, 4, 4, self.vertices_screen.length)
    self.vertices_screen.data:mul(self.vertices_screen.data, true, 2, 1, 1, 4, 4, self.vertices_screen.length)
  else
    -- self.vertices_screen.data.div(1, self.vertices_screen.data, self.vertices_screen.data, 2, 2, 1, 4, 4, self.vertices_screen.length)
    -- -- self.vertices_screen.data:div(self.vertices_screen.data, true, 3, 2, 1, 4, 4, v_proj.length)
    -- self.vertices_screen.data:mul(self.vertices_screen.data, true, 2, 0, 1, 4, 4, self.vertices_screen.length)
    -- self.vertices_screen.data:mul(self.vertices_screen.data, true, 2, 1, 1, 4, 4, self.vertices_screen.length)
    self.vertices_screen.data.div(-1, self.vertices_screen.data, self.vertices_screen.data, 2, 2, 1, 4, 4, self.vertices_screen.length)
  -- ud_util.debug(self.vertices_screen.data)
  end

  profile("transform_vertices")

  profile("draw_faces")
  local faces_drawn = self.faces:draw_faces(self.vertices_screen, light, self.lighting, IS_ISO)
  profile("draw_faces")

  profile("draw_billboards")
  self.billboards:draw(self.vertices_screen)
  profile("draw_billboards")

  profile("draw_lines")
  self.lines:draw(self.vertices_screen)
  profile("draw_lines")

  if debug then
    color(7)
    self.faces:draw_wireframes(self.vertices_screen, buf)
  
    color(8)
    pset(self.vertices_screen.data, 0, self.vertices_screen.length, 2, 4)
  end

  print("CPU: " .. stat(1), 400, 3, 7)
  print("MEM: " .. stat(0))
  print("FPS: " .. stat(7))
  color(6)
  print("CAM: " .. self.camera.pos.x .. "," .. self.camera.pos.y .. "," .. self.camera.pos.z)
  print("VERTICES: " .. self.vertices.length)
  print("FACES: " .. faces_drawn .."/".. self.faces.length)

  color(6)
end

local scene = {}

function scene.builder()
  return setmetatable({
    vertices = {},
    faces = {},
    lines = {},
    billboards = {},
  }, SceneBuilder)
end

---@return Scene
function SceneBuilder.build(builder)
  local self = setmetatable({
    t = 0
  }, Scene)

  apply_color_tables()

  self.vertices = vertices.of(builder.vertices)
  self.faces = faces.of(builder.faces, builder.vertices)
  self.lines = lines.of(builder.lines)
  self.billboards = billboards.of(builder.billboards)

  self.vertices_screen = vertices.of(builder.vertices)

  self.world_to_cam = userdata("f64", 4, 4)
  self.cam_to_screen = userdata("f64", 4, 4)
  -- perspective divide
  if not IS_ISO then
    self.cam_to_screen:set(0, 0,
      ALPHA_U, 0, 0, 0,
      0, ALPHA_V, 0, 0,
      U_0, V_0, 1, 0,
      0, 0, 0, 1
    )
  else
    -- self.cam_to_screen:set(0, 0,
    --   ALPHA_U, 0, 0, 0,
    --   0, ALPHA_V, 0, 0,
    --   0, 0, 0, 0,
    --   3*U_0, 3*V_0, 3, 1
    -- )
    local r = 5
    local l = -5
    local t = 5
    local b = -5
    local f = 10
    local n = 7
    self.cam_to_screen:set(0, 0,
      2 / (r - l) * ALPHA_U, 0, 0, 0,
      0, 2 / (t - b) * ALPHA_V, 0, 0,
      0, 0, -2 / (f - n), 0,
      - (r + l) / (r - l) + U_0, - (t + b) / (t - b) + V_0, -(f + n) / (f - n), 1
    )
  end
  self.world_to_screen = userdata("f64", 4, 4)
  
  self.lighting = lighting.new()

  return self
end
 
function SceneBuilder:add_billboard(p, s)
  local v_start = #self.vertices
  add(self.vertices, p)
  add(self.billboards, {
    s = s,
    v = v_start,
  })
end

function SceneBuilder:add_axes(p)
  local v_start = #self.vertices
  add(self.vertices, p)
  local s = 1
  -- add(self.vertices, p + vec(s, 0, 0))
  -- add(self.vertices, p + vec(0, s, 0))
  -- add(self.vertices, p + vec(0, 0, s))
  add(self.vertices, vec(p.x + s, p.y + 0, p.z + 0))
  add(self.vertices, vec(p.x + 0, p.y + s, p.z + 0))
  add(self.vertices, vec(p.x + 0, p.y + 0, p.z + s))

  add(self.lines, {v0 = v_start, v1 = v_start + 1, c = 8})
  add(self.lines, {v0 = v_start, v1 = v_start + 2, c = 11})
  add(self.lines, {v0 = v_start, v1 = v_start + 3, c = 12})
end
  
function SceneBuilder:add_plane(o, i_hat, j_hat, s)
  local v_start = #self.vertices

  for i = 0, 1 do
    for j = 0, 1 do
      add(self.vertices, o + i * i_hat + j * j_hat)
    end
  end

  add(self.faces, {
    s = s,
    v0 = v_start+0, v0_u = 0, v0_v = 0,
    v1 = v_start+1, v1_u = 16, v1_v = 0,
    v2 = v_start+3, v2_u = 16, v2_v = 16,
    v3 = v_start+2, v3_u = 0, v3_v = 16,
  })
end  

function SceneBuilder:add_cube(o, i_hat, j_hat, k_hat, s)
  local v_start = #self.vertices

  for i = 0, 1 do
    for j = 0, 1 do
      for k = 0, 1 do
        add(self.vertices, o + i * i_hat + j * j_hat + k * k_hat)
      end
    end
  end

  add(self.faces, {
    s = s,
    v0 = v_start+0, v0_u = 0, v0_v = 0,
    v1 = v_start+2, v1_u = 16, v1_v = 0,
    v2 = v_start+3, v2_u = 16, v2_v = 16,
    v3 = v_start+1, v3_u = 0, v3_v = 16,
  })
  add(self.faces, {
    s = s,
    v0 = v_start+4, v0_u = 0, v0_v = 0,
    v1 = v_start+5, v1_u = 16, v1_v = 0,
    v2 = v_start+7, v2_u = 16, v2_v = 16,
    v3 = v_start+6, v3_u = 0, v3_v = 16,
  })
  add(self.faces, {
    s = s,
    v0 = v_start+0, v0_u = 0, v0_v = 0,
    v1 = v_start+1, v1_u = 16, v1_v = 0,
    v2 = v_start+5, v2_u = 16, v2_v = 16,
    v3 = v_start+4, v3_u = 0, v3_v = 16,
  })
  add(self.faces, {
    s = s,
    v0 = v_start+2, v0_u = 0, v0_v = 0,
    v1 = v_start+6, v1_u = 16, v1_v = 0,
    v2 = v_start+7, v2_u = 16, v2_v = 16,
    v3 = v_start+3, v3_u = 0, v3_v = 16,
  })
  add(self.faces, {
    s = s,
    v0 = v_start+0, v0_u = 0, v0_v = 0,
    v1 = v_start+4, v1_u = 16, v1_v = 0,
    v2 = v_start+6, v2_u = 16, v2_v = 16,
    v3 = v_start+2, v3_u = 0, v3_v = 16,
  })
  add(self.faces, {
    s = s,
    v0 = v_start+1, v0_u = 0, v0_v = 0,
    v1 = v_start+3, v1_u = 16, v1_v = 0,
    v2 = v_start+7, v2_u = 16, v2_v = 16,
    v3 = v_start+5, v3_u = 0, v3_v = 16,
  })
end

function SceneBuilder:add_sphere(o, r, ring_vertices, layers, s)
  local v_start = #self.vertices
  add(self.vertices, o - vec(0, r, 0))

  for i = 1, layers - 1 do
    local t = 2 * i / (layers) - 1
    local y = t * r
    local small_r = r * sqrt(1 - t^2)

    for j = 0, ring_vertices-1 do
      local theta = 2 * math.pi * j / ring_vertices
      local p = o + vec(
          small_r * math.cos(theta),
          y,
          small_r * math.sin(theta))
        
      add(self.vertices, p)
    end
  end

  add(self.vertices, o + vec(0, r, 0))

  printh(v_start)
  local v_min = v_start
  local v_max = v_start + ring_vertices * (layers - 1) + 1
  -- for i = -1, layers-2 do
  for i = -1, layers-2 do
    for j = 0, ring_vertices-1 do
      local y_top = i + 1
      local y_bottom = i
      local x_left = j
      local x_right = (j + 1) % ring_vertices
      local v_0 = mid(v_min, v_start + 1 + ring_vertices * y_top + x_left, v_max)
      local v_1 = mid(v_min, v_start + 1 + ring_vertices * y_top + x_right, v_max)
      local v_2 = mid(v_min, v_start + 1 + ring_vertices * y_bottom + x_right, v_max)
      local v_3 = mid(v_min, v_start + 1 + ring_vertices * y_bottom + x_left, v_max)
      add(self.faces, {
        s = s,
        v0 = v_0, v0_u = 0, v0_v = 0,
        v1 = v_3, v1_u = 16, v1_v = 0,
        v2 = v_2, v2_u = 16, v2_v = 16,
        v3 = v_1, v3_u = 0, v3_v = 16,
      })
      printh(i..","..j..": "..tostr(vec(v_0, v_1, v_2, v_3)))
    end
  end
end

return scene
