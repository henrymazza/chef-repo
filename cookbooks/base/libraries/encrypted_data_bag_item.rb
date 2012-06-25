class Chef
  class Recipe
    
    def encrypted_data_bag_item(bag, item, secret_file =
        Chef::EncryptedDataBagItem::DEFAULT_SECRET_FILE)
      DataBag.validate_name!(bag.to_s)
      DataBagItem.validate_id!(item)
      secret = EncryptedDataBagItem.load_secret(secret_file)
      EncryptedDataBagItem.load(bag, item, secret)
    rescue Exception
      Log.error("Failed to load data bag item: #{bag.inspect} #{item.inspect}")
      raise
    end

  end
end
