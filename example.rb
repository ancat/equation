require_relative 'lib/equation.rb'

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

puts engine.eval(
  rule: ARGV[0]
)
