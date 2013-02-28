module FirstRate
  module Ratable
    def self.included( base )
      base.field :ratings, type: Integer, default: 0      
      base.field :rating_total, type: Integer, default: 0
      base.field :average_rating, type: Float
    end
    
    def rate! rating, rater = nil, options = {}
      inc( :ratings, 1 )
      inc( :rating_total, rating )
      set( :average_rating, self.rating_total.to_f / self.ratings )
      check_type_is_rater( rater && rater.class )
      rater.did_rate( self, rating ) if rater
    end

    def rated_by type = nil
      type ||= Rating.default_ratable_type()
      return [] unless type
      check_type_is_rater( type )
      type.having_rated( self )
    end

    def check_type_is_rater type
      if type && !type.ancestors.include?( FirstRate::Rater )
        raise ArgumentError, "The model #{type.to_s} must include FirstRate::Rater"
      end
    end
  end
end
