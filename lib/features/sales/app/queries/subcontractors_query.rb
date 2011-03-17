require 'lib/features/thirds/app/queries/thirds_query'

module SubcontractorsQuery
  include ThirdsQuery
  
  alias_method :query_td_for_name_in_subcontractor, :query_td_for_name_in_third # original method in thirds > thirds_query
  alias_method :query_td_for_legal_form_name_in_subcontractor, :query_td_for_legal_form_name_in_third # original method in thirds > thirds_query
  alias_method :query_td_for_activity_sector_reference_get_activity_sector_name_in_subcontractor,
               :query_td_for_activity_sector_reference_get_activity_sector_name_in_third # original method in thirds > suppliers_query
               
end