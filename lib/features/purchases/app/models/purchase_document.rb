class PurchaseDocument < ActiveRecord::Base
  
  has_permissions :as_business_object
  
#  has_one :parcel_delivery_document, :class_name => "Parcel", :foreign_key => :delivery_document_id
#  has_one :purchase_order_quotation_document, :class_name => "PurchaseOrder", :foreign_key => :quotation_document_id
#  has_one :purchase_order_invoice_document, :class_name => "PurchaseOrder", :foreign_key => :invoice_document_id
  
  has_attached_file :purchase_document, 
                    :styles => { :thumb => "120x120" },
                    :path   => ":rails_root/assets/purchases/parcels/:id/delivery_documents/:id.:extension"
end
