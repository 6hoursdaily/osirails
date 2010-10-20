class PurchaseOrder < ActiveRecord::Base
  STATUS_DRAFT                  = 1
  STATUS_CONFIRMED              = 2
  STATUS_PROCESSING_BY_SUPPLIER = 3
  STATUS_COMPLETED              = 4
  STATUS_CANCELLED              = 5
  
  REQUESTS_PER_PAGE = 5
  
  has_permissions :as_business_object, :additional_class_methods => [ :cancel ]
  has_reference :prefix => :purchases
  has_address :address
  has_contact :supplier_contact, :accept_from => :supplier_contacts
  
  has_many :purchase_order_supplies
  has_many :existing_and_unreferenced_purchase_order_supplies, :class_name => "PurchaseOrderSupply", :conditions => ["comment_line IS NULL"]
  has_many :existing_purchase_order_supplies, :class_name => "PurchaseOrderSupply", :conditions => ["supply_id IS NOT NULL AND comment_line IS NULL"]
  has_many :unreferenced_purchase_order_supplies, :class_name => "PurchaseOrderSupply", :conditions => ["supply_id IS NULL AND comment_line IS NULL"]
  has_many :comment_lines, :class_name => "PurchaseOrderSupply", :conditions => ["supply_id IS NULL AND comment_line IS NOT NULL"]
  
  has_many :supplier_supplies, :finder_sql => 'SELECT DISTINCT s.* FROM supplier_supplies s INNER JOIN (purchase_order_supplies t) ON (t.purchase_order_id = #{id}) WHERE (s.supplier_id = #{supplier_id} AND s.supply_id = t.supply_id)'
  has_many :purchase_delivery_items, :through => :purchase_order_supplies
  has_many :purchase_deliveries, :finder_sql => '
                                    SELECT DISTINCT purchase_deliveries.*
                                    FROM purchase_orders 
                                    INNER JOIN purchase_order_supplies
                                    ON #{id} = purchase_order_supplies.purchase_order_id
                                    INNER JOIN purchase_delivery_items
                                    ON purchase_order_supplies.id = purchase_delivery_items.purchase_order_supply_id
                                    INNER JOIN purchase_deliveries
                                    ON purchase_delivery_items.purchase_delivery_id = purchase_deliveries.id
                                    ORDER BY purchase_deliveries.status, purchase_deliveries.cancelled_at DESC, purchase_deliveries.received_on DESC, purchase_deliveries.received_by_forwarder_on DESC, purchase_deliveries.shipped_on DESC, purchase_deliveries.processing_by_supplier_since DESC
                                    '
  
  belongs_to :invoice_document,   :class_name => "PurchaseDocument"
  belongs_to :quotation_document, :class_name => "PurchaseDocument"
  belongs_to :user
  belongs_to :canceller, :class_name => "User", :foreign_key => :cancelled_by_id
  belongs_to :supplier
  belongs_to :quotation
  
  cattr_accessor :form_labels
  @@form_labels = Hash.new
  @@form_labels[:supplier]          = "Fournisseur :"
  @@form_labels[:employee]          = "Demandeur :"
  @@form_labels[:user]              = "Créateur de la demande :"
  @@form_labels[:reference]         = "Référence :"
  @@form_labels[:statut]            = "Statut :"
  @@form_labels[:cancelled_comment] = "Raison de l'annulation :"
  
  validates_presence_of :user_id, :supplier_id
  validates_presence_of :cancelled_by_id, :cancelled_comment, :if => :cancelled?
  validates_presence_of :canceller, :if => :cancelled_by_id
  validates_presence_of :quotation_document, :reference, :if => :confirmed?
  validate :validates_length_of_purchase_order_supplies
  
  validates_inclusion_of :status, :in => [ STATUS_DRAFT ], :if => :new_record?
  validates_inclusion_of :status, :in => [ STATUS_DRAFT, STATUS_CONFIRMED ], :if => :was_draft?
  validates_inclusion_of :status, :in => [ STATUS_CONFIRMED, STATUS_PROCESSING_BY_SUPPLIER, STATUS_CANCELLED ], :if => :was_confirmed?
  validates_inclusion_of :status, :in => [ STATUS_PROCESSING_BY_SUPPLIER, STATUS_COMPLETED, STATUS_CANCELLED ], :if => :was_processing_by_supplier?
  validates_inclusion_of :status, :in => [ STATUS_COMPLETED ], :if => :was_completed?
  validates_inclusion_of :status, :in => [ STATUS_CANCELLED ], :if => :was_cancelled?
  
  validates_associated :purchase_order_supplies, :supplier_supplies
  validates_associated :invoice_document, :if => :completed?
  validates_associated :quotation_document, :if => :confirmed?
  
  named_scope :pending, :conditions => ["purchase_orders.status = ? OR purchase_orders.status = ? OR purchase_orders.status = ?", STATUS_DRAFT, STATUS_CONFIRMED, STATUS_PROCESSING_BY_SUPPLIER ],
                        :order => "purchase_orders.created_at DESC"
  named_scope :completed, :conditions => ["purchase_orders.status = ?", STATUS_COMPLETED ],
                        :order => "purchase_orders.completed_on DESC"
  named_scope :closed, :conditions => ["purchase_orders.status = ? OR purchase_orders.status = ?", STATUS_COMPLETED, STATUS_CANCELLED ],
                        :order => "purchase_orders.cancelled_at DESC, purchase_orders.completed_on DESC"
  
  before_validation :build_supplier_supplies, :build_associated_request_order_supplies
  
  before_validation_on_create :initialize_to_draft
  
  after_save :save_purchase_order_supplies, :save_supplier_supplies, :save_request_order_supplies
  after_save :destroy_request_order_supplies_deselected

  before_destroy :can_be_deleted?
  
  def validates_length_of_purchase_order_supplies
    errors.add(:purchase_order_supplies, "Veuillez sélectionner au moins une fourniture") if purchase_order_supplies.reject(&:should_destroy?).empty?
  end
  
  def initialize_to_draft
    self.status = STATUS_DRAFT
  end
  
  def total_duty
    purchase_order_existing_supplies.collect(&:total_with_prizegiving).sum
  end 
  
  def total_amount_duty
    (1.0 - (prizegiving.to_f / 100.0)) * total_duty.to_f
  end
  
  def total_taxes
    purchase_order_existing_supplies.collect(&:amount_taxes).sum
  end
  
  def total_price
    total_amount_duty + miscellaneous + total_taxes
  end
  
  def total_price
    cancelled? ? @purchase_order_supplies.collect(&:purchase_order_supply_total).sum : purchase_order_supplies.reject(&:cancelled?).collect(&:purchase_order_supply_total).sum
  end
  
  def purchase_order_existing_supplies
    purchase_order_supplies.select{|p| p.supply_id && !p.comment_line}
  end
  
  def purchase_order_unreferenced_supplies
    purchase_order_supplies.reject{|p| p.supply_id && p.comment_line}
  end
  
  def purchase_order_comment_lines
    purchase_order_supplies.select{|p| !p.supply_id && p.comment_line}
  end
  
  def draft?
    status == STATUS_DRAFT
  end
  
  def confirmed?
    status == STATUS_CONFIRMED
  end
  
  def processing_by_supplier?
    status == STATUS_PROCESSING_BY_SUPPLIER
  end
  
  def completed?
    status == STATUS_COMPLETED
  end
  
  def cancelled?
    new_record? ? false : ( status==STATUS_CANCELLED ? true : ((purchase_order_supplies.select(&:was_cancelled?).size == purchase_order_supplies.size and (purchase_order_supplies.select(&:was_cancelled?).size != 0) ? true : false)))
  end
  
  def was_draft?
    status_was == STATUS_DRAFT
  end
  
  def was_confirmed?
    status_was == STATUS_CONFIRMED
  end
  
  def was_processing_by_supplier?
    status_was == STATUS_PROCESSING_BY_SUPPLIER
  end
  
  def was_completed?
    status_was == STATUS_COMPLETED
  end
  
  def was_cancelled?
    new_record? ? false : (status_was == STATUS_CANCELLED ? true : ((purchase_order_supplies.select(&:was_cancelled?).size == purchase_order_supplies.size and purchase_order_supplies.select(&:was_cancelled?).size != 0) ? true : false))
  end
  
  def can_be_confirmed?
    was_draft? and !was_cancelled? and !was_confirmed? and can_be_confirmed_with_purchase_request_supplies_associated?
  end
  
  def can_be_processed_by_supplier?
    was_confirmed?
  end
  
  def can_be_completed?
    are_all_purchase_order_supplies_treated? && (was_confirmed? || was_processing_by_supplier?)
  end
  
  def can_be_cancelled?
    was_confirmed? or was_processing_by_supplier?
  end
  
  def can_be_deleted?
    !new_record? and was_draft?
  end
  
  def can_be_edited?
    was_draft?
  end
  
  def can_add_purchase_delivery?
    (confirmed? or processing_by_supplier?) and is_remaining_quantity_for_purchase_delivery? and !cancelled?
  end
  
  def can_be_confirmed_with_purchase_request_supplies_associated?
    purchase_order_supplies.each{ |pos|
      pos.purchase_request_supplies.each{ |prs|
        if prs.confirmed_purchase_order_supply
          errors.add(:purchase_order_supplies, "Certains éléments empêchent la confirmation de votre ordre d'achats")
          return false
        end
      }
    }
    true
  end
  
  def confirm
    if can_be_confirmed?
      update_reference
      self.confirmed_on = Time.now
      self.status = STATUS_CONFIRMED
      return self.save
    end
    false
  end
  
  def process_by_supplier
    if can_be_processed_by_supplier?
      self.processing_by_supplier_since = Time.now
      self.status = STATUS_PROCESSING_BY_SUPPLIER
      return self.save
    end
  end
  
  def complete
    if can_be_completed?
      self.completed_on = Time.now
      self.status = STATUS_COMPLETED
      return self.save
    end
    false
  end
  
  def cancel
    if can_be_cancelled?
      self.cancelled_at = Time.now
      self.status = STATUS_CANCELLED
      return self.save
    end
    false
  end
  
  def not_cancelled_purchase_order_supplies
    purchase_order_supplies.select{ |pos| !pos.cancelled? }
  end
  
  def associated_purchase_request_supplies
    purchase_order_supplies.collect(&:purchase_request_supplies).flatten.compact.uniq
  end
  
  def associated_purchase_requests
    associated_purchase_request_supplies.collect(&:purchase_request).uniq
  end
  
  def is_remaining_quantity_for_purchase_delivery?
    purchase_order_supplies.each{ |pos| return true if (pos.remaining_quantity_for_purchase_delivery > 0 && !pos.was_cancelled?) }
    false
  end
  
  def are_all_purchase_order_supplies_treated?
    return false if not_cancelled_purchase_order_supplies.empty?
    not_cancelled_purchase_order_supplies.each{ |pos| return false unless pos.treated? }
    true
  end
  
  def quotation_document_attributes=(quotation_document_attributes)
    self.quotation_document = PurchaseDocument.new(quotation_document_attributes.first)
  end
  
  def invoice_document_attributes=(invoice_document_attributes)
    self.invoice_document = PurchaseDocument.new(invoice_document_attributes.first)
  end
  
  def build_associated_request_order_supplies
    purchase_order_supplies.each do |e|
      next unless e.purchase_request_supplies_ids
      e.purchase_request_supplies_ids.split(';').map(&:to_i).each do |s|
        if s > 0 and purchase_request_supply = PurchaseRequestSupply.find_by_id(s)
          e.request_order_supplies.build(:purchase_request_supply_id => purchase_request_supply.id) unless e.request_order_supplies.detect{|t| t.purchase_request_supply_id == s.to_i}
        end
      end
    end
  end
  
  def purchase_order_supply_attributes=(purchase_order_supply_attributes)
    purchase_order_supply_attributes.each do |attributes|
      if attributes[:id].blank?
        purchase_order_supplies.build(attributes)
      else
        purchase_order_supply = purchase_order_supplies.detect { |t| t.id == attributes[:id].to_i }
        purchase_order_supply.attributes = attributes
      end
    end
  end
  
  def build_supplier_supplies
    purchase_order_supplies.each do |e|
      unless SupplierSupply.find_by_supply_id_and_supplier_id(e.supply_id, supplier_id)
        supplier_supplies.build(:supplier_id          => supplier_id,
                                :supply_id            => e.supply_id,
                                :supplier_reference   => e.supplier_reference,
                                :supplier_designation => e.supplier_designation,
                                :fob_unit_price       => e.fob_unit_price,
                                :taxes                => e.taxes)
      end
    end
  end
  
  def build_with_purchase_request_supplies(list_of_supplies)
    list_of_supplies.collect do |purchase_request_supply|
      supplier_supply = SupplierSupply.find_by_supply_id_and_supplier_id(purchase_request_supply.supply_id, self.supplier_id)
      purchase_order_supply = self.purchase_order_supplies.build({:supply_id      => purchase_request_supply.supply_id, 
                                                                  :quantity       => purchase_request_supply.expected_quantity,
                                                                  :taxes          => supplier_supply.taxes, 
                                                                  :fob_unit_price => supplier_supply.fob_unit_price})
      purchase_order_supply.unconfirmed_purchase_request_supplies.each do |e|
        purchase_order_supply.request_order_supplies.build(:purchase_request_supply_id => e.id)
      end
    end
  end
  
  def save_request_order_supplies
    purchase_order_supplies.each do |e|
      e.request_order_supplies.each do |s|
        s.save(false)
      end
    end
  end
  
  def save_supplier_supplies
    supplier_supplies.each do |e|
      e.save(false)
    end
  end
  
  def save_purchase_order_supplies
    purchase_order_supplies.each do |e|
      if e.should_destroy.to_i != 1
        e.save(false)
      else
        e.destroy()
      end
    end
  end
  
  def put_purchase_order_status_to_cancelled
    self.purchase_order_supplies.reload
    if cancelled?
      self.cancelled_by_id = purchase_order_supplies.all(:order => "cancelled_at").last unless was_cancelled?
      self.cancelled_comment = "Annulation de toutes les fournitures commandées dans cet ordre." unless was_cancelled?
      self.cancel unless was_cancelled?
      self.reload
    end
  end
  
  def destroy_request_order_supplies_deselected
    self.purchase_order_supplies.each do |e|
      if e.purchase_request_supplies_deselected_ids
        e.purchase_request_supplies_deselected_ids.split(';').each do |s|
          if (s != '' && purchase_request_supply = PurchaseRequestSupply.find(s))
            request_order_supply = e.request_order_supplies.detect{|t| t.purchase_request_supply_id == s.to_i}
            request_order_supply.destroy if request_order_supply
          end
        end
      end
    end
  end
end
