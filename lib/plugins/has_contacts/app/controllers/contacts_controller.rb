class ContactsController < ApplicationController
  helper :numbers
  # GET /:contact_owner/:contact_owner_id/contacts
  # 
  # ==== Examples
  #   GET /customers/1/contacts
  #   GET /supplier/3/contacts
  #
  def index
    hash = params.select{ |key, value| key.end_with?("_id") }
    raise "An error has occured. The ContactsController should receive at least 1 param which ends with '_id'" if hash.size < 1
    raise "An error has occured. The ContactsController shouldn't receive more than 1 params which ends with '_id'" if hash.size > 1
    
    owner_class = hash.first.first.chomp("_id").camelize.constantize
    owner_id = hash.first.last
    @contacts_owner = owner_class.send(:find, owner_id)

    @group_by = params[:group_by] || "type"
    @order_by = params[:order_by] || "asc" # ascendent
    @group_by_owner = params[:group_by] || false 

    render :layout => false
  end
  
  # GET /contacts/:id/avatar
  def avatar
    @contact = Contact.find(params[:contact_id])

    url     = @contact.avatar.path(:thumb)
    options = { :filename => @contact.avatar_file_name, :type => @contact.avatar_content_type, :disposition => 'inline' }
    
    respond_to do |format|
      format.jpg { send_data(File.read(url), options) }
      format.png { send_data(File.read(url), options) }
    end
  end

end
