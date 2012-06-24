name "init"
description "standard package"
override_attributes(
  "java" => {
    "install_flavor" => "openjdk"
  }
)
run_list (
    "recipe[java]"
)
