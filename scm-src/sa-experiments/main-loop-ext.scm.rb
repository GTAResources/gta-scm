
declare do
  int $code_state
  int $13576
  int $save_in_progress
end

[:labeldef, :main_loop_ext]

if $code_state == 0 && $13576 > 0 && $save_in_progress != 1
  log("starting scripts")
  [:start_new_script, [[:label, :external_loader],[:end_var_args]]]
  [:start_new_script, [[:label, :helper],[:end_var_args]]]

  $code_state = 1
  # [:gosub, [[:label,:global_variable_declares]]]
end

[:goto, [[:int32, 60030]]]
