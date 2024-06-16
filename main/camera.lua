local M = {}

local DISPLAY_WIDTH = sys.get_config_int("display.width")
local DISPLAY_HEIGHT = sys.get_config_int("display.height")

local WINDOW_WIDTH = DISPLAY_WIDTH
local WINDOW_HEIGHT = DISPLAY_HEIGHT
local DISPLAY_SCALE_X = 1
local DISPLAY_SCALE_Y = 1

function M.init()
	WINDOW_WIDTH, WINDOW_HEIGHT = window.get_size()
	DISPLAY_SCALE_X = WINDOW_WIDTH / DISPLAY_WIDTH
	DISPLAY_SCALE_Y = WINDOW_HEIGHT / DISPLAY_HEIGHT
end

--- convert screen to world coordinates taking into account
-- the view and projection of a specific camera
-- @param camera URL of camera to use for conversion
-- @param screen_x Screen x coordinate to convert
-- @param screen_y Screen y coordinate to convert
-- @param z optional z coordinate to pass through the conversion, defaults to 0
-- @return world_x The resulting world x coordinate of the screen coordinate
-- @return world_y The resulting world y coordinate of the screen coordinate
-- @return world_z The resulting world z coordinate of the screen coordinate
function M.screen_to_world(camera, screen_x, screen_y, z)
	local projection = go.get(camera, "projection")
	local view = go.get(camera, "view")
	local w, h = window.get_size()
	-- The window.get_size() function will return the scaled window size,
	-- ie taking into account display scaling (Retina screens on macOS for
	-- instance). We need to adjust for display scaling in our calculation.
	w = w / (w / DISPLAY_WIDTH)
	h = h / (h / DISPLAY_HEIGHT)

	-- https://defold.com/manuals/camera/#converting-mouse-to-world-coordinates
	local inv = vmath.inv(projection * view)
	local x = (2 * screen_x / w) - 1
	local y = (2 * screen_y / h) - 1
	local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
	local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
	return x1, y1, z or 0
end


--- Adjust camera zoom so that the original area covered by
-- display width and height of game.project is always visible
-- this mode will reveal more content to the sides or above and
-- below if the aspect ratio is different. Call this function
-- any time the window size changes (or every frame if you wish)
-- this is the "Fixed Fit Projection" from the manual:
-- https://defold.com/manuals/render/#fixed-fit-projection
-- @param camera URL of camera to use for conversion
function M.use_fixed_fit_projection(camera)
	local w, h = window.get_size()
	-- take into display scaling (eg retina)
	w = w / DISPLAY_SCALE_X
	h = h / DISPLAY_SCALE_Y
	-- calculate the zoom so that the entire initial area of game project
	-- is visible
	local zoom = math.min(w / DISPLAY_WIDTH, h / DISPLAY_HEIGHT)
	go.set(camera, "orthographic_zoom", zoom)
end

return M