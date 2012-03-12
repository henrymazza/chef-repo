name "imap_migrator"
	run_list "role[base]", "role[webserver]", "recipe[redis]", "recipe[resque]", "recipe[application]"
 
	override_attributes :apps => { 
	  :imap_migrator=> { 
	    :production => { 
	      :run_migrations => false,
	      :force => false
	    },
	    :staging => {
	      :run_migrations => false,
	      :force => false
	    }
	  }
	}

