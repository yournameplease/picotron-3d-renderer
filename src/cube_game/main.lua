require("src.util")

local stage = require("src.cube_game.stage")

local game = {}
local cube_game = {}

function cube_game.init()
  printh("init")
  local layers = fetch(DATP.."map/world_1.map")
  -- local layers = fetch(DATP.."map/test.map")
  game.stage = stage.new(layers[1].bmp, 5, 5, 5, 1)

  game.t = 0
  game.yaw_0 = game.stage.camera.yaw
  game.pitch_0 = game.stage.camera.pitch
  game.yaw_1 = 0
  game.pitch_1 = 0

  camera_next = {
    pos = vec(0, 0, 0),
    pitch = 0,
    yaw = 0,
    roll = 0
  }

  profile.enabled(true, true)
end

function cube_game.update()
  local dt = 1/60
  game.t = game.t + dt

  -- if game.t > 3 and not animation_started then
  --   animation_started = true
  --   game.stage.scene:animate_camera(camera_next, 3, lerp)
  -- end

  -- game.stage.camera.yaw = game.yaw_0 + 0.05 * math.cos(game.t)
  -- game.stage.camera.pitch = game.pitch_0 + 0.05 * math.sin(game.t)
  -- game.stage.camera.yaw = lerp(game.yaw_0, game.yaw_1, (1 + math.sin(game.t)) / 2)
  -- game.stage.camera.pitch = lerp(game.pitch_0, game.pitch_1, (1 + math.sin(game.t)) / 2)

  
  game.stage.scene:update(dt)

end

function cube_game.draw()
  cls(21)

  -- game.stage.scene:draw(true)
  game.stage:draw()
  profile.draw()
end

return cube_game
