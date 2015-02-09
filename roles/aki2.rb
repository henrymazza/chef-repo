name "aki2"
  override_attributes(
    # default['ruby_build']['upgrade'] = "none"
    :ruby_build => {
      "upgrade" => "sync"
    }
  )
run_list "recipe[aki2]"

