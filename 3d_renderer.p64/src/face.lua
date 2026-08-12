local V0_COL = 0
local V1_COL = 1
local V2_COL = 2
local V3_COL = 3
local C_COL = 4

local FACES_LEN = 7

local SORT_IDX_COL = 0
local SORT_Z_COL = 1
local SORT_TEMP_COL = 2

local SORT_LEN = 3
local VERTICES_LEN = 4


local L_X0_COL = 0
local L_Y0_COL = 1
local L_X1_COL = 2
local L_Y1_COL = 3
local L_C_COL = 4
local L_LEN = 5

local ud_util = require("src.userdata")

local lines_buffer = userdata("f64", L_LEN, SCREEN_HEIGHT)
for i = 0, SCREEN_HEIGHT - 1 do
  lines_buffer:set(L_Y0_COL, i, i)
  lines_buffer:set(L_Y1_COL, i, i)
end

---@class Face
---@field v0 integer
---@field v1 integer
---@field v2 integer
---@field v3 integer
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
function faces.of(vs)
  local self = faces.new(#vs)
  for _, v in ipairs(vs) do
    self:add(v)
  end
  ud_util.debugh(self.data)
  return self
end

---@param face Face
function Faces:add(face)
  assert(self.length < self.capacity)
  self.data:set(V0_COL, self.length, face.v0, face.v1, face.v2, face.v3, face.c)
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
function Faces:draw_faces(draw_vertices)
  -- z-ordering
  -- todo: is sorting by centroid right?  may be a smarter way  
  local z_idx = self.data:mul(VERTICES_LEN):add(2)

  draw_vertices.data:take(z_idx, self.sort, 0, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  self.sort:copy(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  draw_vertices.data:take(z_idx, self.sort, 1, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  draw_vertices.data:take(z_idx, self.sort, 2, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  draw_vertices.data:take(z_idx, self.sort, 3, SORT_TEMP_COL, 1, FACES_LEN, SORT_LEN, self.length)
  self.sort:add(self.sort, true, SORT_TEMP_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)
  self.sort:mul(0.25, true, SORT_Z_COL, SORT_Z_COL, 1, SORT_LEN, SORT_LEN, self.length)

  -- self.sort:sort(SORT_Z_COL, false)
  self.data:sort(SORT_Z_COL, true)

  -- ud_util.debug(self.sort)

  local drawn = 0
  for i = 0, self.length-1 do
  -- for i = 0, 0 do
    local idx, z = self.sort:get(SORT_IDX_COL, i, 2)
    local v0, v1, v2, v3, c = self.data:get(0, idx, 6)

    if z < FOCAL_LENGTH then
      break
    else

      -- todo: only for drawn lines
      lines_buffer:copy(-1)
      lines_buffer:copy(c, true, L_C_COL, L_C_COL, 1, L_LEN, L_LEN, SCREEN_HEIGHT)
    
      local x0, y0, z0 = draw_vertices.data:get(0, v0, 3)
      local x1, y1, z1 = draw_vertices.data:get(0, v1, 3)
      local x2, y2, z2 = draw_vertices.data:get(0, v2, 3)
      local x3, y3, z3 = draw_vertices.data:get(0, v3, 3)

      -- backface culling
      -- assume coplanar points
      -- take vector perpindicular to the plane formed by v0->v3, v0->v1 as the normal
      local p1 = {x = x3-x0, y = y3-y0, z = z3-z0}
      local p2 = {x = x1-x0, y = y1-y0, z = z1-z0}
      local n = {
        x = p1.y * p2.z - p2.y * p1.z,
        y = p1.x * p2.z - p2.x * p1.z,
        z = p1.x * p2.y - p2.x * p1.y,
      }
      -- i think since this is camera space I can just dot with (0, 0, -1) and check if positive?
      local n_dot_camera = -n.z
      if n_dot_camera < 0 then
        --continue
      else

        local points = {
          [0] = {x = x0, y = y0},
          [1] = {x = x1, y = y1},
          [2] = {x = x2, y = y2},
          [3] = {x = x3, y = y3},
        }

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

        local left_y
        local right_y
        local left_y_final = 0
        local right_y_final = 0

        if y_min < 0 then
          local i_next = (y_min_i + 1) % 4
          local i_prev = (y_min_i + 3) % 4

          local p = points[y_min_i]

          do
            local q = points[i_prev]
            local x_int = (q.x - p.x) * (0 - p.y) / (q.y - p.y) + p.x
            lines_buffer:set(L_X0_COL, 0, x_int)
          end
          do
            local q = points[i_next]
            local x_int = (q.x - p.x) * (0 - p.y) / (q.y - p.y) + p.x
            lines_buffer:set(L_X1_COL, 0, x_int)
          end

          left_y = 0
          right_y = 0
        else
          local p = points[y_min_i]
          lines_buffer:set(L_X0_COL, flr(y_min), p.x)
          lines_buffer:set(L_X1_COL, flr(y_min), p.x)
          left_y = flr(y_min)
          right_y = flr(y_min)
        end

        if y_max > SCREEN_HEIGHT - 1  then
          local i_next = (y_max_i + 1) % 4
          local i_prev = (y_max_i + 3) % 4

          local p = points[y_max_i]

          do
            local q = points[i_prev]
            local x_int = (q.x - p.x) * (SCREEN_HEIGHT - 1 - p.y) / (q.y - p.y) + p.x
            lines_buffer:set(L_X0_COL, SCREEN_HEIGHT - 1, x_int)
          end
          do
            local q = points[i_next]
            local x_int = (q.x - p.x) * (SCREEN_HEIGHT - 1 - p.y) / (q.y - p.y) + p.x
            lines_buffer:set(L_X1_COL, SCREEN_HEIGHT - 1, x_int)
          end

          left_y_final = 0
          right_y_final = 0
        else
          local p = points[y_max_i]
          lines_buffer:set(L_X0_COL, flr(y_max), p.x)
          lines_buffer:set(L_X1_COL, flr(y_max), p.x)
          left_y_final = flr(y_max)
          right_y_final = flr(y_max)
        end

        y_min = flr(y_min)
        y_max = flr(y_max)

        -- fill left endpoints
        -- go ccw until reached max point
        do
          local j = y_min_i
          while true do
            j = (j + 3) % 4
            if j == y_max_i then
              local len = left_y_final - left_y
              lines_buffer:lerp(left_y * L_LEN + L_X0_COL, len, L_LEN, 1)
              break
            else
              local left_y_next = flr(points[j].y)
              local len = left_y_next - left_y
              lines_buffer:set(L_X0_COL, left_y_next, points[j].x)
              lines_buffer:lerp(left_y * L_LEN + L_X0_COL, len, L_LEN, 1)
              left_y = left_y_next
            end
          end
        end

        -- fill right endpoints
        -- go cw until reached max point
        do
          local j = y_min_i
          while true do
            j = (j + 1) % 4
            if j == y_max_i then
              local len = right_y_final - right_y
              lines_buffer:lerp(right_y * L_LEN + L_X1_COL, len, L_LEN, 1)
              break
            else
              local right_y_next = flr(points[j].y)
              local len = right_y_next - right_y
              lines_buffer:set(L_X1_COL, right_y_next, points[j].x)
              lines_buffer:lerp(right_y * L_LEN + L_X1_COL, len, L_LEN, 1)
              right_y = right_y_next
            end
          end
        end

        local len = y_max - y_min
        line(lines_buffer, L_LEN * y_min, len, 5, L_LEN)    
        drawn = drawn + 1
      end
    end
  end

  return drawn
end

return faces
