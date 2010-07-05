class CreatePurchaseRequestSupplies < ActiveRecord::Migration
  def self.up
    create_table :purchase_request_supplies do |t|
      t.references  :purchase_request, :supply
      t.integer     :cancelled_by, :expected_quantity
      t.datetime    :expected_delivery_date, :cancelled_at
      
      t.timestamps
    end
  end

  def self.down
    drop_table :purchase_request_supplies
  end
end