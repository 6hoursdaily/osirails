class Order < ActiveRecord::Base
  # Relationships
  belongs_to :society_activity_sector
  belongs_to :order_type
  belongs_to :customer
  belongs_to :establishment
  belongs_to :commercial, :class_name => 'Employee'
  has_one :step_commercial
  has_one :step_invoicing

  # Validations
  validates_presence_of :order_type
  #  validates_presence_of :establishment
  validates_presence_of :customer
  
  # Create all orders_steps after create
  def after_create
    order_type.activated_steps.each do |step|
      if step.parent.nil?
        step.name.camelize.constantize.create(:order_id => self.id, :status => 'unstarted')
      else
        step.name.camelize.constantize.create(step.parent.name + '_id' => self.send(step.parent.name).id, :status => 'unstarted')
      end
    end
  end

  ## Return a tree with activated step
  #def tree
  #  steps =[]
  #  step_objects = []
  #  self.order_type.sales_processes.each do |sales_process|
  #    steps << sales_process.step if sales_process.activated
  #  end
  #  steps.each do |step|
  #    unless step.parent_id.nil?
  #      step_objects << step.name.camelize.constantize.find_by_order_id(self.id)
  #    else
  #      step_name = step.name + "_order"
  #      step_objects << step_name.camelize.constantize.find_by_order_id(self.id)
  #    end
  #  end
  #  step_objects
  #end

  # Return all steps of the order
  def steps
    order_type.sales_processes.collect { |sp| sp.step if sp.activated }
  end

  # Return a has for advance statistics
  def advance
    steps_obj = []
    advance = {}
    steps.each do |step|
      next if step.parent
      steps_obj += send(step.name).childrens
    end
    advance[:total] = steps_obj.size
    advance[:terminated] = 0
    steps_obj.each { |s| advance[:terminated] += 1 if s.terminated? }
    advance
  end

  ## Return remarks's order
  def remarks
    remarks = []
    OrdersSteps.find(:all, :conditions => ["order_id = ?", self.id]).each {|order_step| order_step.remarks.each {|remark| remarks << remark} }
    remarks
  end

  ## Return missing elements's order
  def missing_elements
    missing_elements = []
    OrdersSteps.find(:all, :conditions => ["order_id = ?", self.id]).each {|order_step| order_step.missing_elements.each {|missing_element| missing_elements << missing_element} }
    missing_elements
  end

end