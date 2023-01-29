lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name = "equation"
  s.version = "0.6.2"
  s.authors = ["OMAR"]
  s.summary = "A rules engine for your Ruby apps."
  s.description = "Equation exposes a minimal environment to allow safe execution of Ruby code represented via a custom expression language."
  s.license = "MIT"
  s.homepage = "https://github.com/ancat/equation"

  s.files = Dir["README.md", "lib/**/*.rb"]

  s.required_ruby_version = ">= 2.5"
end
