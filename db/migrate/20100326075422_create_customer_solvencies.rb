class CreateCustomerSolvencies < ActiveRecord::Migration
  def self.up
    create_table :customer_solvencies do |t|
      t.string     :name
      t.references :payment_method
    end
  end

  def self.down
    drop_table :customer_solventies
  end
end
