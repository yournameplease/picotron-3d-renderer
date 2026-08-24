local V0_COL = 0
local V1_COL = 1
local V2_COL = 2
local V3_COL = 3
local NX_COL = 4
local NY_COL = 5
local NZ_COL = 6
local V0_U_COL = 7
local V0_V_COL = 8
local V1_U_COL = 9
local V1_V_COL = 10
local V2_U_COL = 11
local V2_V_COL = 12
local V3_U_COL = 13
local V3_V_COL = 14
local S_COL = 15
local C_COL = 16

local FACES_LEN = 17

local SORT_IDX_COL = 0
local SORT_Z_COL = 1
local SORT_TEMP_COL = 2

local SORT_LEN = 3
local VERTICES_LEN = 4


local L_S_COL = 0
local L_X0_COL = 1
local L_Y0_COL = 2
local L_X1_COL = 3
local L_Y1_COL = 4
local L_U0_COL = 5
local L_V0_COL = 6
local L_U1_COL = 7
local L_V1_COL = 8
local L_W0_COL = 9
local L_W1_COL = 10
local L_FLAGS_COL = 11
-- local L_C_COL = 4
local L_LEN = 12

local ud_util = require("src.userdata")

-- local TLINE_FLAGS = 0x300
local TLINE_FLAGS = 0x000

local lines_buffer = userdata("f64", L_LEN, SCREEN_HEIGHT)
for i = 0, SCREEN_HEIGHT - 1 do
  lines_buffer:set(L_Y0_COL, i, i)
  lines_buffer:set(L_Y1_COL, i, i)
end
lines_buffer:copy(TLINE_FLAGS, true, L_FLAGS_COL, L_FLAGS_COL, 1, L_LEN, L_LEN, SCREEN_HEIGHT)

---@class Face
---@field v0 integer
---@field v1 integer
---@field v2 integer
---@field v3 integer
---@field v0_u number
---@field v0_v number
---@field v1_u number
---@field v1_v number
---@field v2_u number
---@field v2_v number
---@field v3_u number
---@field v3_v number
---@field s integer
---@field c integer

---@class Faces
---@field data userdata
---@field sort userdata
---@field length integer
---@field capacity integer
local Faces = {}
Faces.__index = Faces
local faces = {}

---@param capacity integer
---@return Faces
function faces.new(capacity)
  local self = setmetatable({}, Faces)

  self.data = userdata("i32", FACES_LEN, capacity)
  self.sort = userdata("f64", SORT_LEN, capacity)
  for i = 0, capacity-1 do
    self.sort:set(SORT_IDX_COL, i, i)
  end
  self.length = 0
  self.capacity = capacity

  return self
end
 
