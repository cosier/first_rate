module FirstRate
  module Rater
    def self.included base
      base.embeds_many :ratings_lists, :class_name => "::FirstRate::RatingsList", :inverse_of => RatingsList.symbol_for_class( base )
      base.scope :having_rated, ->( doc ) { base.where( :"ratings_lists.rated_ids" => doc.id.to_s ) }
      RatingsList.create_inverse_relationship( base )
    end

    def did_rate doc
      ratings_list = self.ratings_lists.by_class( doc.class ).first || self.ratings_lists.create!( rated_type: doc.class.to_s )
      ratings_list.add_to_set( :rated_ids, doc.id.to_s )
    end

    def has_rated? doc_or_id
      ratings_list = self.ratings_lists.having_rated( doc_or_id ).first
      return !ratings_list.nil?
    end

    def items_rated type = nil
      ratings_list = type.nil? ? self.ratings_lists.first : self.ratings_lists.by_class( type ).first
      return [] unless ratings_list
      return ratings_list.items
    end
  end

  class RatingsList
    include Mongoid::Document

    field :rated_type, type: String
    field :rated_ids, type: Array, default: []

    scope :by_class, ->( clazz ) { where( :rated_type => clazz.to_s ) }
    scope :having_rated, ->( doc_or_id ) {
      doc_or_id = doc_or_id.id if doc_or_id.kind_of?( Mongoid::Document )
      doc_or_id = doc_or_id.to_s
      where( :"rated_ids" => doc_or_id )
    }

    @embedded_in_types = []

    class << self
      attr_accessor :embedded_in_types

      def create_inverse_relationship clazz
        @embedded_in_types << clazz
        self.embedded_in symbol_for_class( clazz ), :class_name => clazz.to_s, :inverse_of => :ratings_lists
      end

      def symbol_for_class clazz
        clazz.to_s.gsub( /(.)([A-Z])/, '\\1_\\2' ).downcase.to_sym
      end

      def default_ratable_type
        @embedded_in_types.first
      end
    end

    def rater
      self.class.embedded_in_types.each do |clazz|
        rater = self.send( self.class.symbol_for_class( clazz ) )
        return rater unless rater.nil?
      end
      return nil
    end

    def items
      doc_class.where( :_id.in => self.rated_ids )
    end

    def doc_class
      Kernel.const_get( self.rated_type )
    end
  end
end
