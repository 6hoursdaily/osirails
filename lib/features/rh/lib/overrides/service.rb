require_dependency 'app/models/service'

class Service
  has_many :employees
  has_many :jobs

  def can_be_destroyed?
    self.employees.empty? and self.children.empty?
  end
  
  # return all responsibles (employees) for the service
  def responsibles
    jobs.select(&:responsible).collect(&:employees).flatten.uniq
  end
  
  # return all employees belonging to the current service according to the belonging jobs or the belonging employees
  def members
    Employee.all(:include => [:service, {:jobs => [:service] }], :conditions => ["services.id =? or services_jobs.id =?", id, id])
  end
end
