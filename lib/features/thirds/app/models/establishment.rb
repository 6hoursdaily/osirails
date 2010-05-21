class Establishment  < ActiveRecord::Base
  include SiretNumber
  
  has_permissions :as_business_object
  
  has_address   :address, :one_or_many => :many
  has_contacts
  has_documents :photos
  has_number    :phone
  has_number    :fax
  
  belongs_to :customer
  belongs_to :establishment_type
  belongs_to :activity_sector_reference
  
  validates_presence_of :name, :address, :establishment_type_id
  validates_presence_of :establishment_type, :if => :establishment_type_id
  
  validates_uniqueness_of :siret_number, :allow_blank => true
  
  validates_associated :address
  
  # define if the object should be destroyed (after clicking on the remove button via the web site) # see the /customers/1/edit
  attr_accessor :should_destroy
  
  # define if the object should be updated 
  # should_update = 1 if the form is visible # see the /customers/1/edit
  # should_update = 0 if the form is hidden (after clicking on the cancel button via the web site) # see the /customers/1/edit
  attr_accessor :should_update
  
  # Search Plugin
  has_search_index :only_attributes    => [ :name, :activated ],
                   :only_relationships => [ :contacts, :address ]
  
  def name_and_full_address
    "#{self.name} (#{self.full_address})"
  end
  
  def should_destroy?
    should_destroy.to_i == 1
  end
  
  def should_update?
    should_update.to_i == 1
  end
end
