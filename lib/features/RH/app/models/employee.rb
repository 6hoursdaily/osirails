class Employee < ActiveRecord::Base
  acts_as_file
  
  # Relationships
# TODO Add a role to the user when create an employee => for permissions 

  belongs_to :family_situation
  belongs_to :civility
  has_one :address, :as => :has_address
  has_one :iban, :as => :has_iban
  has_one :job_contract
  has_one :user
  has_many :numbers, :as => :has_number
  has_many :premia
  has_many :employees_services
  has_many :services, :through => :employees_services
  has_and_belongs_to_many :jobs
  
  # Validates
  validates_presence_of :last_name, :first_name, :message => "ne peut être vide"
  validates_format_of :social_security, :with => /^([0-9]{13}\x20[0-9]{2})*$/,:message => "format numéro de sécurité social incorrect"
  validates_format_of :email, :with => /^(\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,5})+)*$/,:message => "format adresse email incorrect"
  validates_format_of :society_email, :with => /^(\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,5})+)*$/,:message => "format adresse email incorrect"
  
  # Callbacks
  after_create :user_create_methode
  before_save :case_managment
  
  # Method to change the case of the fisrt_name and the last_name at the employee's creation
  def case_managment
    self.first_name.capitalize!
    self.last_name.upcase!
  end
  
  def pattern(val,obj)
    retour = ""
    open = 0 
    # verify if opened [ are closed with ]
    
    return "pattern invalide : <br/>- Vous devez fermer les []!!" unless val.count("[") == val.count("]")
    
    (0..val.size).each do |i|
      return "pattern invalide : <br/>- Vous ne devez pas utiliser "+'#'+'{}' if val[i..i+1] == '#{'
      return "pattern invalide : <br/>- Vous ne devez pas utiliser |" if val[i..i] == "|"
      unless open == 2
        open += 1 if val[i..i] == "[" 
        open -= 1 if val[i..i] == "]"
      else
        return "pattern invalide : <br/>- Vous devez fermer le premier [] avant d'ouvrir le second"
      end
    end
    
    val = val.gsub(/\[/,"|")
    val = val.gsub(/\]/,"|")
    val = val.split("|")
    
    for i in (1...val.size) do
      if(i%2==0)
        retour += val[i]       
      else
        tmp = val[i].split(",")
        # verify if opt is an integer
        if tmp.size>2
           return "pattern invalide : <br/>- trop de virgules dans le pattern, une seule au maximum pour ajouter une Option"
        elsif tmp.size>1
          tmp[1].size > 15 ? option = tmp[1][0..15] + "..." : option = tmp[1]
          if /^([0-9]){0,15}$/.match(tmp[1].to_s).nil?
            return "pattern invalide : <br/>- Option [ " + option + " ] invalide "
          end
          # return "pattern invalide : <br/>- Option [ " + option + " ] invalide " if /^([0-9]){0,15}$/.match(tmp[1].to_s).nil?
        end
        unless tmp[0].blank?
          txt = tmp[0].downcase
          # verify if attr is valid
          if obj.respond_to?(txt)  
            if tmp.size==2
              for j in (1...tmp.size)             
                  if tmp[0]==tmp[0].upcase
                    tmp[0].downcase!
                    txt = obj.send(tmp[0])[0...tmp[1].to_i]
                    retour += txt.upcase
                  else
                    txt = obj.send(tmp[0])[0...tmp[1].to_i].gsub(/\x20/,"_")
                    retour += txt.downcase
                  end 
              end 
            else
              if obj.respond_to?(val[i])
                tmp = val[i].downcase 
              else
                return "pattern invalide : <br/>- Attribut [" + val[i] + "] invalide : vous ne devez utiliser la virgule que l'Option "
              end
              txt = obj.send(tmp).gsub(/\x20/,"_")
              if val[i] == val[i].upcase
                retour += txt.upcase
              else
                retour += txt.downcase
              end
            end
          else
             return "pattern invalide : <br/>- Attribut ["+ tmp[0] +"] invalide"
          end
        else
          return "pattern invalide : <br/>- Vous devez ajouter au minimum l'Attribut dans les [] "  
        end  
      end
    end
      return retour.to_s
  end
  
   
  
  def manager(service_id)
    EmployeesService.find(:all,:conditions => ["service_id=? ,responsable=?", service_id, true])
    manager = Employee.find(tmp.employee_id)
    return manager
  end
  
  def fullname
    "#{self.first_name} #{self.last_name}"
  end
  
  def user_create_methode
    User.create(:username => pattern(ConfigurationManager.admin_user_pattern,self), :password =>"P@ssw0rd",:employee_id => self.id)
    JobContract.create(:start_date => "", :end_date => "", :employee_id => self.id, :employee_state_id => "",:job_contract_type_id => "" )  
  end 
  
  def responsable?(service_id)
    tmp = EmployeesService.find(:all,:conditions => ["service_id=? and responsable=?",service_id,1 ])
    manager = []
    tmp.each do |t|
      e = Employee.find(t.employee_id)
      manager << e.id
    end
    return manager
  end
  
  def format_text(line_length,text)
    t_end = text.size
    line_end = 0
    formated_text=""
      while line_end < t_end
        formated_text+=text[line_end..line_end + line_length]+ "\n"
        
        line_end += line_length
      end
    formated_text  
  end
  
end
