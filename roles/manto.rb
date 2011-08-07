name "manto"
	run_list "recipe[mysql::client]", "recipe[application]"
 
	override_attributes :apps => { 
	  :manto => { 
	    :production => { 
	      :run_migrations => true,
	      :force => false
	    },
	    :staging => {
	      :run_migrations => true,
	      :force => true
	    }
	  }
	}
