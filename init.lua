local layout = require("typist.layout")

print(layout.tostring())

return function(Controller, key) -- order defines precedence
  if layout.global_map[key] then
    layout.global_map[key]()
  elseif
    (function()
      for leader, area in pairs(layout.cardarea_map) do
        if Controller.held_keys[leader] then
          local a = area()
          return a and require("typist.cardarea-handler")(a, key, Controller.held_keys)
        end
      end
    end)()
  then -- nothing :)
  elseif G.SETTINGS.paused then
    require("typist.state-handlers")[G.STATES.MENU](key)
  elseif require("typist.state-handlers")[G.STATE] then
    require("typist.state-handlers")[G.STATE](key, Controller.held_keys)
  end

  -- can be invoked anywhere with no consideration for state or precedence
  if Controller.held_keys["d"] and key == "x" then
    debug.debug() -- start a lua console in the global context
  end
end
