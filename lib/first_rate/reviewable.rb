module FirstRate
  module Reviewable
    def self.included base
      base.send( :include, Embedded )
    end

    module Embedded
      def self.included base
        base.embeds_many :reviews, :class_name => "::FirstRate::Reviewable::EmbeddedReview", :inverse_of => FirstRate::Util.symbol_for_class( base )
        EmbeddedReview.create_inverse_relationship( base )
        base.send( :include,  InstanceMethods )
      end
    end

    module Referenced
      def self.included base
        base.has_many :reviews, :class_name => "::FirstRate::Reviewable::ReferencedReview", :inverse_of => FirstRate::Util.symbol_for_class( base )
        ReferencedReview.create_inverse_relationship( base )
        base.send( :include,  InstanceMethods )
      end
    end

    module InstanceMethods
      def review text, byline = nil
        self.reviews.create( text: text )
      end
    end

    class Review
      include Mongoid::Document

      field :text, type: String

      validates_presence_of :text

      def item
        self.class.parent_types.each do |type|
          result = self.send( FirstRate::Util.symbol_for_class( type ) )
          return result if result
        end
        return nil
      end
    end

    class EmbeddedReview < Review
      @parent_types = []

      class << self
        attr_accessor :parent_types

        def create_inverse_relationship base
          @parent_types << base
          embedded_in FirstRate::Util.symbol_for_class( base ), :class_name => base.to_s, :inverse_of => :reviews
        end
      end
    end

    class ReferencedReview < Review
      store_in collection: "reviews"

      @parent_types = []

      class << self
        attr_accessor :parent_types

        def create_inverse_relationship base
          @parent_types << base
          belongs_to FirstRate::Util.symbol_for_class( base ), :class_name => base.to_s, :inverse_of => :reviews
        end
      end
    end
  end
end