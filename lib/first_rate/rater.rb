module FirstRate
  module Rater
    def self.included base
      base.embeds_many :ratings, :class_name => "::FirstRate::Rating", :inverse_of => Rating.symbol_for_class( base )
      base.scope :having_rated, ->( doc ) { base.where( :"ratings.item_id" => doc.id.to_s ) }
      Rating.create_inverse_relationship( base )
    end

    def did_rate doc, value
      self.ratings.create!( value: value, item_id: doc.id.to_s, item_class: doc.class.to_s )
    end

    def has_rated? doc_or_id
      !self.ratings.by_item_id( ensure_bson_id( doc_or_id ) ).empty?
    end

    def items_rated type = nil
      return [] if self.ratings.count == 0
      type ||= Kernel.const_get( self.ratings.first.item_class )
      item_ids = self.ratings.by_class( type ).collect do |rating|
        rating.item_id
      end
      type.where( :_id.in => item_ids )
    end

    def rating_for doc_or_id
      self.ratings.by_item_id( ensure_bson_id( doc_or_id ) ).first
    end

    def ensure_bson_id doc_or_id
      doc_or_id = doc_or_id.id if doc_or_id.kind_of?( Mongoid::Document )
      return doc_or_id.to_s
    end
  end

  class Rating
    include Mongoid::Document

    field :value, type: Integer
    field :item_id, type: String
    field :item_class, type: String

    scope :by_class, ->( clazz ) { where( :item_class => clazz.to_s ) }
    scope :by_item_id, ->( item_id ) { where( :item_id => item_id ) }

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
