# We should split these up into real model files at spec/models/*.rb and
# separate factory files.

class ReferencedRatableThing
  include Mongoid::Document
  include FirstRate::Ratable::Referenced
end

class EmbeddedRatableThing
  include Mongoid::Document
  include FirstRate::Ratable::Embedded
end

class User
  include Mongoid::Document
end

class User1 < User

end

class User2 < User

end


class NotARater
  include Mongoid::Document
end

FactoryGirl.define do 
  factory :embedded_ratable, :class => EmbeddedRatableThing
  factory :referenced_ratable, :class => ReferencedRatableThing
  factory :rater, :class => User1
  factory :another_rater, :class => User2
end
