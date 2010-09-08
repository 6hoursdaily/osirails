ActionController::Routing::Routes.add_routes do |map|
  map.resources :contacts do |contact|
    contact.avatar 'avatar', :controller  => 'contacts',
                             :action      => 'avatar',
                             :conditions  => { :method => :get }
  end
  
  Contact.contacts_owners_models.each do |owner_model|
    map.resources owner_model.tableize.to_sym do |owner|
      owner.resources :contacts
    end
  end
end
