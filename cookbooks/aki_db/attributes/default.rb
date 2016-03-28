node.default[:unicorn][:port] = '3080'
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
