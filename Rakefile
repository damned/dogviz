require 'bundler/setup'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['tests/test*.rb']
  t.verbose = true
end

require 'colorize'
at_exit {
  if $?.exitstatus == 0
    puts 'PASSED'.green
  else
    puts 'FAILED'.red
  end
}