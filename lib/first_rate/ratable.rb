require 'mongo'

module FirstRate
  module Ratable

    def self.included base
      base.send( :include, Embedded )
    end

    module Embedded
      def self.included base
        base.embeds_many :ratings, :class_name => "::FirstRate::Ratable::EmbeddedRating", :inverse_of => FirstRate::Util.symbol_for_class( base )
        EmbeddedRating.create_inverse_relationship( base )
        base.send( :include,  InstanceMethods )
        base.scope :rated_by, ->( rater ) { base.where( :'ratings.rater_id' => Util.ensure_bson_id( rater ) ) }
        base.index :'ratings.rater_id' => Mongo::ASCENDING
      end
    end

    module Referenced
      extend ActiveSupport::Concern

      def self.included base
        base.has_many :ratings, :class_name => "::FirstRate::Ratable::ReferencedRating", :inverse_of => FirstRate::Util.symbol_for_class( base )
        ReferencedRating.create_inverse_relationship( base )
        base.send( :include,  ::FirstRate::Ratable::InstanceMethods )
      end

      module ClassMethods
        def rated_by rater
          id_sym = FirstRate::Util.foreign_key_symbol_for_class( self )
          ids = ReferencedRating.by_rater( rater ).collect { |rating| rating.send( id_sym) }
          self.where( :_id.in => ids )
        end
      end
    end

    module InstanceMethods

      def self.included base
        base.field :average_rating, type: Float
        base.field :reviews_count, type: Integer, default: 0
        base.field :numeric_ratings_count, type: Integer, default: 0
        base.field :numeric_ratings_basis, type: Integer, default: 0
      end

      def rate! *args
        rating = self.rate( *args )
        if rating.new_record?
          rating.save!
        end
        return rating
      end

      def rate numeric_rating, review = nil, rater = nil, options = {}
        rating = self.ratings.by_rater( rater ).first if rater
        rating ||= self.ratings.build(
          rater_id: (rater && rater.id.to_s),
          rater_type: (rater && rater.class.name)
        )
        rating.review = review  if review
        unless numeric_rating.nil?
          if rating.valid?
            if rating.new_record? || rating.numeric_rating.nil?
              self.inc( :numeric_ratings_count, 1 )
              self.inc( :numeric_ratings_basis, numeric_rating )
            else
              self.inc( :numeric_ratings_basis, numeric_rating - rating.numeric_rating )
            end
            self.set( :average_rating, self.numeric_ratings_basis / self.numeric_ratings_count )
          end
          rating.numeric_rating = numeric_rating
        end
        if !review.nil? && (rating.new_record? || rating.review.nil? ) && rating.valid?
          self.inc( :reviews_count, 1 )
        end
        rating.save
        return rating
      end

      def raters type = nil
        rater_ids = []
        self.ratings.each do |rating|
          type ||= rating.rater_supertype_const
          if rating.rater_supertype_const && rating.rater_supertype_const == type
            rater_ids << rating.rater_id.to_s
          end
        end
        return [] if type.nil?
        return type.where( :_id.in => rater_ids )
      end

      def rated_by? rater
        !self.ratings.by_rater( rater ).empty?
      end
    end

    class Rating
      include Mongoid::Document

      field :rater_id, type: String
      field :rater_type, type: String
      field :numeric_rating, type: Integer
      field :review, type: String

      scope :by_rater, ->( rater ) { where( :rater_id => Util.ensure_bson_id( rater ) ) }

      validates_presence_of :review, :if => ->( ) { !self.review.nil? }

      def item
        self.class.parent_types.each do |type|
          result = self.send( FirstRate::Util.symbol_for_class( type ) )
          return result if result
        end
        return nil
      end

      def rater
        return nil unless self.rater_id
        self.rater_supertype_const.find( self.rater_id )
      end

      def rater_supertype_const
        return nil unless self.rater_type
        specific_class = self.rater_type.constantize
        while specific_class.superclass.ancestors.include?( Mongoid::Document )
          specific_class = specific_class.superclass
        end
        return specific_class
      end
    end

    class EmbeddedRating < Rating
      @parent_types = []

      class << self
        attr_accessor :parent_types

        def create_inverse_relationship base
          @parent_types << base
          embedded_in FirstRate::Util.symbol_for_class( base ), :class_name => base.to_s, :inverse_of => :ratings
        end
      end
    end

    class ReferencedRating < Rating
      store_in collection: "ratings"

      @parent_types = []

      class << self
        attr_accessor :parent_types

        def create_inverse_relationship base
          @parent_types << base
          belongs_to FirstRate::Util.symbol_for_class( base ), :class_name => base.to_s, :inverse_of => :ratings
        end
      end
    end
  end
end