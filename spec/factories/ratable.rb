# We should split these up into real model files at spec/models/*.rb and
# separate factory files.

class RatableThing
  include Mongoid::Document
  include FirstRate::Ratable
end

class AnotherRatableThing
  include Mongoid::Document
  include FirstRate::Ratable
end

class User
  include Mongoid::Document
  include FirstRate::Rater
end

class Admin
  include Mongoid::Document
  include FirstRate::Rater
end

class NonRater
  include Mongoid::Document
end

FactoryGirl.define do 
  factory :ratable, :class => RatableThing
  factory :rater, :class => User
  factory :admin_rater, :class => Admin
  factory :bad_rater, :class => NonRater
end
