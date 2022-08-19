require 'equation'

RSpec.describe EquationEngine do
  context 'with valid input and an empty environment' do
    it 'evals numeric literals' do
      parser = described_class.new
      expect(parser.eval(rule: '1')).to eq 1.0
      expect(parser.eval(rule: '1.0')).to eq 1.0
      expect(parser.eval(rule: '-1.0')).to eq -1.0
    end

    it 'evals string literals' do
      parser = described_class.new
      expect(parser.eval(rule: '"HELLO :)"')).to eq "HELLO :)"
    end

    it 'evals range literals' do
      parser = described_class.new
      expect(parser.eval(rule: '1..5')).to eq 1..5
    end

    it 'evals boolean literals' do
      parser = described_class.new
      expect(parser.eval(rule: 'true')).to eq true
      expect(parser.eval(rule: 'false')).to eq false
    end

    it 'evals null literals' do
      parser = described_class.new
      expect(parser.eval(rule: 'nil')).to eq nil
      expect(parser.eval(rule: 'null')).to eq nil
    end

    it 'does arithmetic' do
      parser = described_class.new
      expect(parser.eval(rule: '1 + 1')).to eq 2
      expect(parser.eval(rule: '1 - 1')).to eq 0
      expect(parser.eval(rule: '1 - -1')).to eq 2
      expect(parser.eval(rule: '1 - 1 - 1')).to eq -1
      expect(parser.eval(rule: '1 + 1 + 1')).to eq 3
      expect(parser.eval(rule: '1 + 2 * 2')).to eq 5
      expect(parser.eval(rule: '5 % 2')).to eq 1
      expect(parser.eval(rule: '1 + 5 % 5')).to eq 1
    end

    it 'does string comparisons' do
      parser = described_class.new
      expect(parser.eval(rule: '"HELLO" == "HELLO"')).to eq true
      expect(parser.eval(rule: '"HELLO" != "BYE"')).to eq true
    end

    it 'does regex comparisons' do
      parser = described_class.new
      expect(parser.eval(rule: '"GARBAGE" =~ "G.....E"')).to eq true
      expect(parser.eval(rule: '"GARBAGE" =~ "^G"')).to eq true
      expect(parser.eval(rule: '"127.0.0.1" =~ "^([0-9]{1,3}\.){3}[0-9]{1,3}$"')).to eq true
    end

    it 'handles negations' do
      parser = described_class.new
      expect(parser.eval(rule: '!false')).to eq true
      expect(parser.eval(rule: '!!false')).to eq false
      expect(parser.eval(rule: '!1')).to eq false
      expect(parser.eval(rule: '!!1')).to eq true
      expect(parser.eval(rule: '!!!!!!!!1')).to eq true
      expect(parser.eval(rule: '!(1 == 2)')).to eq true
    end
  end

  context 'with valid input and a populated environment' do
    it 'recognizes variables' do
      parser = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(parser.eval(rule: '$age')).to eq 9
      expect(parser.eval(rule: '$name')).to eq "Dumpling"
    end

    it 'evals expressions that use variables' do
      parser = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(parser.eval(rule: '$age == 9')).to eq true
      expect(parser.eval(rule: '$name == "Dumpling"')).to eq true
    end

    it 'retrieves properties of variables' do
      parser = described_class.new(default: {age: 9, name: "Dumpling"})
      expect(parser.eval(rule: '$name.length')).to eq 8
    end

    it 'executes methods' do
      parser = described_class.new(default: {age: 9, name: "Dumpling"}, methods: {random: ->() { 4 }})
      expect(parser.eval(rule: 'random() == 4')).to eq true
      expect(parser.eval(rule: 'random()')).to eq 4
    end

    it 'executes methods with arguments' do
      parser = described_class.new(default: {age: 9, name: "Dumpling"}, methods: {reverse: ->(s) { s.reverse }})
      expect(parser.eval(rule: 'reverse($name)')).to eq "gnilpmuD"
      expect(parser.eval(rule: 'reverse("hello")')).to eq "olleh"
    end
  end

  context 'with comparisons' do
    it 'does ands' do
      parser = described_class.new(default: {age: 9, name: "OMAR"})
      expect(parser.eval(rule: '$age == 9 && $name == "OMAR"')).to eq true
      expect(parser.eval(rule: '$age == "impossible" && $name == "OMAR"')).to eq false
    end

    it 'does ors' do
      parser = described_class.new(default: {age: 9, name: "OMAR"})
      expect(parser.eval(rule: '$age == "impossible" || $name == "OMAR"')).to eq true
      expect(parser.eval(rule: '$age == "impossible" || $name == "wrong"')).to eq false
      expect(parser.eval(rule: '$age == "impossible" || 10')).to eq 10
    end

    it 'follows precedence rules' do
      parser = described_class.new(default: {age: 9, name: "OMAR"})
      expect(parser.eval(rule: '$age == "impossible" && $name == "OMAR" || 10')).to eq 10
    end
  end
end
