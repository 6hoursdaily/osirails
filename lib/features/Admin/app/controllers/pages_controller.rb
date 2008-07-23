class PagesController < ApplicationController
  def index

   render :action => 'list'
  end

  def new
   @pages = Osirails::Page.new
  end
  
  def create
    @pages = Osirails::Page.new(params[:pages])
      if @pages.save
        redirect_to :action => 'index'
      else
        render :action => 'add'
      end
  end
  def move_up
    page = Osirails::Page.find_by_id(params[:id])
    page.move_higher
    redirect_to pages_path
  end
  
  def move_down
    page = Osirails::Page.find_by_id(params[:id])
    page.move_lower
    redirect_to pages_path
  end
  
  def delete
    page = Osirails::Page.find_by_id(params[:id])
    page.delete_item
    redirect_to pages_path
  end 
end