#
# Cookbook Name:: mingw_install_tdm
# Recipe:: install32
#
# Copyright 2016 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'mingw::default'

root_path = "#{ENV['SYSTEMDRIVE']}\\mingw32"

mingw_get 'msys core - 32 bit' do
  package 'msys-base=2013072300-msys-bin.meta'
  root root_path
end

mingw_get 'msys core extensions - 32 bit' do
  package 'msys-coreutils-ext=5.97-3-*'
  root root_path
end

mingw_get 'msys perl - 32 bit' do
  package 'msys-perl-bin=5.8.8-*'
  root root_path
end

mingw_tdm_gcc 'TDM GCC - 32 bit' do
  version '5.1.0'
  flavor :sjlj_32
  root root_path
end
