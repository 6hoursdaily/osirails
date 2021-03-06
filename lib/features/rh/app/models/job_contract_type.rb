class JobContractType < ActiveRecord::Base
  validates_presence_of :name
  validates_inclusion_of :limited, :in => [true, false]
  
  has_search_index :only_attributes => [:limited, :name]
end
