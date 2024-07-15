require "globals"
local Game = require "game"

function lovr.load()
	Game.Init()
end

function lovr.keypressed( key, scancode, repeating )
	if key == "f2" then
		game_state = e_game_state.init
	end

	if key == "return" then
		game_state = e_game_state.autocomplete
	end
end

function lovr.update( dt )
	Game.Update()
end

function lovr.draw( pass )
	pass:setProjection( 1, mat4():orthographic( pass:getDimensions() ) )

	Game.Render()

	pass:setColor( 0.043, 0.411, 0.168 )
	pass:plane( window.w / 2, window.h / 2, 0, window.tex_w, window.tex_h )
	pass:setColor( 1, 1, 1 )
	pass:setMaterial( window.tex )
	pass:plane( window.w / 2, window.h / 2, 0, window.tex_w, -window.tex_h )

	local passes = {}
	table.insert( passes, pass )
	table.insert( passes, window.pass )
	return lovr.graphics.submit( passes )
end
