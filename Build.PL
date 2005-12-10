use Module::Build;

Module::Build->new(
  module_name => 'HTML::BBReverse',
  license => 'perl',
  create_makefile_pl => 'passthrough',
)->create_build_script;
