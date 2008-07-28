def init(yaml, config, path)
  
  # Load every file in the app directory
  controller_path = File.join(path, 'app', 'controllers')
  $LOAD_PATH << controller_path
  Dependencies.load_paths << controller_path
  config.controller_paths << controller_path
  model_path = File.join(path, 'app', 'models')
  $LOAD_PATH << model_path
  Dependencies.load_paths << model_path
  config.controller_paths << model_path
  ActionController::Base.append_view_path(path + '/app/views/')
  $LOAD_PATH << File.join(path, 'app', 'helpers')
  

  # These variables store the feature's configuration from his config.yml file 
  name = yaml['name']
  version = yaml['version']
  dependencies = yaml['dependencies']
  conflicts = yaml['conflicts']
  business_objects = yaml['business_objects']
  pages = yaml['pages']

  # This array store all pages in order than they will be displayed
  $page_table = []
   
  feature = Feature.find_or_create_by_name_and_version(name, version)

  #Test of dependencies for this feature
  dependencies_hash = []
  unless dependencies.nil?
    dependencies.each_pair do |key,value|
      dependencies_hash << {:name => key, :version => value}
    end
  end
  feature.dependencies = dependencies_hash
  feature.save

  #Test of conflicts for this feature
  conflicts_hash = []
  unless conflicts.nil?
    conflicts.each_pair do |key,value|
      conflicts_hash << {:name => key, :version => value}
    end
  end
  feature.conflicts = conflicts_hash
  feature.save
  
  #Test of business Objects
  business_objects_array =  []
  unless business_objects.nil?
    business_objects.each do |business_object|
      business_objects_array << [business_object]
    end
    feature.business_objects = business_objects_array
    feature.save
  end

  roles_count = Role.count
  #Test if all permission for all business objects are present
  unless business_objects.nil?
    business_objects.each do |bo|
      unless BusinessObjectPermission.find_all_by_has_permission_type(bo).size == roles_count
        Role.find(:all).each do |role|
          BusinessObjectPermission.find_or_create_by_has_permission_type_and_role_id(bo, role.id)
        end
      end  
    end
  end

  #Test if all permission for all pages are present
  def pages_permisisons_verification(pages)
    roles_count = Role.count
    pages.each_pair do |key,value|
      p = Page.find_by_name(key)
      unless p.nil?
        unless PagePermission.find_all_by_page_id(p.id).size == roles_count
          Role.find(:all).each do |role|
            if PagePermission.find_by_page_id_and_role_id(p.id, role.id).nil?
              PagePermission.create(:page_id => p.id,:role_id =>role.id)
            end
          end
        end
      end
      unless value['children'].nil?
        pages_permisisons_verification(value['children'])
      end
    end
  end

  pages_permisisons_verification(pages)


  # This method insert in $page_table all feature's pages
  def page_insertion(pages,parent_name)
    pages.each_pair do |key,value|
      $page_table << {  :name => key, :title_link => value["title_link"], :description_link => value["description_link"], :url => value["url"], :parent => parent_name}
      unless value["children"].nil?
        page_insertion(value["children"], key)
      end
    end
  end

  page_insertion(pages,"")
  

  # This block insert into Database the pages that wasn't present 
  $page_table.each do |page|
    parent_page = Page.find_by_name(page[:parent])
    unless Page.find_by_name(page[:name])
      if parent_page.nil?
        Page.create(:title_link =>page[:title_link], :description_link => page[:description_link], :url => page[:url], :name => page[:name])
      else
        Page.create(:title_link =>page[:title_link], :description_link => page[:description_link], :url => page[:url], :name => page[:name], :parent_id =>parent_page.id )
      end
    end
  end
end