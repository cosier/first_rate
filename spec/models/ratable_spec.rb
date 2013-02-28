require 'spec_helper'

describe FirstRate::Ratable do
  # Ahh, ruby
  block = Proc.new do
    context "when rating" do
      context "including a review" do
        it "saves a rating" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
          }.to change { @ratable.ratings.count }.from( 0 ).to 1
        end

        it "increases the number of numeric ratings from 0 to 1" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.numeric_ratings_count }.from( 0 ).to 1
        end

        it "sets average rating to 3" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.average_rating }.from( nil ).to 3
        end

        it "increases number of reviews from 0 to 1" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.reviews_count }.from( 0 ).to 1
        end

        it "saves review text" do
          @ratable.rate( 3, "Dis da review check it" ).review.should == "Dis da review check it"
        end
      end

      context "with just a review" do
        it "saves a rating" do
          expect {
            @ratable.rate( nil, "Dis da review check it" )
          }.to change { @ratable.ratings.count }.from( 0 ).to 1
        end

        it "doesn't increase the number of numeric ratings" do
          expect {
            @ratable.rate( nil, "Dis da review check it" )
            @ratable.reload
          }.not_to change { @ratable.numeric_ratings_count }
        end

        it "doesn't change average rating" do
          expect {
            @ratable.rate( nil, "Dis da review check it" )
            @ratable.reload
          }.not_to change { @ratable.average_rating }
        end

        it "increases number of reviews from 0 to 1" do
          expect {
            @ratable.rate( nil, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.reviews_count }.from( 0 ).to 1
        end

        it "saves review text" do
          @ratable.rate( nil, "Dis da review check it" ).review.should == "Dis da review check it"
        end
      end

      context "with an empty review" do
        it "doesn't save a rating" do
          expect {
            @ratable.rate( 2, "" )
          }.not_to change { @ratable.ratings.count }
        end

        it "doesn't increase number of numeric ratings" do
          expect {
            @ratable.rate( 2, "" )
            @ratable.reload
          }.not_to change { @ratable.numeric_ratings_count }
        end

        it "doesn't increase number of reviews" do
          expect {
            @ratable.rate( 2, "" )
            @ratable.reload
          }.not_to change { @ratable.reviews_count }
        end

        context "using #rate! (bang) " do
          it "should raise a validation error" do
            expect {
              @ratable.rate!( 2, "" )
            }.to raise_error Mongoid::Errors::Validations
          end
        end
      end

      context "with no review" do
        it "saves a rating" do
          expect {
            @ratable.rate( 3 )
          }.to change { @ratable.ratings.count }.from( 0 ).to 1
        end

        it "increases the number of numeric ratings from 0 to 1" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.numeric_ratings_count }.from( 0 ).to 1
        end

        it "sets average rating to 3" do
          expect {
            @ratable.rate( 3, "Dis da review check it" )
            @ratable.reload
          }.to change { @ratable.average_rating }.from( nil ).to 3
        end
      end


      context "when not anonymous" do
        before {
          @rater = FactoryGirl.create( :rater )
        }

        context "the same item a second time" do
          before {
            @rating = @ratable.rate( 3, "Dis my review check it", @rater )
          }

          it "doesn't increase number of reviews" do
            expect {
              @ratable.rate( 2, "Dis my updated review check it", @rater )
              @ratable.reload
            }.not_to change { @ratable.reviews_count }
          end

          it "doesn't increase number of numeric ratings" do
            expect {
              @ratable.rate( 2, "Dis my updated review check it", @rater )
              @ratable.reload
            }.not_to change { @ratable.numeric_ratings_count }
          end

          it "updates original review" do
            expect {
              @ratable.rate( 2, "Dis my updated review check it", @rater )
              @rating.reload
            }.to change { @rating.review }.to ( "Dis my updated review check it" )
          end
        end

        it "changes #rated_by? to true for reviewer" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @ratable.reload
          }.to change { @ratable.rated_by?( @rater ) }.to true
        end

        it "adds rater to list of raters" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @ratable.reload
          }.to change { @ratable.raters.first }.from( nil ).to( @rater )
        end

        it "adds rater to list of raters of that type" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @ratable.reload
          }.to change { @ratable.raters( @rater.class ).first }.from( nil ).to( @rater )
        end

        it "doesn't add rater to list of raters of some other type" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @ratable.reload
          }.not_to change { @ratable.raters( NotARater ).first }
        end

        it "adds rating to rater's list" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @rater.reload
          }.to change { @ratable.class.rated_by( @rater ).first }.from( nil ).to( @ratable )
        end

        describe "the rating" do
          before {
            @rating = @ratable.rate( 2, "Dis my review check it", @rater )
          }

          it "can identify its reviewer" do
            @rating.rater.should == @rater
          end
        end
      end
    end
  end

  describe "(embedded)" do
    before {
      @ratable = FactoryGirl.create( :embedded_ratable )
    }

    context &block
  end

  describe "(reference)" do
    before {
      @ratable = FactoryGirl.create( :referenced_ratable )
    }

    context &block
  end
end