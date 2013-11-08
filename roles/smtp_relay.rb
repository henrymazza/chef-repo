name "smtp_relay"
  run_list "recipe[postfix]"

  #node['postfix']['inet_interfaces']
  override_attributes :postfix => {
    :inet_interfaces => "all"
  }
