
class GtaScm::Node::Instruction < GtaScm::Node::Base
  def opcode;      self[0];     end
  def opcode=(_);  self[0] = _; end
  def arguments;   self[1];     end

  def initialize(*args)
    super
    self[0] = GtaScm::ByteArray.new
    self[1] = GtaScm::ByteArray.new
  end

  def eat!(parser)
    self.offset = parser.offset

    self[0] = parser.read(2)

    self[1] = GtaScm::ByteArray.new

    definition = parser.opcodes[ self.opcode ] || raise("No definition for opcode #{self.opcode.inspect}")

    if definition.var_args?
      loop do
        argument = GtaScm::Node::Argument.new
        self.arguments << argument
        argument.eat!(parser,self)
        break if argument.arg_type_id == 0 # end of var_args list
      end
    else
      definition.arguments.each_with_index do |arg_def,arg_idx|
        argument = GtaScm::Node::Argument.new
        self.arguments << argument
        argument.eat!(parser,self)
      end
    end
  end

  def negated?
    self.opcode != GtaScm::OpcodeDefinitions.normalize_opcode(self.opcode)
  end

  def negate!
    if !negated?
      self.opcode[1] += 128
    end
  end

  def to_ir(scm,dis)
    definition = scm.opcodes[ self.opcode ] || raise("No definition for opcode #{self.opcode.inspect}")

    ir = []
    name = definition.name
    name = :"not_#{name}" if negated?
    ir << name
    if self.arguments.present?
      ir[1] = (self.arguments || []).map.each_with_index do |argument,idx|
        arg = if argument.end_var_args?
          [argument.arg_type_sym]
        elsif argument.array?
          [argument.arg_type_sym].concat(argument.array_ir(scm,dis))
        elsif argument.string128?
          [:string128,argument.value]
        elsif argument.istring?
          [:istring8,argument.value]
        elsif self.jump_argument?(idx)
          if argument.arg_type_sym == :var || argument.arg_type_sym == :lvar
            [argument.arg_type_sym,argument.value]
          elsif argument.value < 0
            [:mission_label,dis.label_for_offset(argument.value,self.offset)]
          else
            [:label,dis.label_for_offset(argument.value,self.offset)]
          end
        # elsif argument.float?
        #   [argument.arg_type_sym,argument.value,'DAADB00B']
        elsif enum = self.enum_argument?(idx) && dis.options[:use_enum_arguments]
          self.enum_argument_ir(scm,dis,enum,argument.value)
        else
          [argument.arg_type_sym,argument.value]
        end

        if arg[0] == :var && (name = dis.variable_names[ arg[1] ])
          arg << :"#{name}"
        end

        arg
      end
    end
    ir
  end

  ENUM_ARGUMENT_OPCODES = {
    [0x9B,0x02] => { 0 => :object },                    # CREATE_OBJECT_NO_OFFSET
    [0x13,0x02] => { 0 => :object, 1 => :pickup_type }, # CREATE_PICKUP
    [0x36,0x02] => { 1 => :object }, # gang_car
    [0x37,0x02] => { 1 => :weapon_id, 2 => :weapon_id }, # gang_car
  }
  def enum_argument?(arg_idx)
    args = ENUM_ARGUMENT_OPCODES[ self.opcode ]
    return false unless args
    args[arg_idx]
  end

  def enum_argument_ir(scm,dis,enum,value)
    case enum
    when :object
      if value >= 0
        [ :object, scm.definitions[:objects][value] ]
      else
        [ :objscm, scm.objscm_name(value) ]
      end
    else
      if enum == :weapon_id
        # debugger;enum
      end
      if ir = scm.definitions[enum.to_sym].andand[value]
        ir
      else
        [enum,value]
      end
    end
  end

  JUMP_ARGUMENT_OPCODES = {
    [0x02,0x00] => [0], # GOTO
    [0x4c,0x00] => [0], # GOTO_IF_TRUE
    [0x4d,0x00] => [0], # GOTO_IF_FALSE
    [0x4f,0x00] => [0], # START_NEW_SCRIPT
    [0x50,0x00] => [0], # GOSUB
    [0x71,0x08] => [3,5,7,9,11,13,15,17], # SWITCH_START
    [0x72,0x08] => [1,3,5,7,9,11,13,15,17], # SWITCH_CONTINUE
    [0xd7,0x00] => [0], # launch_mission
  }
  def jump_argument?(arg_idx)
    arg_idxs = JUMP_ARGUMENT_OPCODES[ self.opcode ]
    return false unless arg_idxs
    arg_idxs.include?(arg_idx)
  end

  def string128_argument?
    # self.opcode == [0x62,0x06]
    self.opcode == [0xB6, 0x05]
  end

  def jumps
    # TODO: calculate abs offsets here? or further up?
    case self.opcode
      when [0x02,0x00] # GOTO
        [{type: :always,   to: self.arguments[0].value}]
      when [0x4c,0x00] # GOTO_IF_TRUE
        [{type: :if_true,  to: self.arguments[0].value}]
      when [0x4d,0x00] # GOTO_IF_FALSE
        [{type: :if_false, to: self.arguments[0].value}]
      when [0x4e,0x00] # TERMINATE_THIS_SCRIPT
        [{type: :end}]
      when [0x4f,0x00] # START_NEW_SCRIPT
        [{type: :new,      to: self.arguments[0].value}]
      when [0x50,0x00] # GOSUB
        [{type: :gosub,    to: self.arguments[0].value}]
      when [0x51,0x00] # RETURN
        [{type: :return}]
      when [0x71,0x08], [0x72,0x08] # SWITCH_START / SWITCH_CONTINUE
        jumps_for_switch
      else
        []
      end
  end

  def absolute_offset(value)
    
  end

  def jumps_for_switch
    jump_args = JUMP_ARGUMENT_OPCODES[self.opcode]
    jump_args.map do |jump_arg_idx|
      value = self.arguments[jump_arg_idx - 1].value
      if value == -1
        nil
      else
        {type: :switch, to: self.arguments[jump_arg_idx].value, switch_value: value}
      end
    end.compact
  end
end
