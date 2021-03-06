module ValidatesTimeliness

  def self.enable_multiparameter_attributes_extension!
    ::ActiveRecord::Base.send(:include, ValidatesTimeliness::ActiveRecord::MultiparameterAttributes)
  end

  module ActiveRecord
    module MultiparameterAttributes
      
      def self.included(base)
        base.alias_method_chain :execute_callstack_for_multiparameter_attributes, :timeliness
      end    
    
      # Overrides AR method to store multiparameter time and dates as string
      # allowing validation later.
      def execute_callstack_for_multiparameter_attributes_with_timeliness(callstack)
        errors = []
        callstack.each do |name, values|
          column = column_for_attribute(name)
          if column && [:date, :time, :datetime].include?(column.type)
            begin
              callstack.delete(name)
              if values.empty?
                send("#{name}=", nil)
              else
                value = time_array_to_string(values, column.type)
                send("#{name}=", value)
              end
            rescue => ex
              errors << ::ActiveRecord::AttributeAssignmentError.new("error on assignment #{values.inspect} to #{name}", ex, name)
            end
          end
        end
        unless errors.empty?
          raise ::ActiveRecord::MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
        end
        execute_callstack_for_multiparameter_attributes_without_timeliness(callstack)
      end
      
      def time_array_to_string(values, type)
        values.collect! {|v| v.to_s }
                
        case type
        when :date
          extract_date_from_multiparameter_attributes(values)
        when :time
          extract_time_from_multiparameter_attributes(values)
        when :datetime
          date_values, time_values = values.slice!(0, 3), values
          extract_date_from_multiparameter_attributes(date_values) + " " + extract_time_from_multiparameter_attributes(time_values)
        end
      end   
         
      def extract_date_from_multiparameter_attributes(values)
        [values[0], *values.slice(1, 2).map { |s| s.rjust(2, "0") }].join("-")
      end
      
      def extract_time_from_multiparameter_attributes(values)
        values = values.size > 3 ? values[3..5] : values
        values.map { |s| s.rjust(2, "0") }.join(":")
      end
      
    end

  end
end
