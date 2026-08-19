
SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
EPSILON = 0.0001

-- half screen vectors
FOCAL_LENGTH = 2
U_0 = SCREEN_WIDTH / 2
V_0 = SCREEN_HEIGHT / 2
-- ALPHA_U = F * U_0
-- ALPHA_V = -F * V_0
ALPHA_U = 128
ALPHA_V = 128

local vertices = require("src.vertex")
local faces = require("src.face")

local BUFFER_MAX = 1024

-- vertices

local buf = userdata("f64", BUFFER_MAX)

local v
local f
local proj
local image
local world_to_cam
local cam_to_screen
local v_proj
local v_cam
-- todo: convert to userdata
local light = {x = 1, y = -2, z = -3}
local t = 0

local camera

function apply_color_table(color_table_sprite)
	local sprite=get_spr(color_table_sprite)
	--copy the sprite into the address 0x8000 in memory
	memmap(sprite,0x8000)
	--poke the bit that makes it work for shapes(circ,rect etc.), the bit for sprites
	--is already set by default.
	poke(0x550b,0x3f)
	--the color table got copied and will be used. This is the same color table 
	--that pal() modifies.
end

---@param vec Vertex
---@return Vertex
function vector_normalize(vec)
  local mag = (vec.x * vec.x + vec.y * vec.y + vec.z * vec.z) ^ 0.5
  if mag < EPSILON then
    return {x = 0, y = 0, z = 0}
  end
  return {x = vec.x / mag, y = vec.y / mag, z = vec.z / mag}
end

function _init()
  camera = {
    x = -2, y = 4, z = 2,
    -- pitch = 0, roll = 0, yaw = 0.25
    pitch = 0.1, roll = 0.1, yaw = 0
  }

  
  local cube_vertices = {}
  local cube_faces = {}

  local o = {x = 0, y = 0, z = 5}
  local i_hat = {x = 1, y = 0, z = 0}
  local j_hat = {x = 0, y = 1, z = 0}
  local k_hat = {x = 0, y = 0, z = 1}

  local GRID_S = 6
  -- local GRID_S = 2
  
  for l = 0, GRID_S-1 do
    for m = 0, GRID_S-1 do
      for i = 0, 1 do
        for j = 0, 1 do
          for k = 0, 1 do
            add(cube_vertices, {
              x = 3*l + o.x + i * i_hat.x + j * j_hat.x + k * k_hat.x,
              y = o.y + i * i_hat.y + j * j_hat.y + k * k_hat.y,
              z = 3*m + o.z + i * i_hat.z + j * j_hat.z + k * k_hat.z,
            })
          end
        end
      end

      local offset = 8*(l*GRID_S+m)
      local c = (l*GRID_S+m)%7+8
      local s = (l*GRID_S+m)%4+1
      
      add(cube_faces, {
        s = s,
        v0 = offset+0, v0_u = 0, v0_v = 0,
        v1 = offset+2, v1_u = 16, v1_v = 0,
        v2 = offset+3, v2_u = 16, v2_v = 16,
        v3 = offset+1, v3_u = 0, v3_v = 16,
        c = c
      }) -- 8})
      add(cube_faces, {
        s = s,
        v0 = offset+4, v0_u = 0, v0_v = 0,
        v1 = offset+5, v1_u = 16, v1_v = 0,
        v2 = offset+7, v2_u = 16, v2_v = 16,
        v3 = offset+6, v3_u = 0, v3_v = 16,
        c = c
      }) -- 9})
      add(cube_faces, {
        s = s,
        v0 = offset+0, v0_u = 0, v0_v = 0,
        v1 = offset+1, v1_u = 16, v1_v = 0,
        v2 = offset+5, v2_u = 16, v2_v = 16,
        v3 = offset+4, v3_u = 0, v3_v = 16,
        c = c
      }) -- 10})
      add(cube_faces, {
        s = s,
        v0 = offset+2, v0_u = 0, v0_v = 0,
        v1 = offset+6, v1_u = 16, v1_v = 0,
        v2 = offset+7, v2_u = 16, v2_v = 16,
        v3 = offset+3, v3_u = 0, v3_v = 16,
        c = c
      }) -- 11})
      add(cube_faces, {
        s = s,
        v0 = offset+0, v0_u = 0, v0_v = 0,
        v1 = offset+4, v1_u = 16, v1_v = 0,
        v2 = offset+6, v2_u = 16, v2_v = 16,
        v3 = offset+2, v3_u = 0, v3_v = 16,
        c = c
      }) -- 12})
      add(cube_faces, {
        s = s,
        v0 = offset+1, v0_u = 0, v0_v = 0,
        v1 = offset+3, v1_u = 16, v1_v = 0,
        v2 = offset+7, v2_u = 16, v2_v = 16,
        v3 = offset+5, v3_u = 0, v3_v = 16,
        c = c
      }) -- 13})
    end
  end

  world_to_cam = userdata("f64", 4, 4)
  world_to_cam:set(0, 0,
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    camera.x, camera.y, camera.z, 1
  )

  cam_to_screen = userdata("f64", 4, 4)
  cam_to_screen:set(0, 0,
    ALPHA_U, 0, U_0, 0,
    0, ALPHA_V, V_0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  )
  cam_to_screen:transpose(true)

  
  v = vertices.of(cube_vertices)
  v_proj = vertices.of(cube_vertices)
  v_cam = vertices.of(cube_vertices)


  light = vector_normalize(light)
  printh(light.x .. light.y .. light.z)

  f = faces.of(cube_faces, cube_vertices)

  apply_color_table(8)

  profile.enabled(true, true)
