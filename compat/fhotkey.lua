local M = {}

M.init = function()
  if not fhotkey then return end

  print("FlushHotkeys detected, unhooking it from the keyboard :)")
  Controller.key_press_update = assert(fhotkey.FUNCS.keyupdate_ref)
end

M.best_hand_impl = function()
  if not fhotkey then return require("typist.mod.hand").best_hand end

  print("FlushHotkeys detected, will use its `best_hand` implementation instead")
  return function()
    fhotkey.FUNCS.select_best_hand(
      G.hand.cards,
      { accept_flush = true, accept_str = true, accept_oak = true }
    )
  end
end

return M
