# TODO: Write documentation
module BusinessRules
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_eval { include InstanceMethods }
  end

  module ClassMethods
    def define_business_rules_for(name, &block)
      @business_rules ||= {}
      @business_rules[name] = block
    end

    def business_rules
      @business_rules
    end
  end

  module InstanceMethods
    attr_writer :business_rules_errors

    def business_rule(name, message = 'is invalid.', &block)
      returning yield do |value|
        unless value
          self.business_rules_errors[name] ||= []
          self.business_rules_errors[name] << message
        end
      end
    end

    def business_rules_errors(reload = false)
      @business_rules_errors = nil if reload
      @business_rules_errors ||= {}
    end

    def method_missing(method_id, *args)
      begin
        super
      rescue
        method_name = method_id.to_s.gsub(/\?/,'')
        if self.class.business_rules.key?(method_name.to_sym)
          self.instance_eval <<-CODE
            def #{method_name}
              @#{method_name} ||= validate_business_rules(:"#{method_name}")
            end
          CODE
          self.instance_eval(method_name)
        else
          super
        end
      end
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