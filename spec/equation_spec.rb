require 'equation'

RSpec.describe EquationEngine do
  context 'with valid input and an empty environment' do
    it 'does not care about spaces' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: ' 1 ')).to eq 1.0
    end

    it 'evals numeric literals' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '1')).to eq 1.0
      expect(engine.parse_and_eval(rule: '1.0')).to eq 1.0
      expect(engine.parse_and_eval(rule: '-1.0')).to eq -1.0
    end

    it 'evals string literals' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '"HELLO :)"')).to eq "HELLO :)"
    end

    it 'evals range literals' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '1..5')).to eq 1..5
    end

    it 'evals boolean literals' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: 'true')).to eq true
      expect(engine.parse_and_eval(rule: 'false')).to eq false
    end

    it 'evals null literals' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: 'nil')).to eq nil
      expect(engine.parse_and_eval(rule: 'null')).to eq nil
    end

    it 'does arithmetic' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '1 + 1')).to eq 2
      expect(engine.parse_and_eval(rule: '1 - 1')).to eq 0
      expect(engine.parse_and_eval(rule: '1 - -1')).to eq 2
      expect(engine.parse_and_eval(rule: '1 - 1 - 1')).to eq -1
      expect(engine.parse_and_eval(rule: '1 + 1 + 1')).to eq 3
      expect(engine.parse_and_eval(rule: '1 + 2 * 2')).to eq 5
      expect(engine.parse_and_eval(rule: '5 % 2')).to eq 1
      expect(engine.parse_and_eval(rule: '1 + 5 % 5')).to eq 1
    end

    it 'does string comparisons' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '"HELLO" == "HELLO"')).to eq true
      expect(engine.parse_and_eval(rule: '"HELLO" != "BYE"')).to eq true
    end

    it 'does regex comparisons' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '"GARBAGE" =~ "G.....E"')).to eq true
      expect(engine.parse_and_eval(rule: '"GARBAGE" =~ "^G"')).to eq true
      expect(engine.parse_and_eval(rule: '"127.0.0.1" =~ "^([0-9]{1,3}\.){3}[0-9]{1,3}$"')).to eq true
    end

    it 'handles negations' do
      engine = described_class.new
      expect(engine.parse_and_eval(rule: '!false')).to eq true
      expect(engine.parse_and_eval(rule: '!!false')).to eq false
      expect(engine.parse_and_eval(rule: '!1')).to eq false
      expect(engine.parse_and_eval(rule: '!!1')).to eq true
      expect(engine.parse_and_eval(rule: '!!!!!!!!1')).to eq true
      expect(engine.parse_and_eval(rule: '!(1 == 2)')).to eq true
    end
  end

  context 'with valid input and a populated environment' do
    it 'recognizes variables' do
      engine = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(engine.parse_and_eval(rule: '$age')).to eq 9
      expect(engine.parse_and_eval(rule: '$name')).to eq "Dumpling"
    end

    it 'evals expressions that use variables' do
      engine = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(engine.parse_and_eval(rule: '$age == 9')).to eq true
      expect(engine.parse_and_eval(rule: '$name == "Dumpling"')).to eq true
    end

    it 'retrieves values from hashes with symbol and string type keys' do
      symbol_keys = {a: 123}
      string_keys = {"a" => 456}
      engine = described_class.new(default: {symbol: symbol_keys, string: string_keys})
      expect(engine.parse_and_eval(rule: '$symbol.a == 123')).to eq true
      expect(engine.parse_and_eval(rule: '$string.a == 456')).to eq true
    end

    it 'nonexistent keys return nil' do
      engine = described_class.new(default: {empty_hash: {}})
      expect(engine.parse_and_eval(rule: '$empty_hash.a == null')).to eq true
    end

    it 'retrieves properties of variables' do
      engine = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(engine.parse_and_eval(rule: '$name.length')).to eq 8
    end

    it 'executes methods' do
      engine = described_class.new(default: {age: 9, name: "Dumpling"}, methods: {random: ->() { 4 }})
      expect(engine.parse_and_eval(rule: 'random() == 4')).to eq true
      expect(engine.parse_and_eval(rule: 'random()')).to eq 4
    end

    it 'executes methods with arguments' do
      engine = described_class.new(default: {age: 9, name: "Dumpling"}, methods: {reverse: ->(s) { s.reverse }})
      expect(engine.parse_and_eval(rule: 'reverse($name)')).to eq "gnilpmuD"
      expect(engine.parse_and_eval(rule: 'reverse("hello")')).to eq "olleh"
    end
  end

  context 'with comparisons' do
    it 'does ands' do
      engine = described_class.new(default: {age: 9, name: "OMAR"})
      expect(engine.parse_and_eval(rule: '$age == 9 && $name == "OMAR"')).to eq true
      expect(engine.parse_and_eval(rule: '$age == "impossible" && $name == "OMAR"')).to eq false
    end

    it 'does ors' do
      engine = described_class.new(default: {age: 9, name: "OMAR"})
      expect(engine.parse_and_eval(rule: '$age == "impossible" || $name == "OMAR"')).to eq true
      expect(engine.parse_and_eval(rule: '$age == "impossible" || $name == "wrong"')).to eq false
      expect(engine.parse_and_eval(rule: '$age == "impossible" || 10')).to eq 10
    end

    it 'follows precedence rules' do
      engine = described_class.new(default: {age: 9, name: "OMAR"})
      expect(engine.parse_and_eval(rule: '$age == "impossible" && $name == "OMAR" || 10')).to eq 10
    end
  end
end
