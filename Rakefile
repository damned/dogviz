require 'bundler/setup'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['tests/test*.rb']
end

require 'colorize'
at_exit {
  if $?.exitstatus == 0
    puts 'PASSED'.green
  else
    puts 'FAILED'.red
  end
}