---@param vs Face[]
---@return Faces
---@param vertices Vertex[]
function faces.of(vs, vertices)
  local self = faces.new(#vs)
  for _, v in ipairs(vs) do
    self:add(v, vertices)
  end
  -- ud_util.debugh(self.data)
  return self
end

---@param face Face
---@param vertices Vertex[]
function Faces:add(face, vertices)
  assert(self.length < self.capacity)

  local p1 = {
    x = vertices[1+face.v3].x-vertices[1+face.v0].x,
    y = vertices[1+face.v3].y-vertices[1+face.v0].y,
    z = vertices[1+face.v3].z-vertices[1+face.v0].z
  }
  local p2 = {
    x = vertices[1+face.v1].x-vertices[1+face.v0].x,
    y = vertices[1+face.v1].y-vertices[1+face.v0].y,
    z = vertices[1+face.v1].z-vertices[1+face.v0].z
  }
  local n = {
    x = p1.y * p2.z - p2.y * p1.z,
    y = p1.x * p2.z - p2.x * p1.z,
    z = p1.x * p2.y - p2.x * p1.y,
  }
  self.data:set(V0_COL, self.length, face.v0)
  self.data:set(V1_COL, self.length, face.v1)
  self.data:set(V2_COL, self.length, face.v2)
  self.data:set(V3_COL, self.length, face.v3)
  self.data:set(NX_COL, self.length, n.x)
  self.data:set(NY_COL, self.length, n.y)
  self.data:set(NZ_COL, self.length, n.z)
  self.data:set(V0_U_COL, self.length, face.v0_u)
  self.data:set(V0_V_COL, self.length, face.v0_v)
  self.data:set(V1_U_COL, self.length, face.v1_u)
  self.data:set(V1_V_COL, self.length, face.v1_v)
  self.data:set(V2_U_COL, self.length, face.v2_u)
  self.data:set(V2_V_COL, self.length, face.v2_v)
  self.data:set(V3_U_COL, self.length, face.v3_u)
  self.data:set(V3_V_COL, self.length, face.v3_v)
  self.data:set(S_COL, self.length, face.s)
  self.data:set(C_COL, self.length, face.c)
  self.length = self.length + 1
end

---@param draw_vertices Vertices
---@param buf userdata
function Faces:draw_wireframes(draw_vertices, buf)
  draw_vertices.data:take(self.data:mul(VERTICES_LEN), buf, 0, 0, 2, FACES_LEN, 10, self.length)
  draw_vertices.data:take(self.data:mul(VERTICES_LEN), buf, 1, 2, 2, FACES_LEN, 10, self.length)
  draw_vertices.data:take(self.data:mul(VERTICES_LEN), buf, 2, 4, 2, FACES_LEN, 10, self.length)
  draw_vertices.data:take(self.data:mul(VERTICES_LEN), buf, 3, 6, 2, FACES_LEN, 10, self.length)
  draw_vertices.data:take(self.data:mul(VERTICES_LEN), buf, 0, 8, 2, FACES_LEN, 10, self.length)

  for i = 0, self.length-2 do -- why -2?  for some reason last face looks wrong
    -- color(self.data[FACES_LEN * i + C_COL])
    line(buf, i * 10, 4, 4, 2)
  end
end

---@param draw_vertices Vertices
---@param l Vertex vector, really
---@param lighting LightingRamp
function Faces:draw_faces(draw_vertices, l, lighting, is_isometric)
  -- z-ordering
  -- todo: is sorting by centroid right?  may be a smarter way  
  profile("face_setup")
  local z_idx = self.data:mul(VERTICES_LEN):add(2)

  for i = 0, draw_vertices.length do
    self.sort:set(SORT_IDX_COL, i, i)
  end

  -- draw_vertices.data:take(z_idx, self.sort, 0, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  -- self.sort:copy(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  -- draw_vertices.data:take(z_idx, self.sort, 1, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  -- self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  -- draw_vertices.data:take(z_idx, self.sort, 2, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  -- self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  -- draw_vertices.data:take(z_idx, self.sort, 3, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  -- self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  -- self.sort:mul(0.25, true, SORT_Z_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)

  draw_vertices.data:take(z_idx, self.sort, 0, SORT_Z_COL, 1, FACES_LEN, SORT_LEN, self.length)
  
  -- self.sort:sort(SORT_Z_COL, true)
  self.sort:sort(SORT_Z_COL, false)
  -- self.data:sort(SORT_Z_COL, true)
  profile("face_setup")

  -- ud_util.debug(self.sort)

  local drawn = 0
  for i = 0, self.length-1 do
    profile("face_quad_get_row")
    local idx, z = self.sort:get(SORT_IDX_COL, i, 2)
    local v0, v1, v2, v3,
      nx, ny, nz,
      v0_u, v0_v,
      v1_u, v1_v,
      v2_u, v2_v,
      v3_u, v3_v,
      s
      = self.data:get(0, idx, 16)
    profile("face_quad_get_row")

    if not is_isometric and z > 1/FOCAL_LENGTH then
      break
    else

      profile("face_quad_get_verts")
      local x0, y0, z0 = draw_vertices.data:get(0, v0, 3)
      local x1, y1, z1 = draw_vertices.data:get(0, v1, 3)
      local x2, y2, z2 = draw_vertices.data:get(0, v2, 3)
      local x3, y3, z3 = draw_vertices.data:get(0, v3, 3)
      profile("face_quad_get_verts")

      -- backface culling
      -- assume coplanar points
      -- take vector perpindicular to the plane formed by v0->v3, v0->v1 as the normal
      profile("face_quad_compute_culling")
      local p1 = {x = x3-x0, y = y3-y0, z = (1/z3)-(1/z0)}
      local p2 = {x = x1-x0, y = y1-y0, z = (1/z1)-(1/z0)}
      local n = {
        x = p1.y * p2.z - p2.y * p1.z,
        y = p1.x * p2.z - p2.x * p1.z,
        z = p1.x * p2.y - p2.x * p1.y,
      }
      profile("face_quad_compute_culling")
      -- i think since this is camera space I can just dot with (0, 0, -1) and check if positive?
      local n_dot_camera = -n.z
      if n_dot_camera < 0 then
        goto continue
      end

      profile("face_quad_find_min_max_y")
      local points = {
        [0] = {x = x0, y = y0, w = z0, u = v0_u * z0, v = v0_v * z0},
        [1] = {x = x1, y = y1, w = z1, u = v1_u * z1, v = v1_v * z1},
        [2] = {x = x2, y = y2, w = z2, u = v2_u * z2, v = v2_v * z2},
        [3] = {x = x3, y = y3, w = z3, u = v3_u * z3, v = v3_v * z3},
        -- [0] = {x = x0, y = y0, w = -1/z0, u = -v0_u / z0, v = -v0_v / z0},
        -- [1] = {x = x1, y = y1, w = -1/z1, u = -v1_u / z1, v = -v1_v / z1},
        -- [2] = {x = x2, y = y2, w = -1/z2, u = -v2_u / z2, v = -v2_v / z2},
        -- [3] = {x = x3, y = y3, w = -1/z3, u = -v3_u / z3, v = -v3_v / z3},
      }

      -- print("Face "..i..": "..x0..","..y0..","..z0..","..x1..","..y1..","..z1..","..x2..","..y2..","..z2..","..x3..","..y3..","..z3)

      local y_min = 1e9
      local y_min_i
      local y_min_min_x = 1e9
      local y_min_max_x = 1e9
      local y_max = -1e9
      local y_max_i
  
      for j = 0,3 do
        local y = points[j].y
        if y < y_min then
          y_min_i = j 
          y_min = y
        end
        if y > y_max then
          y_max_i = j 
          y_max = y
        end
      end
      profile("face_quad_find_min_max_y")

      if y_min > SCREEN_HEIGHT - 1 then
        goto continue
      end
      if y_max < 0 then
        goto continue
      end
        
      profile("face_quad_compute_scanlines_min_max")
      local y_min_i_left = y_min_i 
      local y_min_i_right = y_min_i 
      local y_max_i_left = y_max_i
      local y_max_i_right = y_max_i

      local left_y
      local right_y
      local left_y_final = 0
      local right_y_final = 0

      if y_min < 0 then
        while points[(y_min_i_left + 3) % 4].y < 0 do
           y_min_i_left = (y_min_i_left + 3) % 4
        end
        while points[(y_min_i_right + 1) % 4].y < 0 do
           y_min_i_right = (y_min_i_right + 1) % 4
        end
        local i_next = (y_min_i_right + 1) % 4
        local i_prev = (y_min_i_left + 3) % 4

        do
          local p = points[y_min_i_left]
          local q = points[i_prev]
          local t = (0 - p.y) / (q.y - p.y)
          lines_buffer:set(L_X0_COL, 0, t * (q.x - p.x) + p.x)
          lines_buffer:set(L_U0_COL, 0, t * (q.u - p.u) + p.u)
          lines_buffer:set(L_V0_COL, 0, t * (q.v - p.v) + p.v)
          lines_buffer:set(L_W0_COL, 0, t * (q.w - p.w) + p.w)
        end
        do
          local p = points[y_min_i_right]
          local q = points[i_next]
          local t = (0 - p.y) / (q.y - p.y)
          lines_buffer:set(L_X1_COL, 0, t * (q.x - p.x) + p.x)
          lines_buffer:set(L_U1_COL, 0, t * (q.u - p.u) + p.u)
          lines_buffer:set(L_V1_COL, 0, t * (q.v - p.v) + p.v)
          lines_buffer:set(L_W1_COL, 0, t * (q.w - p.w) + p.w)
        end

        left_y = 0
        right_y = 0
      else
        local p = points[y_min_i]
        left_y = flr(y_min)
        right_y = flr(y_min)

        lines_buffer:set(L_X0_COL, left_y, p.x)
        lines_buffer:set(L_X1_COL, right_y, p.x)
        lines_buffer:set(L_U0_COL, left_y, p.u)
        lines_buffer:set(L_V0_COL, left_y, p.v)
        lines_buffer:set(L_U1_COL, right_y, p.u)
        lines_buffer:set(L_V1_COL, right_y, p.v)
        lines_buffer:set(L_W0_COL, left_y, p.w)
        lines_buffer:set(L_W1_COL, right_y, p.w)
      end

      if y_max > SCREEN_HEIGHT - 1  then
        while points[(y_max_i_left + 1) % 4].y > SCREEN_HEIGHT - 1 do
           y_max_i_left = (y_max_i_left + 1) % 4
        end
        while points[(y_max_i_right + 3) % 4].y > SCREEN_HEIGHT - 1 do
           y_max_i_right = (y_max_i_right + 3) % 4
        end
        local i_next = (y_max_i_left + 1) % 4
        local i_prev = (y_max_i_right + 3) % 4

        do
          local p = points[y_max_i_left]
          local q = points[i_next]
          local t = (SCREEN_HEIGHT - 1 - p.y) / (q.y - p.y)
          lines_buffer:set(L_X0_COL, SCREEN_HEIGHT - 1, t * (q.x - p.x) + p.x)
          lines_buffer:set(L_U0_COL, SCREEN_HEIGHT - 1, t * (q.u - p.u) + p.u)
          lines_buffer:set(L_V0_COL, SCREEN_HEIGHT - 1, t * (q.v - p.v) + p.v)
          lines_buffer:set(L_W0_COL, SCREEN_HEIGHT - 1, t * (q.w - p.w) + p.w)
        end
        do
          local p = points[y_max_i_right]
          local q = points[i_prev]
          local t = (SCREEN_HEIGHT - 1 - p.y) / (q.y - p.y)
          lines_buffer:set(L_X1_COL, SCREEN_HEIGHT - 1, t * (q.x - p.x) + p.x)
          lines_buffer:set(L_U1_COL, SCREEN_HEIGHT - 1, t * (q.u - p.u) + p.u)
          lines_buffer:set(L_V1_COL, SCREEN_HEIGHT - 1, t * (q.v - p.v) + p.v)
          lines_buffer:set(L_W1_COL, SCREEN_HEIGHT - 1, t * (q.w - p.w) + p.w)
        end

        left_y_final = SCREEN_HEIGHT - 1
        right_y_final = SCREEN_HEIGHT - 1
      else
        local p = points[y_max_i]
        left_y_final = flr(y_max)
        right_y_final = flr(y_max)

        lines_buffer:set(L_X0_COL, left_y_final, p.x)
        lines_buffer:set(L_X1_COL, right_y_final, p.x)
        lines_buffer:set(L_U0_COL, left_y_final, p.u)
        lines_buffer:set(L_V0_COL, left_y_final, p.v)
        lines_buffer:set(L_U1_COL, right_y_final, p.u)
        lines_buffer:set(L_V1_COL, right_y_final, p.v)
        lines_buffer:set(L_W0_COL, left_y_final, p.w)
        lines_buffer:set(L_W1_COL, right_y_final, p.w)
      end
      profile("face_quad_compute_scanlines_min_max")

      y_min = flr(y_min)
      y_max = flr(y_max)

      -- fill left endpoints
      -- go ccw until reached max point
      profile("face_quad_compute_scanlines_left")
      do
        local j = y_min_i_left
        while true do
          j = (j + 3) % 4
          if j == y_max_i_left then
            local len = left_y_final - left_y
            lines_buffer:lerp(left_y * L_LEN + L_X0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_U0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_V0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_W0_COL, len, L_LEN, 1)
            break
          else
            local left_y_next = flr(points[j].y)
            local len = left_y_next - left_y
            lines_buffer:set(L_X0_COL, left_y_next, points[j].x)
            lines_buffer:set(L_U0_COL, left_y_next, points[j].u)
            lines_buffer:set(L_V0_COL, left_y_next, points[j].v)
            lines_buffer:set(L_W0_COL, left_y_next, points[j].w)
            lines_buffer:lerp(left_y * L_LEN + L_X0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_U0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_V0_COL, len, L_LEN, 1)
            lines_buffer:lerp(left_y * L_LEN + L_W0_COL, len, L_LEN, 1)
            left_y = left_y_next
          end
        end
      end
      profile("face_quad_compute_scanlines_left")

      -- fill right endpoints
      -- go cw until reached max point
      profile("face_quad_compute_scanlines_right")
      do
        local j = y_min_i_right
        while true do
          j = (j + 1) % 4
          if j == y_max_i_right then
            local len = right_y_final - right_y
            lines_buffer:lerp(right_y * L_LEN + L_X1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_U1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_V1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_W1_COL, len, L_LEN, 1)
            break
          else
            local right_y_next = flr(points[j].y)
            local len = right_y_next - right_y
            lines_buffer:set(L_X1_COL, right_y_next, points[j].x)
            lines_buffer:set(L_U1_COL, right_y_next, points[j].u)
            lines_buffer:set(L_V1_COL, right_y_next, points[j].v)
            lines_buffer:set(L_W1_COL, right_y_next, points[j].w)
            lines_buffer:lerp(right_y * L_LEN + L_X1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_U1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_V1_COL, len, L_LEN, 1)
            lines_buffer:lerp(right_y * L_LEN + L_W1_COL, len, L_LEN, 1)
            right_y = right_y_next
          end
        end
      end
      profile("face_quad_compute_scanlines_right")

      local len = y_max - y_min

      profile("face_texture")
      local nf = vector_normalize(vec(nx, ny, nz))
      n_dot_l = nf.x * l.x + nf.y * l.y + nf.z * l.z
      -- ambient = 0.1
      -- 0.1 reserved for specular, if I get to it...
      n_dot_l = n_dot_l * 0.8 + 0.1
      lighting:set_lighting_table(n_dot_l)

      -- color(0xC000)
      -- lines_buffer:add(0xc0, true, L_X0_COL, L_X0_COL, 4, L_LEN, L_LEN, SCREEN_HEIGHT)
      lines_buffer:copy(s, true, L_S_COL, L_S_COL, 1, L_LEN, L_LEN, SCREEN_HEIGHT)
      
      -- ud_util.debug(lines_buffer, y_min, len)
      -- ud_util.debug(lines_buffer, L_LEN * y_min)
      tline3d(lines_buffer, L_LEN * y_min, len, 12, L_LEN)    

      lighting:clear()
      profile("face_texture")
     
      drawn = drawn + 1
    end
    ::continue::
  end

  return drawn
end

return faces
