class ItemWithEmbeddedReviews
  include Mongoid::Document
  include FirstRate::Reviewable::Embedded
end

class ItemWithReferencedReviews
  include Mongoid::Document
  include FirstRate::Reviewable::Referenced
end



FactoryGirl.define do
  factory :embedded_reviewable, :class => ItemWithEmbeddedReviews
  factory :referenced_reviewable, :class => ItemWithReferencedReviews
end