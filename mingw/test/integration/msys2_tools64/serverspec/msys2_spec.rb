require 'spec_helper'

set :path, "C:\\msys2\\bin;C:\\msys2\\mingw64\\bin;C:\\msys2\\usr\\bin;#{ENV['PATH']}"

describe command('gcc --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should include 'gcc.exe (Rev1, Built by MSYS2 project)' }
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
  its(:stdout) { should include 'GNU Make 4.1' }
  its(:stdout) { should include 'x86_64-pc-msys' }
end
