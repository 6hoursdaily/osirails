class Third < ActiveRecord::Base
  has_one :address, :as => :has_address
  belongs_to :activity_sector
  belongs_to :third_type
  
  # has_many_polymorphic
  has_many :contacts_owners, 
#    :dependent => :destroy, 
    :as => :has_contact, :class_name => "ContactsOwners"
  has_many :contacts, :source => :contact, :foreign_key => "contact_id", :through => :contacts_owners, :class_name => "Contact"
  
  validates_presence_of :name
  validates_numericality_of :siret_number, :only_integer => true
  validates_numericality_of :banking_informations, :only_integer => true
end