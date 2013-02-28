module FirstRate
  module Util
    module_function

    def symbol_for_class clazz
      clazz.to_s.underscore.to_sym
    end

    def foreign_key_symbol_for_class clazz
      "#{clazz.to_s.underscore}_id".to_sym
    end

    def ensure_bson_id doc_or_id
      doc_or_id = doc_or_id.id if doc_or_id.kind_of?( Mongoid::Document )
      return doc_or_id.to_s
    end
  end
end