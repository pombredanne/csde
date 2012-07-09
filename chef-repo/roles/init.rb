name "init"
description "standard package"
run_list (
    "recipe[cassandra::install_from_release]"
)
