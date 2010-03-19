# TODO: Write documentation and tests
module BusinessRules
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def business_rules
      @business_rules ||= {}
    end

    def define_business_rules_for(name, &block)
      self.class_eval { include InstanceMethods }

      business_rules[name] = block

      self.business_rules.keys.each do |method_id|
        method_name = method_id.to_s.gsub(/\?/,'')
        self.class_eval <<-CODE
          def #{method_name}(reload=false)
            @#{method_name} = nil if reload
            @#{method_name} ||= validate_business_rules(:"#{method_name}")
          end
          alias_method :"#{method_name}?", :"#{method_name}"
        CODE
      end
    end
  end

  module InstanceMethods
    attr_writer :business_rules_errors

    def business_rule(name, message = 'is invalid.', &block)
      begin
        returning yield do |value|
          unless value
            self.business_rules_errors[name] ||= []
            self.business_rules_errors[name] << message
          end
        end
      rescue Exception => e
        self.business_rules_errors[name] ||= []
        self.business_rules_errors[name] << message
      end
    end

    def business_rules_errors(reload = false)
      @business_rules_errors = nil if reload
      @business_rules_errors ||= {}
    end

  protected
    # This method accepts two parameters: a name for the type of business rules being validated (used for the business_rules_errors hash)
    # And a hash where the key is the object and the value is the method being called on the object.
    def validate_business_rules(rules_type)
      self.business_rules_errors = nil
      blk = self.class.business_rules[rules_type]
      self.instance_eval(&blk)

      self.business_rules_errors.empty?
    end
  end
end