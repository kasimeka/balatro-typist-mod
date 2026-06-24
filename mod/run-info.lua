local tabs = require("typist.mod.tabs")

local M = {}

local tab_handler = tabs.make_handler(function()
  local ls = { localize("b_poker_hands"), localize("b_blinds"), localize("b_vouchers") }
  if G.GAME.stake > 1 then ls[#ls + 1] = localize("b_stake") end
  return ls
end)
M.handle = function(key, held_keys)
  return tab_handler(key, held_keys)
end

return M
