local M = {}

M.init = function() end

M.lobby_start_game = function()
  local mp_start = G.MAIN_MENU_UI:get_UIE_by_ID("lobby_menu_start")
  if mp_start then G.FUNCS.lobby_start_game(mp_start) end
end

M.pvp_toggle_ready = function(e)
  if e.config.button == "pvp_ready_button" then G.FUNCS.pvp_ready_button(e) end
  if e.config.button == "mp_toggle_ready" then
    G.FUNCS.mp_toggle_ready(e)
    return true
  end
end

return M
