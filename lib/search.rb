class Search

  include Permissible
  
  # method to group sub attributes
  
  def self.group(array)
  grouped = []
  tmp = {}
  array.each do |elmnt|
    if elmnt.size==1
      grouped << elmnt 
    else
      tmp[elmnt[0]] = [] if tmp[elmnt[0]].nil?
      tmp[elmnt[0]] << elmnt 
    end 
  end
  tmp.each_pair do |key,value|
    value.each do |elmnt|
    grouped << elmnt
    end
  end
  return grouped
end
  
  
  # method to generate an array containing the result array headers ( in the view )
  
  def self.search_result_headers(hash, parent)
    columns ||= []
    hash.each_pair do |attribute,type|
      if type.class == Hash
        attribute.camelize = attribute ? columns = columns.fusion(search_result_headers(type,attribute)) : columns = columns.fusion(search_result_headers(type))
      else
        parent != model ? columns << [parent, attribute]  : columns << attribute 
      end
    end  
    return columns
  end  
  
  # methode that return in an array the hiearchie of keys into recursives hashes and put a "_" in front of the attribute 
  # hash = an array containing all attributes
  # attribute = the attribute that you want the hierarchy  
 
  def self.get_attribute_hierarchy(hash,attribute,parent,model)
    hash.each_pair do |key,element|
      tab = []
      if element.class == Hash
        tab = get_attribute_hierarchy(element,attribute,parent,key)
        tab = tab.fusion([key]) unless key.camelize == key

  # replace the identificator '_' by '#' to pass the recursive return sequence
 
        tab[tab.index(tab.last)] = "#"+attribute if tab.include?("_"+attribute) and parent == key
        return tab if tab.include?("#"+attribute)
      elsif key==attribute and parent==model
        return ["_"+key]  
      end
    end
    return []
  end
  
  ####################################################
  ### methods to get the :include hash in the find ###
  
  #def self.get_include_hash(hash)
  #  result_values = []
  #  hash.each_pair do |model,categories|
  #    categories.each_value do |attributes|
  #      result_values = sub_resources(attributes) unless sub_resources(attributes).nil?
  #    end
  #  end
  #  return result_values
  #end
  
  def self.get_include_hash(categories)
    result_values = []
    categories.each_value do |attributes|
      if attributes.class == Hash
      puts attributes.inspect
        result_values = sub_resources(attributes) unless sub_resources(attributes).nil?
      end   
    end
    return result_values
  end
  
  # recursive methode used by get_incude_hash
  def self.sub_resources(attributes)
    sub_resources_array = []
    attributes.each_pair do |attribute,contents|
      if contents.class == Hash
        contents.each_value do |value|
          sub_resources(value).nil? ? sub_resources_array << attribute.to_sym : sub_resources_array << {attribute.to_sym => sub_resources(value)}  
        end
      end
    end
    sub_resources_array==[] ?  nil : sub_resources_array
  end
  
  ##################################################### 
  
  ##################################################### 
  ### methods to get conditions array ################# 
   
  def self.get_conditions_array(criteria_hash,model,search_type) 
    conditions_array ||= [""]
    criteria_hash.each_value do |criterion|
      if search_type == "and"
        conditions_array[0].blank? ? group="" : group = " and "
      elsif search_type == "or"
        conditions_array[0].blank? ? group="" : group = " or "
      elsif search_type == "not"
        conditions_array[0].blank? ? group="" : group = " and "
        criterion['action'] = negative(criterion['action'])
      else
        group = ""
      end  
      # criterion['parent']==model ? parent = " " : parent = criterion['parent'].tableize + "."
      parent = criterion['parent'].tableize + "."
      unless criterion['value'].nil?
      
        if criterion['value'].split(" ").size>1
          conditions_array[0] += "("
          tmp = {}
          
          criterion['value'].split(" ").each do |value|
            # if the comparison sign is negative there's more results with 'and', that 'or'
            if criterion['action'] == "not like" or criterion['action'] == "!="
              tmp == {} ? tmp_group = "" : tmp_group = " and "
            else
              tmp == {} ? tmp_group = "" : tmp_group = " or "
            end
            conditions_array[0] += tmp_group + parent + criterion['attribute'].split(",")[0] + " " + criterion['action'] + "?" unless criterion['attribute'].nil? or criterion['action'].nil?
            tmp['attribute'] = criterion['attribute']
            tmp['value'] = value
            conditions_array << format_value(tmp)
          end
          
          conditions_array[0]+= ")"
        else
          conditions_array[0] += group + parent + criterion['attribute'].split(",")[0] + " " + criterion['action'] + "?" unless criterion['attribute'].nil? or criterion['action'].nil?
          conditions_array << format_value(criterion)
        end  
        
      else
        conditions_array[0] += group + parent + criterion['attribute'].split(",")[0] + " " + criterion['action'] + "?" unless criterion['attribute'].nil? or criterion['action'].nil?
        conditions_array << format_value(criterion)    
      end
    end 

    return conditions_array
  end
  
  # method to get the negative form of the comparators ex =! for =
  def self.negative(action)
    positive = ["=",">","<",">=","<=","like"]
    negative = ["!=","<=",">=","<",">","not like"]
    return negative[positive.index(action)] if positive.include?(action)
    return positive[negative.index(action)] if negative.include?(action)
  end
  
  # method to format the criterion's value
  def self.format_value(params)
    case params['attribute'].split(",")[1]
      when 'date'
        m= params['date(2i)'] 
        d= params['date(3i)'] 
        y= params['date(1i)'] 
        result = "#{y}/#{m}/#{d}"
      when 'number'
        result =params['value'].to_d unless params['value'].nil?
      when 'boolean'
        result = params['value']  
      else
        result = "%" + params['value'].strip + "%" unless params['value'].nil?
    end
    return result
  end
  
  #####################################################
end
