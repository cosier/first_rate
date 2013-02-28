require 'spec_helper'

describe FirstRate::Reviewable do

  # Ahh, ruby
  block = Proc.new do
    context "when reviewing" do
      it "increases the number of reviews from 0 to 1" do
        expect {
          @reviewable.review( "Dis my review check it" )
        }.to change { @reviewable.reviews.count }.from( 0 ).to 1
      end

      describe "the review" do
        before {
          @review = @reviewable.review( "Dis my review check it" )
        }

        it "saves the review text" do
          @review.text.should == "Dis my review check it"
        end

        it "can identify its item" do
          @review.item.should == @reviewable
        end
      end
    end
  end

  describe "(embedded)" do
    before {
      @reviewable = FactoryGirl.create( :embedded_reviewable )
    }

    context &block
  end

  describe "(reference)" do
    before {
      @reviewable = FactoryGirl.create( :referenced_reviewable )
    }

    context &block
  end
end
