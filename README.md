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
