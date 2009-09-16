class Customer < Third
  has_permissions :as_business_object
  has_documents :graphic_charter, :logo
  
  belongs_to :payment_method
  belongs_to :payment_time_limit
  has_many :establishments
  
  validates_uniqueness_of :name, :siret_number # don't put that in third.rb because validation should be only for customer (and not all thirds)
  validates_associated :establishments, :contacts
  
  named_scope :activates, :conditions => {:activated => true}
  
  after_update :save_establishments
  
  has_search_index :only_attributes    => [:name, :siret_number],
                   :only_relationships => [:activity_sector, :legal_form, :contacts, :establishments],
                   :main_model         => true
  
  def activated_establishments
    establishment_array = []
    self.establishments.each {|establishment| establishment_array << establishment if establishment.activated}
    return establishment_array
  end

  # customer.contacts_all            => array
  #
  # return the direct contacts of the customer,
  # with the contacts of all its establishments.
  #
  def contacts_all
    contacts = []
    #OPTIMIZE can this loop be optimize with an unique sql request ?
    self.establishments.each do |establishment|
      establishment.contacts.each do |contact|
        contacts << contact
      end
    end

    self.contacts + contacts
  end

  def establishment_attributes=(establishment_attributes)
    establishment_attributes.each do |attributes|
      if attributes[:id].blank?
        establishments.build(attributes)
      else
        establishment = establishments.detect { |t| t.id == attributes[:id].to_i }
        establishment.attributes = attributes
      end
    end
  end

  def save_establishments
    establishments.each do |e|
      if e.should_destroy?
        e.destroy
      elsif e.should_update?
        e.save(false)
      end
    end
  end

end
