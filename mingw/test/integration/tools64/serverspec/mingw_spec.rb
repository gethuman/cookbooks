require 'spec_helper'

set :path, "C:\\mingw64\\bin;C:\\mingw64\\msys\\1.0\\bin;#{ENV['PATH']}"

describe command('gcc --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include 'gcc.exe (tdm64-1) 5.1.0' }
end

describe command('gcc -dumpmachine') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should eq "x86_64-w64-mingw32\n" }
end

describe command('as --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include '2.25' }
  its(:stdout) { should include 'x86_64-w64-mingw32' }
end

describe command('make --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include 'GNU Make 3.81' }
end
