module FirstRate
  module Util
    module_function

    def symbol_for_class clazz
      clazz.to_s.underscore
    end
  end
end