(script_name ((string8 "bnsm")))
% script for:

% spawning actor + radar marker + item? at location
% managing respawn if killed (timeout)
% prompting to buy when close + eligable (no other script running)
% spawning script with set timer/usage counter
% terminating script when expired

(set_lvar_int ((lvar 0 type) (int8 0)))
(set_lvar_float ((lvar 1 x) (float32 -1525)))
(set_lvar_float ((lvar 2 y) (float32 974)))
% z - for blackboard prop, subtract 1.0
% (set_lvar_float ((lvar 3 z) (float32 7.2)))
(set_lvar_float ((lvar 3 z) (float32 6.2)))
(set_lvar_float ((lvar 4 h) (float32 120)))
(set_lvar_float ((lvar 5 r) (float32 10)))

(set_lvar_int ((lvar 25 prop) (int8 0)))
(set_lvar_int ((lvar 26 char) (int8 0)))
(set_lvar_float ((lvar 27 distance) (float32 0)))
(set_lvar_float ((lvar 28 px) (float32 0)))
(set_lvar_float ((lvar 29 py) (float32 0)))
(set_lvar_float ((lvar 30 pz) (float32 0)))
% state
% 0 = player outside radius
% 1 = player inside radius, loading
% 2 = player inside radius, ready
% 3 = player inside radius, npc dead
% 4 = player inside radius, npc can't sell
% 5 = unloading
(set_lvar_int ((lvar 31 state) (int8 0)))

(labeldef bnsm_main_loop)
(wait ((int8 40)))

(andor ((int8 0)))
  (is_player_playing ((dmavar 8)))
(goto_if_false ((label bnsm_main_loop)))

(get_char_coordinates ((dmavar 12) (lvar 28 px) (lvar 29 py) (lvar 30 pz)))
(get_distance_between_coords_2d ((lvar 1 x) (lvar 2 y) (lvar 28 px) (lvar 29 py) (lvar 27 distance)))

(andor ((int8 0)))
  (is_int_lvar_equal_to_number ((lvar 31 state) (int8 0)))
(goto_if_false ((label state_0_handler_end)))
  % state 0 - is player within load radius?
  (andor ((int8 0)))
    (is_float_lvar_greater_than_float_lvar ((lvar 5 r) (lvar 27 distance)))
  (goto_if_false ((label state_0_handler_end_1)))
    % state 0 - if so, request models and go to state = 1
    (request_model ((int16 214)))
    (request_model ((int16 -45)))
    (set_lvar_int ((lvar 31 state) (int8 1)))
  (labeldef state_0_handler_end_1)
  (goto ((label bnsm_main_loop)))
(labeldef state_0_handler_end)

(andor ((int8 0)))
  (is_int_lvar_equal_to_number ((lvar 31 state) (int8 1)))
(goto_if_false ((label state_1_handler_end)))
  % state 1 - are all models loaded?
  (andor ((int8 0)))
    (has_model_loaded ((int16 214)))
    (has_model_loaded ((int16 -45)))
  (goto_if_false ((label state_1_handler_end_1)))
    % state 1 - if so, spawn them
    (create_object ((int16 -45) (lvar 1 x) (lvar 2 y) (lvar 3 z) (lvar 25 prop)))
    (set_object_heading ((lvar 25 prop) (lvar 4 h)))
    % HACK: reuse px/py/pz
    (get_offset_from_object_in_world_coords ((lvar 25 prop) (float32 0.0) (float32 1.5) (float32 0.0) (lvar 28 px) (lvar 29 py) (lvar 30 pz)))
    (create_char ((int8 26) (int16 214) (lvar 28 px) (lvar 29 py) (lvar 30 pz) (lvar 26 char)))
    (set_char_heading ((lvar 26 char) (lvar 4 h)))
    (set_lvar_int ((lvar 31 state) (int8 2)))
  (labeldef state_1_handler_end_1)
  (goto ((label bnsm_main_loop)))
(labeldef state_1_handler_end)

(andor ((int8 0)))
  (is_int_lvar_equal_to_number ((lvar 31 state) (int8 2)))
(goto_if_false ((label state_2_handler_end)))
  % state 2 - has player left load radius?
  (andor ((int8 0)))
    (not_is_float_lvar_greater_than_float_lvar ((lvar 5 r) (lvar 27 distance)))
  (goto_if_false ((label state_2_handler_end_1)))
    % state 2 - if so, go to state 5 to unload
    (set_lvar_int ((lvar 31 state) (int8 5)))
    (goto ((label bnsm_main_loop)))
  (labeldef state_2_handler_end_1)

  % state 2 - close enough to show help?
  (andor ((int8 0)))
    (is_number_greater_than_float_lvar ((float32 3.0) (lvar 27 distance)))
  (goto_if_false ((label state_2_handler_end_2)))
    (print_help_forever_with_number ((string8 "IE06") (int8 99)))
  (labeldef state_2_handler_end_2)

  % state 2 - if not, and still within a certain range, clear help
  % (avoid unneccessarily clearing other help texts)
  (andor ((int8 1)))
    (not_is_number_greater_than_float_lvar ((float32 3.0) (lvar 27 distance)))
    (is_number_greater_than_float_lvar ((float32 30.0) (lvar 27 distance)))
  (goto_if_false ((label state_2_handler_end_3)))
    (clear_help)
  (labeldef state_2_handler_end_3)

  (goto ((label bnsm_main_loop)))
(labeldef state_2_handler_end)



(andor ((int8 0)))
  (is_int_lvar_equal_to_number ((lvar 31 state) (int8 5)))
(goto_if_false ((label state_5_handler_end)))
  (delete_char ((lvar 26 char)))
  (delete_object ((lvar 25 prop)))
  (set_lvar_int ((lvar 26 char) (int8 0)))
  (set_lvar_int ((lvar 25 prop) (int8 0)))
  (mark_model_as_no_longer_needed ((int16 214)))
  (mark_model_as_no_longer_needed ((int16 -45)))
  (set_lvar_int ((lvar 31 state) (int8 0)))
  (goto ((label bnsm_main_loop)))
(labeldef state_5_handler_end)

(goto ((label bnsm_main_loop)))
