local tu = require("typist.lib.tblutils")

local cardarea_handler = require("typist.mod.cardarea-handler")
local layout = require("typist.mod.layout")

require("typist.lib.log")(layout.tostring())

G.SETTINGS.__typist = G.SETTINGS.__typist or {}
G.SETTINGS.__typist.card_hover_duration = G.SETTINGS.__typist.card_hover_duration or 10

-- pseudo-CardArea object to manipulate jokers and consumable as if they're one hand
G.__typist_TOP_AREA = setmetatable({}, { __index = { __typist_top_area = true } })
return function(Controller, key) -- order defines precedence
  -- if text input is active, skip over keybind handlers
  if G.CONTROLLER and G.CONTROLLER.text_input_hook then -- do nothing
  elseif layout.global_map[key] then
    layout.global_map[key]()
  elseif G.SETTINGS.paused then
    require("typist.mod.state-handlers")[G.STATES.MENU](key)
  elseif
    (function()
      for leader, area in pairs(layout.cardarea_map) do
        if Controller.held_keys[leader] then
          local a = area and area()
          return a and cardarea_handler(a, key, Controller.held_keys)
        end
      end
    end)()
  then -- nothing :)
  elseif
    (function()
      if layout.top_area_free_select_map[key] or G.__typist_TOP_AREA.active_selection then
        if not (G.jokers and G.consumeables) then return end

        G.__typist_TOP_AREA.cards = tu.list_concat(G.jokers.cards, G.consumeables.cards)
        G.__typist_TOP_AREA.highlighted =
          tu.list_concat(G.jokers.highlighted, G.consumeables.highlighted)

        return cardarea_handler(G.__typist_TOP_AREA, key, Controller.held_keys)
      end
    end)()
  then -- nothing here too
  elseif require("typist.mod.state-handlers")[G.STATE] and G.GAME.STOP_USE == 0 then
    require("typist.mod.state-handlers")[G.STATE](key, Controller.held_keys)
  end
end
