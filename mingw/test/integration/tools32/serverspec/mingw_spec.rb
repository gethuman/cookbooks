require 'spec_helper'

set :path, "C:\\mingw32\\bin;C:\\mingw32\\msys\\1.0\\bin;#{ENV['PATH']}"

describe command('gcc --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include 'gcc.exe (tdm-1) 5.1.0' }
end

describe command('gcc -dumpmachine') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should eq "mingw32\n" }
end

describe command('as --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include '2.25.1' }
  its(:stdout) { should include 'mingw32' }
end

describe command('make --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include 'GNU Make 3.81' }
end
