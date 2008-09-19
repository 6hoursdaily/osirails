class JobsController < ApplicationController
  
  helper :employees
  
  def index
    @jobs = Job.find(:all)
  end
  
  def new
    @job= Job.new 
  end
  
  def edit
    @job= Job.find(params[:id])
  end
  
  def show
    @job = Job.find(params[:id])
  end
  
  def create
    @job = Job.new(params[:job])
    respond_to do |format|
      if @job.save
        @jobs = Job.find(:all)
        unless params['employee_id']==""
          @employee = Employee.find(params['employee_id'])
          @numbers = @employee.numbers
        end
        flash[:notice] = 'La fonction a été crée avec succés.'
        format.html { redirect_to(jobs_path) }  
        format.js  
      else
        format.html { render :action => "new" }
        format.js {render :action => "job_form", :layout => false}
      end
    end
    
  end
  
  def update
    @job = Job.find(params[:id])
    
    respond_to do |format|
      if @job.update_attributes(params[:job])
        flash[:notice] = 'La fonction  a été modifié avec succés.'
        format.html { redirect_to(@job) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def destroy
    @job = Job.find(params[:id])
    @job.destroy 

    respond_to do |format|
      format.html { redirect_to(jobs_url) }
    end
  end
  
end
