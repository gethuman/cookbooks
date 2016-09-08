def fixture(name)
  cookbook "mingw_#{name}", path: "test/fixtures/cookbooks/mingw_#{name}"
end

source 'https://supermarket.chef.io'

metadata

group :integration do
  fixture 'tdm_install'
  fixture 'msys2_install'
end
