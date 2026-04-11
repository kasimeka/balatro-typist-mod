require("typist.mod.cardarea-ext")

local tu = require("typist.lib.tblutils")

local cardarea_handler = require("typist.mod.cardarea-handler")
local hand = require("typist.mod.hand")
local layout = require("typist.mod.layout")
local run_setup = require("typist.mod.run-setup")

local multiplayer_compat = require("typist.compat.multiplayer")

local M = {}

local best_hand = require("typist.compat.fhotkey").best_hand_impl()

---play or discard from HUD buttons when the key matches and the button is active
local function try_play_or_discard_from_buttons(key)
  if
    key == layout.proceed
    and G.buttons
    and G.buttons:get_UIE_by_ID("play_button").config.button
  then
    G.FUNCS.play_cards_from_highlighted()
    return true
  end
  if
    key == layout.dismiss
    and G.buttons
    and G.buttons:get_UIE_by_ID("discard_button").config.button
  then
    G.FUNCS.discard_cards_from_highlighted()
    return true
  end
end

local function cheat_layer(key, held_keys)
  if key == layout.cheat.best_hand then
    best_hand(held_keys[layout.cheat.reverse_left] or held_keys[layout.cheat.reverse_right])
  elseif key == layout.cheat.best_flush then
    hand.flush(hand.best_flush_suit())
  elseif layout.cheat.suits_map[key] then
    hand.flush(layout.cheat.suits_map[key])
  elseif layout.cheat.ranks_map[key] then
    if -- only allow a leader key to pass when another leader key is held
      not (key == layout.cheat.leader_left or key == layout.cheat.leader_right)
      or (key == layout.cheat.leader_left and held_keys[layout.cheat.leader_right])
      or (key == layout.cheat.leader_right and held_keys[layout.cheat.leader_left])
    then
      hand.by_rank(layout.cheat.ranks_map[key])
    end
  elseif try_play_or_discard_from_buttons(key) then
  end
end

M[G.STATES.SELECTING_HAND] = function(key, held_keys)
  if held_keys[layout.preview_deck] and not G.deck_preview then
    G.deck_preview = UIBox {
      definition = G.UIDEF.deck_preview(),
      config = { align = "tm", offset = { x = 0, y = -0.8 }, major = G.hand, bond = "Weak" },
    }
    G.E_MANAGER:add_event(Event {
      blocking = false,
      blockable = false,
      func = function()
        if
          G.deck_preview and not (tu.dig(G, { "CONTROLLER", "held_keys", layout.preview_deck }))
        then
          G.deck_preview:remove()
          G.deck_preview = nil
          return true
        end
      end,
    })
  end

  if held_keys[layout.cheat.leader_right] or held_keys[layout.cheat.leader_left] then
    cheat_layer(key, held_keys)

  -- toggle card by position in hand
  elseif layout.free_select_map[key] then
    G.hand:__typist_toggle_card_by_index(layout.free_select_map[key])
  elseif try_play_or_discard_from_buttons(key) then
  elseif key == layout.hand.invert_selection then
    hand.invert_selection()
  elseif key == layout.hand.deselect_all then
    G.hand:unhighlight_all()
    play_sound("cardSlide2", nil, 0.3)

  -- select the leftmost 5 cards
  elseif key == layout.hand.left5 then
    hand.left5()
  -- select the rightmost 5 cards
  elseif key == layout.hand.right5 then
    hand.right5()

  --
  elseif key == layout.hand.sort_by_rank then
    G.FUNCS.sort_hand_value(nil)
  elseif key == layout.hand.sort_by_suit then
    G.FUNCS.sort_hand_suit(nil)
  elseif key == layout.hand.reorder_by_enhancements then
    hand.reorder_by_enhancements()
  end
end

M[G.STATES.ROUND_EVAL] = function(key)
  if key == layout.proceed or key == layout.enter then
    local cash_out_button
    for e, _ in pairs(G.__typist_ORPHANED_UIBOXES) do
      cash_out_button = e:get_UIE_by_ID("cash_out_button")
      if cash_out_button and cash_out_button.config.button then
        G.FUNCS.cash_out(cash_out_button)
        return
      end
    end
  end
end

