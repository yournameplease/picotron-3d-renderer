local stage = require("src.cube_game.stage")

local game = {}
local cube_game = {}

function cube_game.init()
  local layers = fetch(DATP.."map/world_1.map")
  game.stage = stage.new(layers[1].bmp, 5, 5, 5)
end

function cube_game.update()

end

function cube_game.draw()
  cls(0)

  game.stage.scene:draw(true)
end

return cube_game
