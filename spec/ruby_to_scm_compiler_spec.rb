require_relative 'spec_helper'

require 'gta_scm/ruby_to_scm_compiler'
require 'parser/current'

describe GtaScm::RubyToScmCompiler do

  before :all do
    @scm = GtaScm::Scm.load_string("san-andreas","")
    @scm.load_opcode_definitions!
    @scm
  end
  let(:ruby){ "" }
  subject { compile(ruby) }

  describe "assigns" do
    context "for local vars" do

      context "for ints" do
        context "for =" do
          let(:ruby){"test = 0"}
          it { is_expected.to eql "(set_lvar_int ((lvar 0 test) (int32 0)))" }
        end
        context "for +=" do
          let(:ruby){"test += 0"}
          it { is_expected.to eql "(add_val_to_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for -=" do
          let(:ruby){"test -= 0"}
          it { is_expected.to eql "(sub_val_from_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for *=" do
          let(:ruby){"test *= 0"}
          it { is_expected.to eql "(mult_val_by_int_lvar ((lvar 0 test) (int32 0)))" }
        end
        context "for /=" do
          let(:ruby){"test /= 0"}
          it { is_expected.to eql "(div_val_by_int_lvar ((lvar 0 test) (int32 0)))" }
        end
      end

      context "for floats" do
        context "for =" do
          let(:ruby){"test = 0.0"}
          it { is_expected.to eql "(set_lvar_float ((lvar 0 test) (float32 0.0)))" }
        end
        context "for +=" do
          let(:ruby){"test += 0.0"}
          it { is_expected.to eql "(add_val_to_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for -=" do
          let(:ruby){"test -= 0.0"}
          it { is_expected.to eql "(sub_val_from_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for *=" do
          let(:ruby){"test *= 0.0"}
          it { is_expected.to eql "(mult_val_by_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
        context "for /=" do
          let(:ruby){"test /= 0.0"}
          it { is_expected.to eql "(div_val_by_float_lvar ((lvar 0 test) (float32 0.0)))" }
        end
      end
    end


    context "type-casting" do
      let(:ruby){"a = 1.0; b = a.to_i"}
      it { is_expected.to eql "(cset_lvar_int_to_lvar_float ((lvar 1 b) (lvar 0 a)))" }
    end

    # context "decomposing operations" do
    #   let(:ruby){"a = 1; b = 2; c = (a + 4) * b"}
    #   it { is_expected.to eql "c = a; c += 4; c *= b" }
    # end

    context "opcode calls" do
      context "with a single assignment" do
        let(:ruby){"time = get_game_timer()"}
        it { is_expected.to eql "(get_game_timer ((lvar 0 time)))" }
      end

      context "with multiple assignments" do
        let(:ruby){"x,y,z = get_char_coordinates($_12)"}
        it { is_expected.to eql "(get_char_coordinates ((dmavar 12) (lvar 0 x) (lvar 1 y) (lvar 2 z)))" }
      end

      context "with the wrong number of arguments" do
        let(:ruby){"get_game_timer()"}
        it { expect {
          compile(ruby)
          }.to raise_error(GtaScm::RubyToScmCompiler::IncorrectArgumentCount) }
      end

      context "with the wrong number of multiple assignments" do
        let(:ruby){"x,y = get_char_coordinates($_12)"}
        it { expect {
          compile(ruby)
          }.to raise_error(GtaScm::RubyToScmCompiler::IncorrectArgumentCount) }
      end
    end

  end

  describe "compares" do
    context "trivial compares" do
      let(:ruby){"a = 0; if a > 5; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 0)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
        LISP
      }
    end

    context "compares with ands" do
      let(:ruby){"a = 0; if a > 5 && a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int32 10)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with ors" do
      let(:ruby){"a = 0; if a > 5 || a < 10; wait(1); else; wait(0); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 21)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 5)))
        (not_is_int_lvar_greater_or_equal_to_number ((lvar 0 a) (int32 10)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with nots" do
      let(:ruby){ <<-RUBY
        a = 0
        if not is_car_dead(a)
          wait(1)
        else
          wait(0)
        end
      RUBY
      }

      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with AND and NOT" do
      let(:ruby){ <<-RUBY
        a = 0
        if a > 0 and not is_car_dead(a)
          wait(1)
        else
          wait(0)
        end
      RUBY
      }

      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (andor ((int8 1)))
        (is_int_lvar_greater_than_number ((lvar 0 a) (int32 0)))
        (not_is_car_dead ((lvar 0 a)))
        (goto_if_false ((label label_1)))
        (wait ((int32 1)))
        (goto ((label label_2)))
        (labeldef label_1)
        (wait ((int32 0)))
        (labeldef label_2)
      LISP
      }
    end

    context "compares with mixed and/ors" do
      let(:ruby){"a = 0; if a > 5 && a == 10 || a < 10; wait(1); else; wait(0); end"}
      it { expect {
        compile(ruby)
      }.to raise_error(GtaScm::RubyToScmCompiler::InvalidConditionalLogicalOperatorUse) }
    end
  end

  describe "loops" do
    context "main loop" do
      let(:ruby){"loop do; wait(1); end"}
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (labeldef label_1)
        (wait ((int32 1)))
        (goto ((label label_1)))
        (labeldef label_2)
        LISP
      }
    end
    context "loops with break" do
      let(:ruby){ <<-RUBY
        a = 0
        loop do
          wait(50)
          break
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (set_lvar_int ((lvar 0 a) (int32 0)))
        (labeldef label_1)
        (wait ((int32 50)))
        (goto ((label label_2)))
        (goto ((label label_1)))
        (labeldef label_2)
        LISP
      }
    end
  end

  describe "lambdas" do
    context "lambda definition and call" do
      let(:ruby){ <<-RUBY
        block = routine{ terminate_this_script() };
        block();
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
        (goto ((label label_2)))
        (labeldef label_1)
        (terminate_this_script)
        (return)
        (labeldef label_2)
        (gosub ((label label_1)))
      LISP
      }
    end
  end

  describe "complex stuff" do
    context "multiple branches inside loop" do
      let(:ruby){ <<-RUBY
        loop do
          wait(100)
          waiting_for = 0
          if is_player_playing($_8)
            x,y,z = get_char_coordinates($_12)
            current_time = get_game_timer()
            if current_time > 5000
              add_one_off_sound(x,y,z,1056)
              terminate_this_script()
            else
              waiting_for += 100
            end
          end
        end
      RUBY
      }
      it { is_expected.to eql <<-LISP.strip_heredoc.strip
          (labeldef label_1)
          (wait ((int32 100)))
          (set_lvar_int ((lvar 0 waiting_for) (int32 0)))
          (andor ((int8 0)))
          (is_player_playing ((dmavar 8)))
          (goto_if_false ((label label_3)))
          (get_char_coordinates ((dmavar 12) (lvar 1 x) (lvar 2 y) (lvar 3 z)))
          (get_game_timer ((lvar 4 current_time)))
          (andor ((int8 0)))
          (is_int_lvar_greater_than_number ((lvar 4 current_time) (int32 5000)))
          (goto_if_false ((label label_4)))
          (add_one_off_sound ((lvar 1 x) (lvar 2 y) (lvar 3 z) (int32 1056)))
          (terminate_this_script)
          (goto ((label label_5)))
          (labeldef label_4)
          (add_val_to_int_lvar ((lvar 0 waiting_for) (int32 100)))
          (labeldef label_5)
          (labeldef label_3)
          (goto ((label label_1)))
          (labeldef label_2)
        LISP
      }
    end
  end

  # ===

  def compile(ruby)
    parsed = Parser::CurrentRuby.parse(ruby)
    compiler = GtaScm::RubyToScmCompiler.new
    compiler.scm = @scm
    scm = compiler.transform_node(parsed)
    f = scm.map do |node|
      Elparser::encode(node)
    end
    f.join("\n")
  end


end