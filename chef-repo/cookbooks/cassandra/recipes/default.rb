include_recipe "cassandra::setup_repos"
include_recipe "cassandra::install"
include_recipe "cassandra::additional_settings"
include_recipe "cassandra::write_configs"
include_recipe "cassandra::restart_service"
