require 'treetop'
require_relative 'equation_node_classes'
require_relative 'equation_grammar'

class Context
  attr_accessor :transient_symbols

  def initialize(default: {}, methods: {})
    @symbol_table = default
    @transient_symbols = {}
    @methods = methods
  end

  def symbols
    @symbol_table.merge(@transient_symbols)
  end

  def get(identifier:, path: {})
    assert_defined!(identifier: identifier)
    child = symbols[identifier.to_sym]
    path.each{|segment|
      segment_name = segment.elements[1].text_value
      if child.respond_to?(segment_name.to_sym)
        child = child.send(segment_name.to_sym)
      else
        return nil
      end
    }

    child
  end

  def call(method:, args:)
    assert_method_exists!(method: method)
    @methods[method.to_sym].call(*args)
  end

  private
  def assert_defined!(identifier:)
    raise "Undefined variable: #{identifier}" unless symbols.has_key?(identifier.to_sym)
  end

  def assert_method_exists!(method:)
    raise "Undefined method: #{method}" unless @methods.has_key?(method.to_sym)
  end
end

class EquationEngine
  attr_accessor :parser, :context

  def initialize(default: {}, methods: {})
    @parser = EquationParser.new
    @context = Context.new(default: default, methods: methods)
  end

  def parse(rule:)
    parsed_rule = @parser.parse(rule)
    raise "Parse Error: #{@parser.failure_reason}" unless parsed_rule

    parsed_rule
  end

  def parse_and_eval(rule:)
    parse(rule: rule).value(ctx: @context)
  end

  def eval(rule:)
    rule.value(ctx: @context)
  end

  def eval_with(rule:, values: {})
    rule.value(ctx: @context.tap { |x|
      x.transient_symbols = values
    })
  end
end
