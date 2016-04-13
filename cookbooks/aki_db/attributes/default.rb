set['unicorn']['options'] = nil
node.default['rbenv']['user_installs'] = [
  { 'user'    => 'aki_db',
    'rubies'  => ['2.1.5'],
    'global'  => '2.1.5',
    'gems'    => {
      '2.1.5'    => [
        { 'name'    => 'bundler'
        }
      ]
    }
  }
]
