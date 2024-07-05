-- (c) clubs
-- (s) spades
-- (h) hearts
-- (d) diamonds

e_mouse_state = {
	clicked = 1,
	held = 2,
	released = 3
}

e_game_state  = {
	init = 1,
	session = 2,
	win = 3
}

game_state    = e_game_state.init
highlight_tex = nil

window        = { w = 0, h = 0, tex = nil, pass = nil, aspect_multiplier = 1.6, tex_w = 0, tex_h = 0 }

metrics       = {}

mouse         = { x = 0, y = 0, prev = 0, curr = 0, state = e_mouse_state.released }

deck_ordered  = {
	-- { rank = "a", suit = "d", texture = nil }
}

deck_session  = {}

free_cells    = {}
home_cells    = {}
tableau       = {}
