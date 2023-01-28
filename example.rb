require_relative 'lib/equation.rb'
require "tty-prompt"
require "pp"

engine = EquationEngine.new(
  default: {
    x: 1,
    name: "OMAR",
    request: {
      path: "/api/login",
      method: "POST",
    },
  },
  methods: {
    rand10: ->() { rand(1..10) },
    random: ->() { 4 },
    reverse: ->(s) { s.reverse },
    any: ->(*more) { more.any? },
    all: ->(*more) { more.all? },
    none: ->(*more) { more.none? },
  }
)

pp(engine.context.symbols)
prompt = TTY::Prompt.new

while true do
  input = prompt.ask("equation>")
  begin
    puts engine.parse_and_eval(
      rule: input
    )
  rescue => e
    puts "#{e}"
  end
end
