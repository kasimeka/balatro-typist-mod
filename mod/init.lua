G.SETTINGS.__typist = G.SETTINGS.__typist or {}
G.SETTINGS.__typist.card_hover_duration = G.SETTINGS.__typist.card_hover_duration or 10

-- pseudo-CardArea object to manipulate jokers and consumable as if they're one hand
G.__typist_TOP_AREA = setmetatable({}, { __index = { __typist_top_area = true } })

local layout = require("typist.mod.layout")

require("typist.lib.log")(layout.tostring())
