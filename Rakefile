require 'rake'
require 'rake/testtask'

task :default => :test

desc 'Running standard tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = '**/test/**/*_test.rb'
  t.verbose = true
  t.warning = false
end
