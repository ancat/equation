# Equation [WIP]

A rules engine for your Ruby app! Use a constrained and relatively safe language to express logic for your Ruby app, without having to write Ruby. This allows you to use text (e.g. in a configuration file or database) to store logic in a way that can be updated independently from your code faster than it takes for a deploy without opening extra security vulnerabilities. 

Use cases include:

* writing rules to describe HTTP traffic that then gets dropped, like a WAF
* writing policies to express authorization logic
* etc

Modeled loosely after [Symfony Expression Language](https://symfony.com/doc/current/components/expression_language.html).

## Example

In this example, we'll use a rule to determine whether a request should be dropped or not. While the rule here is hardcoded into the program, it could just as easily be pulled from a database, some redis cache, etc instead. Rules can also be cached, saving you an extra parsing step.

```ruby
require 'equation'

# set up the execution environment and give it access to the rails request object
engine = EquationEngine.new(default: {
  age: 12,
  username: "OMAR",
  request: request
})

suspicious_request = engine.eval(rule: '$request.path == "/api/login" && $request.remote_ip == "1.2.3.4" && $username == "OMAR"')
if suspicious_request
  # log some things, notify some people
end
```

## Language Features

Because Equation is modeled after [Symfony Expression Language](https://symfony.com/doc/current/components/expression_language/syntax.html), it supports a lot of the same features. For a more exhaustive list, check out the [tests](https://github.com/ancat/equation/blob/main/spec/equation_spec.rb).

### Literals

* Strings: double quotes, e.g. `"hello world"`
* Numbers: all treated as floats, e.g. `0`, `-10`, `0.5`
* Arrays: square brackets, e.g. `[403, 404]` or `["yes", "no", "maybe"]`; can be mixed types
* Booleans: `true`, `false`
* Null: `nil`

### Variables

Variables are only made available to the engine at initialization. For example, given this setup code:

```ruby
engine = EquationEngine.new(default: {name: "OMAR", age: 12})
```

These variables and all their properties are accessible from within rules:

```
$name == "OMAR" # true
$name.length    # 4
$name.reverse   # RAMO
```

### Methods

Like variables, methods are only made available to the engine at initialization. They can take any number and type of arguments, including variables or return values from other methods.

```ruby
engine = EquationEngine.new(default: {age: 12}, methods: {is_even: ->(n) {n%2==0}})
```

`is_even` can now be called as follows:

```
is_even(5)    # false
is_even($age) # true
```

### Comparisons

```
$name == "Dumpling" && $age >= 12
$name in ["Dumpling", "Meatball"] || $age == 12
```