end



function _update()
  profile("update")
  t = t + 1/60
  
  if btn(0) then camera.x = camera.x - 0.1 end
  if btn(1) then camera.x = camera.x + 0.1 end
  if btn(2) then camera.z = camera.z - 0.1 end
  if btn(3) then camera.z = camera.z + 0.1 end
  if btn(4) then camera.y = camera.y + 0.1 end
  if btn(5) then camera.y = camera.y - 0.1 end
  
  -- currently pitch and yaw have their names flipped, i think
  if btn(8) then camera.pitch = camera.pitch - 0.001 end
  if btn(9) then camera.pitch = camera.pitch + 0.001 end
  if btn(10) then camera.yaw = camera.yaw + 0.001 end
  if btn(11) then camera.yaw = camera.yaw - 0.001 end
  if btn(14) then camera.roll = camera.roll - 0.001 end
  if btn(15) then camera.roll = camera.roll + 0.001 end
  profile("update")
end

function _draw()
  profile("draw_setup")
  light = vector_normalize({
    x = cos(t / 20),
    y = -2,
    z = sin(0.2 + t / 20)
  })

  
  local a = camera.yaw
  local b = camera.pitch
  local g = camera.roll
  world_to_cam:set(0, 0,
    math.cos(b)*math.cos(g), -math.cos(b)*math.sin(g), math.sin(b), -camera.x, -- magic minus sign :O
    math.cos(a)*math.sin(g)+math.sin(a)*math.sin(b)*math.cos(g), math.cos(a)*math.cos(g)-math.sin(a)*math.sin(b)*math.sin(g), -math.sin(a)*math.cos(b), camera.y,
    math.sin(a)*math.sin(g)-math.cos(a)*math.sin(b)*math.cos(g), math.sin(a)*math.cos(g)+math.cos(a)*math.sin(b)*math.sin(g), math.cos(a)*math.cos(b), camera.z,
    0, 0, 0, 1
  )
  world_to_cam:transpose(true)

  cls(21)

  -- DEBUG = true
  DEBUG = false
  
  profile("draw_setup")
  profile("transform_vertices")
  color(5)
  v:transform(v_proj.data, world_to_cam)
  if DEBUG then
  print("v_proj")
  print(v_proj.data[0] .. ", " .. v_proj.data[1] .. ", " .. v_proj.data[2] .. ", " .. v_proj.data[3] .. ", ")
  print(v_proj.data[4+0] .. ", " .. v_proj.data[4+1] .. ", " .. v_proj.data[4+2] .. ", " .. v_proj.data[4+3] .. ", ")
  print(v_proj.data[8+0] .. ", " .. v_proj.data[8+1] .. ", " .. v_proj.data[8+2] .. ", " .. v_proj.data[8+3] .. ", ")
  print(v_proj.data[12+0] .. ", " .. v_proj.data[12+1] .. ", " .. v_proj.data[12+2] .. ", " .. v_proj.data[12+3] .. ", ")
  print(v_proj.data[16+0] .. ", " .. v_proj.data[16+1] .. ", " .. v_proj.data[16+2] .. ", " .. v_proj.data[16+3] .. ", ")
  print(v_proj.data[20+0] .. ", " .. v_proj.data[20+1] .. ", " .. v_proj.data[20+2] .. ", " .. v_proj.data[20+3] .. ", ")
  print(v_proj.data[24+0] .. ", " .. v_proj.data[24+1] .. ", " .. v_proj.data[24+2] .. ", " .. v_proj.data[24+3] .. ", ")
  print(v_proj.data[28+0] .. ", " .. v_proj.data[28+1] .. ", " .. v_proj.data[28+2] .. ", " .. v_proj.data[28+3] .. ", ")
  end

  v_proj:transform(v_cam.data, cam_to_screen)
  v_cam.data.div(1, v_cam.data, v_cam.data, 2, 2, 1, 4, 4, v_proj.length)
  -- v_cam.data:div(v_cam.data, true, 3, 2, 1, 4, 4, v_proj.length)
  v_cam.data:mul(v_cam.data, true, 2, 0, 1, 4, 4, v_proj.length)
  v_cam.data:mul(v_cam.data, true, 2, 1, 1, 4, 4, v_proj.length)

  if DEBUG then
  print(v_cam.length .. ", " .. v_cam.capacity)
  print(v_cam.data[0] .. ", " .. v_cam.data[1] .. ", " .. v_cam.data[2] .. ", " .. v_cam.data[3] .. ", ")
  print(v_cam.data[4+0] .. ", " .. v_cam.data[4+1] .. ", " .. v_cam.data[4+2] .. ", " .. v_cam.data[4+3] .. ", ")
  print(v_cam.data[8+0] .. ", " .. v_cam.data[8+1] .. ", " .. v_cam.data[8+2] .. ", " .. v_cam.data[8+3] .. ", ")
  print(v_cam.data[12+0] .. ", " .. v_cam.data[12+1] .. ", " .. v_cam.data[12+2] .. ", " .. v_cam.data[12+3] .. ", ")
  print(v_cam.data[16+0] .. ", " .. v_cam.data[16+1] .. ", " .. v_cam.data[16+2] .. ", " .. v_cam.data[16+3] .. ", ")
  print(v_cam.data[20+0] .. ", " .. v_cam.data[20+1] .. ", " .. v_cam.data[20+2] .. ", " .. v_cam.data[20+3] .. ", ")
  print(v_cam.data[24+0] .. ", " .. v_cam.data[24+1] .. ", " .. v_cam.data[24+2] .. ", " .. v_cam.data[24+3] .. ", ")
  print(v_cam.data[28+0] .. ", " .. v_cam.data[28+1] .. ", " .. v_cam.data[28+2] .. ", " .. v_cam.data[28+3] .. ", ")
  end
  profile("transform_vertices")

  profile("draw_faces")
  local faces_drawn = f:draw_faces(v_cam, light)
  profile("draw_faces")

  -- color(7)
  -- f:draw_wireframes(v_cam, buf)
  
  -- color(8)
  -- pset(v_cam.data, 0, v_cam.length, 2, 4)

  print("CPU: " .. stat(1), 400, 3, 7)
  color(6)
  print("CAM: " .. camera.x .. "," .. camera.y .. "," .. camera.z)
  print("VERTICES: " .. v.length)
  print("FACES: " .. faces_drawn .."/".. f.length)

  color(6)
  profile.draw()
end

