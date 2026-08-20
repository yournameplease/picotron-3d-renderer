
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
local dither = require("src.dither")
local lighting = require("src.lighting")
local faces = require("src.face")
local scene = require("src.scene")

local BUFFER_MAX = 1024

-- vertices

local buf = userdata("f64", BUFFER_MAX)

local dither_ramp
-- local lighting_ramp
-- todo)) global
---@type LightingRamp
lighting_ramp = nil
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

  
  local o = vec(0, 0, 5)
  local i_hat = vec(1, 0, 0)
  local j_hat = vec(0, 1, 0)
  local k_hat = vec(0, 0, 1)

  -- local GRID_S = 6
  local GRID_S = 3

  local scene_builder = scene.builder()
  
  for l = 0, GRID_S-1 do
    for m = 0, GRID_S-1 do
      local s = (l*GRID_S+m)%4+1
      -- scene_builder:add_cube(o + vec(3*l, 0, 3*m), i_hat * (1 + l/GRID_S), j_hat, k_hat * (1 + m/GRID_S), s)
    end
  end

  scene_builder:add_sphere(
    vec(15, 5, 25),
    10,
    20,
    10,
    2
  )
 

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

  
  v = vertices.of(scene_builder.vertices)
  v_proj = vertices.of(scene_builder.vertices)
  v_cam = vertices.of(scene_builder.vertices)


  light = vector_normalize(light)
  printh(light.x .. light.y .. light.z)

  f = faces.of(scene_builder.faces, scene_builder.vertices)

  apply_color_table(8, 0)
  -- apply_color_table(8, 1)
  apply_color_table(10, 2)
  -- apply_color_table(10, 3)

  lighting_ramp = lighting.new()
  
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
  if btn(8) then camera.pitch = camera.pitch - 0.01 end
  if btn(9) then camera.pitch = camera.pitch + 0.01 end
  if btn(10) then camera.yaw = camera.yaw + 0.01 end
  if btn(11) then camera.yaw = camera.yaw - 0.01 end
  if btn(14) then camera.roll = camera.roll - 0.01 end
  if btn(15) then camera.roll = camera.roll + 0.01 end
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

  -- lighting_ramp.dither:debug_rect(10, 10, 110, 110, 7)
  -- lighting_ramp.dither:debug_circ(210, 210, 100, 7)
end

