class Customer < Third
  has_permissions     :as_business_object
  has_documents       :graphic_charter
  has_address         :bill_to_address
  
  belongs_to :factor
  belongs_to :customer_solvency
  belongs_to :customer_grade
  belongs_to :creator, :class_name => 'User'
  
  has_one  :head_office
  has_many :establishments, :conditions => ["type IS NULL"]
  
  has_attached_file :logo, 
                    :styles       => { :thumb => "100x100" },
                    :path         => ":rails_root/assets/thirds/logos/:id.:style",
                    :url          => "/customers/:id.:extension"                    # TODO maybe change that url
  
  validates_presence_of   :bill_to_address, :head_office
  validates_uniqueness_of :name
  
  # papercilp plugin validations
  with_options :if => :logo do |v|
    v.validates_attachment_content_type :logo, :content_type => [ 'image/jpg', 'image/png','image/jpeg']
    v.validates_attachment_size         :logo, :less_than => 3.megabytes
  end
  
  validates_associated    :establishments, :head_office
  validate :uniqueness_of_siret_number , :if => :head_office
  
  
  after_save :save_establishments, :save_head_office
  
  # for pagination : number of instances by index page
  CUSTOMERS_PER_PAGE = 15
  
  named_scope :activates, :conditions => {:activated => true}
  
  has_search_index :only_attributes    => [:name, :siret_number],
                   :only_relationships => [:legal_form, :establishments],
                   :main_model         => true
  
  @@form_labels[:factor]            = "Compagnie d'affacturage :"
  @@form_labels[:customer_solvency] = "Solvabilité :"
  @@form_labels[:customer_grade]    = "Note relation client :"
  @@form_labels[:logo]              = "Logo :"
  @@form_labels[:created_at]        = "Créé le :"
  @@form_labels[:creator]           = "Créé par :"
  
  def payment_time_limit
    customer_grade.payment_time_limit
  end
  
  def payment_method
    customer_solvency.payment_method
  end
  
  def factorised?
    factor_id
  end
  
  def was_factorised?
    factor_id_was
  end
  
  def contacts
    establishments.collect(&:contacts).flatten
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
  
  def head_office_attributes=(head_office_attributes)
    attributes = head_office_attributes.first
    if head_office.nil?
      build_head_office(attributes)
    else
      head_office.attributes = attributes 
    end
  end
  
  def save_head_office
    head_office.save(false)
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
  
  def activated_establishments
    establishments.select(&:activated)
  end
  
  def build_establishment(attributes = {})
    self.establishments.build(attributes)
  end
  
  def uniqueness_of_siret_number
    objects       = establishments + [head_office]
    all_siret_numbers = {}
    objects.each {|n| all_siret_numbers.merge!(n => n.siret_number)}
    
    message = ActiveRecord::Errors.default_error_messages[:taken]
    objects.each do |establishment|
      other_siret_numbers = all_siret_numbers.reject {|obj, v| establishment == obj}
      establishment.errors.add(:siret_number, message) if other_siret_numbers.values.include?(establishment.siret_number)
    end
  end
end
