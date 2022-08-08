task :spec do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end

task :build_grammar do
  sh "tt lib/equation_grammar.treetop -fo lib/equation_grammar.rb"
end
