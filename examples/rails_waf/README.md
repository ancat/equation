# Creating a Web App Firewall using Equation

Equation's goal is to remain pretty generic as far as rules engines go, so it can be used for any number of applications. In this example, we'll implement a basic [Web Application Firewall](https://www.cloudflare.com/learning/ddos/glossary/web-application-firewall-waf/) that uses Equation to let us describe malicious HTTP traffic so we can block it. To do this, we'll create a [concern](https://guides.rubyonrails.org/getting_started.html#using-concerns) that encapsulates all of Equation's functionality and exposes different ways to block traffic to any controller.

You can find this concern under `enforcer.rb` in this directory; to try it out you can copy it to `app/controllers/concerns/enforcer.rb` though I would not suggest running it in production. While it attempts to consciously increase performance by caching expensive behaviors (e.g. rule parsing, fetching remote resources) there's not much error checking and an accident could render your site inaccessible. Another caveat, while Equation is being used to demonstrate its abilities to block malicious traffic, the examples here are not exhaustive and there will certainly be all sorts of ways to bypass these rules. This example is intended to demonstrate just a narrow slice of its security use case.

## Adding Equation to Controllers

Because we're using a concern, you can include it in any controller by adding `include Enforcer` to it. We'll add it to the base `ApplicationController` so all underlying controllers can use it as needed.

```ruby
class ApplicationController < ActionController::Base
  include Enforcer

  ...
end
```

Now with this available to all controllers, let's try blocking traffic that might be sending us [XSS](https://owasp.org/www-community/attacks/xss/) attempts. We'll take the lazy way out and not allow any script tags in any request parameters. Once again, this is not exhaustive or foolproof but is just a teeny tiny sample. Using a sample vulnerable controller, we can get a classic alert box going.

![sad xss](https://user-images.githubusercontent.com/946975/185774771-b2296e99-0aee-448f-853e-89e3ab7989dd.png)

To start mitigating these without having to change any application code, let's just block all requests that have payloads that look like this. Let's start by adding this rule to the controller:

```ruby
class ApplicationController < ActionController::Base
  include Enforcer
  enforce rule: '$params_normalized =~ ".*<script>.*"'
end
```

This rule is applying the regular expression `.*<script>.*` to the entire request body. If that shows up anywhere, the application aborts early.

![no xss happy](https://user-images.githubusercontent.com/946975/185774772-d8664e75-7a77-4547-a7f1-5bff20896a16.png)

If we decide we want to block multiple types of payloads, we can add a `rules` method to our controller and return an array of rules.

```ruby
  private
  def rules
    [
      '$params_normalized =~ ".*<script>.*"', # Some XSS
      '$params_normalized =~ ".*union.*select.*"', # Some SQL Injection
      '$request.ip in ["3.4.5.6", "6.7.8.2"]', # IP Address of mean guys
      '(time() - $current_user.created_at) < 3600', # New users sending abusive traffic
    ]
  end
```

Now, this is just to demonstrate writing rules to block traffic. In many cases, if rules are going to be long lived or permanent, they should instead be expressed as regular Ruby code. This is not just for performance (less parsing, caching, etc) but also for writing tests, but also for testing as the functionality expressed in the rules may make more sense as part of the application instead.

## Adding Rules at Runtime

So the examples before are nice but because we're directly editing controller code, we still have to go through the process of running tests, deploying, etc which in many cases may defeat the purposes of having a flexible expression language. Instead, what we can do is have this concern fetch rules from a remote source using ActiveStorage.

```ruby
class ApplicationController < ActionController::Base
  include Enforcer
  enforce_from key: 'rules.json'
end
```

Now all our rules live independently of application code. Using the [Log4J vulnerability](https://blogs.juniper.net/en-us/security/in-the-wild-log4j-attack-payloads) as an example, we have a very specific payload we would like to block: anything containing `jndi:ldap`. While there's a huge variety of payloads for this vulnerability, this string shows up in all of them.

Before we can:
* Understand the root cause of the vulnerability...
* Test whether or not we're affected...
* Tell if we're being probed for this vulnerability...

We can deploy a `rules.json` file to an ActiveStorage backend (e.g. AWS S3) that our Rails app is already configured to use; all it needs to contain is the rules in JSON format.

```json
[
  "$params_normalized =~ \".*jdni:ldap.*\""
]
```

The enforcer concern caches remotely hosted rules for only five minutes, so it'll take at most that long for your application to have picked up the new rule, once again without having to deploy any new application code.
