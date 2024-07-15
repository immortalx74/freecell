-- (c) clubs
-- (s) spades
-- (h) hearts
-- (d) diamonds

ffi = require "ffi"
glfw = ffi.os == 'Windows' and ffi.load( 'glfw3' ) or ffi.C

ffi.cdef( [[
	enum {
		GLFW_RESIZABLE = 0x00020003,
		GLFW_VISIBLE = 0x00020004,
		GLFW_DECORATED = 0x00020005,
		GLFW_FLOATING = 0x00020007
	};

	typedef struct GLFWvidmode {
		int width;
		int height;
		int refreshRate;
	} GLFWvidmode;

	typedef struct GLFWwindow GLFWwindow;
	GLFWwindow* os_get_glfw_window(void);
	void glfwGetWindowPos(GLFWwindow* window, int *xpos, int *ypos);
	void glfwSetInputMode(GLFWwindow * window, int GLFW_CURSOR, int GLFW_CURSOR_HIDDEN);
	void glfwGetCursorPos(GLFWwindow *window, double *xpos, double *ypos);
	void glfwSetWindowSize(GLFWwindow *window, int width, int height);
]] )

e_mouse_state = {
	clicked = 1,
	held = 2,
	released = 3
}

e_game_state  = {
	init = 1,
	session = 2,
	win = 3,
	autosolve = 4
}

game_state    = e_game_state.init
highlight_tex = nil

window        = { w = 0, h = 0, tex = nil, pass = nil, aspect_multiplier = 1.6, tex_w = 0, tex_h = 0 }

metrics       = {}

mouse         = { x = 0, y = 0, x_prev = 0, y_prev = 0, button_prev = 0, button_curr = 0, state = e_mouse_state.released }

deck_ordered  = {
	-- { rank = "a", suit = "d", texture = nil }
}

deck_session  = {}
moving_stack  = {}
free_cells    = { false, false, false, false }
home_cells    = { false, false, false, false }
tableau       = {}
