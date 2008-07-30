class BusinessObjectPermissionsController < ApplicationController
  def index
    @business_object_permissions = BusinessObjectPermission.find(:all, :group => 'has_permission_type')
  end

  def edit
    @business_object_permissions = BusinessObjectPermission.find(:all, :conditions => ["has_permission_type = ?", params[:id]], :include => [:role] )
  end

  def update
    transaction_error = BusinessObjectPermission.transaction do
      BusinessObjectPermission.update_all("`list` = 0, `view` = 0, `add` = 0, `edit` = 0, `delete` = 0", :has_permission_type => params[:id])
      BusinessObjectPermission.update_all("`list` = 1", :role_id => params[:list], :has_permission_type => params[:id])
      BusinessObjectPermission.update_all("`view` = 1", :role_id => params[:view], :has_permission_type => params[:id])
      BusinessObjectPermission.update_all("`add` = 1", :role_id => params[:add], :has_permission_type => params[:id])
      BusinessObjectPermission.update_all("`edit` = 1", :role_id => params[:edit], :has_permission_type => params[:id])
      BusinessObjectPermission.update_all("`delete` = 1", :role_id => params[:delete], :has_permission_type => params[:id])
    end
    if transaction_error
      flash[:notice] = "Les permissions ont été modifié avec succés"
    else
      flash[:error] = "Erreur lors de la mise à jour des permissions"      
    end
    redirect_to(edit_business_object_permission_path)
  end
end