module ServicesHelper
  
  # This method permit to verify if a service have got children or employees
  def show_delete_button(service)
    " &#124; "+link_to("Supprimer", service, {:method => :delete, :confirm => 'Etes vous sûr  ?' }) if service.can_delete?
  end
  
  # This method permit to have a services on <ul> type.
  def show_structured_services
    services = Service.find_all_by_service_parent_id
    list = []
    list << "<div class='hierarchic'><ul class=\"parent\">"
    list = get_children(services,list)
    list << "</ul></div>"
    list 
  end
  
  # This method permit to make a tree for services
  def get_children(services,list)
    services.each do |service|
      delete_button = show_delete_button(service)
      list << "<li class=\"menus\">#{service.name} &nbsp; <span class=\"action\">"+link_to("Modifier", edit_service_path(service))+"#{delete_button}</span></li>"
      if service.children.size > 0
        list << "<ul>"
        get_children(service.children,list)
        list << "</ul>"
      end
    end
    list
  end
  
end