module Rudder
  class Report
    # @@Technique@@Type@@RuleId@@DirectiveId@@VersionId@@Component@@Key@@ExecutionTimeStamp##NodeId@#HumanReadableMessage
    def initialize(report)
      unless /(.*)@@(?<technique>.*)@@(?<type>.*)@@(?<ruleId>.*)@@(?<directiveId>.*)@@(?<versionId>.*)@@(?<component>.*)@@(?<key>.*)@@(?<timeStamp>.*)##(?<nodeId>.*)@#(?<message>.*)/i =~ report
        raise "Given report was unparsable"
      end
      @technique = technique
      @type = type
      @ruleId = ruleId
      @directiveId = directiveId
      @versionId = versionId
      @component = component
      @key = key
      @timeStamp = timeStamp
      @nodeId = nodeId
      @message = message
    end

    attr_reader :technique
    attr_reader :type
    attr_reader :ruleId
    attr_reader :directiveId
    attr_reader :versionId
    attr_reader :component
    attr_reader :key
    attr_reader :timeStamp
    attr_reader :nodeId
    attr_reader :message

    def ==(other)
      if self.class == other.class
        equal = true
        self.instance_variables.map.each do |attribute|
          a = self.instance_variable_get attribute
          b = other.instance_variable_get attribute
          unless a == "*" or b == "*"
            equal = equal && (a == b)
          end
        end
        equal
      else
       false
      end
    end
  end
end
