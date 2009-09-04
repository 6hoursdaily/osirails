class EmployeesController < ApplicationController
  helper :salaries, :job_contract
  before_filter :load_collections, :only => [:new, :create, :edit, :update, :show]  
  method_permission :list => ["show"]
  
  # GET /employees
  def index
    @employees = params['all_employees'] || false ? Employee.all : Employee.actives
  end

  # GET /employees/:id
  def show
    @employee = Employee.find params[:id]
  end

  # GET /employees/new
  def new
    @employee = Employee.new
    @employee.numbers.build
    @employee.address = Address.new
  end

  # GET /employees/:id/edit
  def edit
    @employee = Employee.find params[:id] 
  end

  # POST /employees
  def create
    # regroupe the two parts of social security number
    params[:employee][:social_security_number] = params['social_security_number'].values.join " "
    params.delete('social_security_number')
    
    @employee = Employee.new params[:employee]

    if @employee.save
      flash[:notice] = "L'employé(e) a été créé(e) avec succés."
      redirect_to @employee
    else
      render :action => "new"
    end
  end

  # PUT /employees/:id
  def update
    @employee = Employee.find params[:id]
    @address  = @employee.address

    # regroupe the two parts of social security number
    params[:employee][:social_security_number] = params['social_security_number'].values.join " "
    params.delete('social_security_number')
    
    # destroy all jobs if the params is nil
    params[:employee]['job_ids']||= []

    if @employee.update_attributes params[:employee]
      flash[:notice] = "L'employé(e) a été modifié(e) avec succés."
      redirect_to @employee
    else
      render :action => "edit"
    end
  end

  # DELETE /employees/:id
  def destroy
    @employee = Employee.find params[:id]
    unless @employee.destroy
      flash[:error] = "Une erreur est survenue à la suppression de l'employé(e)"
    end
    redirect_to employees_path
  end

  def load_collections
    @jobs     = Job.all
    @services = Service.all
  end 
end