-- pseudo-CardArea object to manipulate the shop as if it's one hand
local shop = setmetatable({}, { __index = { __typist_shop = true } })
-- stylua: ignore
local to_big = to_big or function(x) return x end -- talisman compat
M[G.STATES.SHOP] = function(key, held_keys)
  -- reroll shop
  if
    key == layout.reroll
    and (
      to_big(G.GAME.dollars) - to_big(G.GAME.current_round.reroll_cost)
      >= to_big(G.GAME.bankrupt_at)
    )
  then
    G.FUNCS.reroll_shop()

  -- switch to blind select
  elseif key == layout.dismiss or key == layout.enter then
    G.FUNCS.toggle_shop()
  else
    shop.cards = tu.list_concat(G.shop_jokers.cards, G.shop_vouchers.cards, G.shop_booster.cards)
    shop.highlighted = tu.list_concat(
      G.shop_jokers.highlighted,
      G.shop_vouchers.highlighted,
      G.shop_booster.highlighted
    )
    cardarea_handler(shop, key, held_keys)
  end
end

M[G.STATES.BLIND_SELECT] = function(key)
  -- select blind
  if key == layout.proceed or key == layout.enter then
    local e =
      G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("select_blind_button")

    if not multiplayer_compat.pvp_toggle_ready(e) then G.FUNCS.select_blind(e) end

  -- skip blind
  elseif key == layout.skip then
    G.FUNCS.skip_blind(
      G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("blind_extras")
    )

  -- reroll boss
  elseif key == layout.reroll then
    if
      (
        (G.GAME.used_vouchers["v_directors_cut"] and not G.GAME.round_resets.boss_rerolled)
        or G.GAME.used_vouchers["v_retcon"]
      ) and G.GAME.dollars - 10 >= G.GAME.bankrupt_at
    then
      G.FUNCS.reroll_boss()
    end
  else -- TODO: find and hover the current tag?
  end
end

-- close splash screen on any key press
M[G.STATES.SPLASH] = function()
  G:delete_run() -- this just deletes the run from global state, no save files affected
  G:main_menu()
end

local function handle_main_menu(key)
  if key == layout.proceed then
    local the_play_button = G.MAIN_MENU_UI:get_UIE_by_ID("main_menu_play")
    if the_play_button then
      G.FUNCS.setup_run(the_play_button)
    else
      multiplayer_compat.lobby_start_game()
    end
  end
end

local function handle_overlay_menu(key)
  local new_run_from_game_end_button = G.OVERLAY_MENU:get_UIE_by_ID("from_game_over")
    or G.OVERLAY_MENU:get_UIE_by_ID("from_game_won")
  local game_end_screen = not not new_run_from_game_end_button

  if run_setup.handle(key) then return end

  if key == layout.proceed then
    if game_end_screen then
      G.FUNCS.notify_then_setup_run(new_run_from_game_end_button)
    elseif
      G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_continue"))
      and tu.dig(G.GAME, { "viewed_back", "effect", "center", "unlocked" })
    then
      G.FUNCS.start_setup_run { config = { id = {} } }
    end
    return
  end

  if key == layout.escape or key == layout.dismiss then
    if game_end_screen then
      G.FUNCS.go_to_menu()
    elseif not G.OVERLAY_MENU.config.no_esc then
      G.FUNCS:exit_overlay_menu()
    elseif G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_new_run")) then
      G.FUNCS.go_to_menu()
    end
    return
  end

  if key == layout.enter then
    if tu.dig(new_run_from_game_end_button, { "config", "id" }) == "from_game_won" then
      G.FUNCS:exit_overlay_menu()
    else
      require("typist.compat.taikomochi").zen_restart_ante()
    end
  end
end

M[G.STATES.MENU] = function(key)
  if G.MAIN_MENU_UI and not G.SETTINGS.paused then
    handle_main_menu(key)
  elseif G.OVERLAY_MENU then
    handle_overlay_menu(key)
  end
end

local pack_event = { config = {} }
M[G.STATES.STANDARD_PACK] = function(key, held_keys)
  if key == layout.dismiss then
    if G.FUNCS.can_skip_booster(pack_event) or pack_event.config.button then
      G.FUNCS.skip_booster(pack_event)
    end
  else
    cardarea_handler(G.pack_cards, key, held_keys)
  end
end
-- booster pack states (STANDARD_PACK, PLANET_PACK, …) share one handler
M[G.STATES.PLANET_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.SPECTRAL_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.BUFFOON_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.TAROT_PACK] = M[G.STATES.STANDARD_PACK]
if G.STATES.SMODS_BOOSTER_OPENED then
  M[G.STATES.SMODS_BOOSTER_OPENED] = M[G.STATES.STANDARD_PACK]
end

return M
