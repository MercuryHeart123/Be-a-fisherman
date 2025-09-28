--!strict

-- Runtime table
local Types = {}
Types.BaitState = {
	In = "In",
	Out = "Out",
	Pressed = "Pressed",
}

-- Type alias (for static checking)
export type BaitState = "In" | "Out" | "Pressed"

return Types
