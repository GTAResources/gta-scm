binary("games/san-andreas/data/script/main.scm") do |scm|
  # delete original headers
  scm.delete(0,55976)

  # 29 bytes of jumped-over code in init code
  scm.delete(56124,56153)

  # 1217 bytes of jumped-over code in init code
  scm.patch(56728,57945) do
    [:labeldef,:debug_breakpoint]
    [:IncludeRuby, "debug-breakpoint"]
    [:IncludeRuby, "debug-logger", [:v2, true]]
  end

  # patch out intro mission launcher
  scm.patch(59976,59980) do
    # [:load_and_launch_mission_internal,[[:int8,2]]]
    [:nop]
    [:nop]
  end

  # patch out load_and_launch_mission_internal(4) to load bad duality game (we use it's global vars) 
  scm.patch(61294,61305) do
    # [:set_var_int,[[:dmavar,1636],[:int8,2]]]
    # [:load_and_launch_mission_internal,[[:int8,4]]]
    [:set_var_int,[[:dmavar,1636],[:int8,1]]]
    [:load_and_launch_mission_internal,[[:int8,3]]]
  end

  # replace goto in main thread to our extension
  scm.patch(61763,61770) do
    # [:gosub,[[:int32,60030]]]
    [:goto,[[:label,:main_loop_ext]]]
  end

  # replace gosub in save thread to our extension
  scm.patch(88020,88027) do
    # [:gosub,[[:int32,88389]]]
    [:gosub,[[:label,:save_thread_ext]]]
  end
  scm.patch(88165,88172) do
    # [:gosub,[[:int32,88469]]]
    [:gosub,[[:label,:save_thread_after_ext]]]
  end

  # Unused export debug code
  scm.patch(127559,129478) do
    # [:goto,[[:int32,127573]]]
    # [:goto,[[:int32,129490]]]
    [:goto,[[:int32,122006]]]
    [:goto,[[:int32,129490]]]
    # more code can go here
  end

  # Unused GF debug code
  scm.patch(152364,154839) do
    # more code can go here
    [:nop]
  end

  # end of main code
  scm.patch(194125,200000) do
    [:IncludeRuby,"declares",[:v2,true]]
    [:IncludeRuby,"main-loop-ext",[:v2,true]]
    [:IncludeRuby,"save-script-ext",[:v2,true]]
    [:IncludeRuby,"external-loader",[:v2,true]]

    [:IncludeRuby,"bitpacker"]
    [:IncludeRuby,"corona"]
    [:Include,"carid2gxt"]


    [:labeldef,:helper]
    [:IncludeRuby,"helper"]
  end

  # Include missions
  scm.include(194125,3079744)

  [:AssignGlobalVariables]
  [:AssembleExternal,78,"ext78"]
  [:AssembleExternal,79,"ext79"]
end