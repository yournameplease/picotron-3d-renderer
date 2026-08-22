local face = require("src.face")
local vertex = require("src.vertex")
local ud_util = require("src.userdata")

---@class SceneBuilder
---@field vertices Vertex[]
---@field faces Face[]
---@field billboards Billboard[]
local SceneBuilder = {}
SceneBuilder.__index = SceneBuilder

local scene = {}

function scene.builder()
  return setmetatable({
    vertices = {},
    faces = {},
    billboards = {},
  }, SceneBuilder)
end
 
function SceneBuilder:add_billboard(p, s)
  local v_start = #self.vertices
  add(self.vertices, p)
  add(self.billboards, {
    s = s,
    v = v_start,
  })
end
  
function SceneBuilder:add_plane(o, i_hat, j_hat, s)
  local v_start = #self.vertices

  for i = -1, 1, 2 do
    for j = -1, 1, 2 do
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
