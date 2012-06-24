name "init"
description "standard package"
override_attributes(
  "java" => {
    "install_flavor" => "oracle"
  }
)
run_list (
    "recipe[java]"
)
