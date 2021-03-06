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

      context "with neither a rating nor a review" do
        it "doesn't save a rating" do
          expect {
            @ratable.rate( nil )
          }.not_to change { @ratable.ratings.count }
        end
      end

      context "when not anonymous" do
        before {
          @rater = FactoryGirl.create( :rater )
        }

        context "the same item a second time" do
          context "when already reviewed" do
            before {
              @rating = @ratable.rate( 3, "Dis my review check it", @rater )
            }

            it "doesn't increase number of reviews" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.not_to change { @ratable.reviews_count }
            end

            it "updates original review" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @rating.reload
              }.to change { @rating.review }.to ( "Dis my updated review check it" )
            end

            it "won't update a review to nil" do
              expect {
                @ratable.rate( 2, nil, @rater )
                @rating.reload
              }.not_to change { @rating.review }
            end
          end

          context "when not already reviewed" do
            before {
              @rating = @ratable.rate( 3, nil, @rater )
            }

            it "increases number of reviews" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.to change { @ratable.reviews_count }.from( 0 ).to 1
            end
          end

          context "when already numerically rated" do
            before {
              @rating = @ratable.rate( 3, "Dis my review check it", @rater )
            }

            it "doesn't increase number of numeric ratings" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.not_to change { @ratable.numeric_ratings_count }
            end

            it "updates average to 2 instead of 3.5" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.to change { @ratable.average_rating }.to 2
            end

            it "won't update a review to nil" do
              expect {
                @ratable.rate( nil, "new review", @rater )
                @rating.reload
              }.not_to change { @rating.numeric_rating }
            end
          end

          context "when not already numerically rated" do
            before {
              @rating = @ratable.rate( nil, "Dis my review check it", @rater )
            }

            it "increases number of numeric ratings" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.to change { @ratable.numeric_ratings_count }.from( 0 ).to 1
            end

            it "sets average to 2" do
              expect {
                @ratable.rate( 2, "Dis my updated review check it", @rater )
                @ratable.reload
              }.to change { @ratable.average_rating }.from( nil ).to 2
            end
          end
        end

        context "when 2 reviewers of different subtypes" do
          before {
            @another_rater = FactoryGirl.create( :another_rater )
            @ratable.rate( 2, "foo", @rater )
            @ratable.rate( 4, "derp", @another_rater )

          }

          it "adds both to default list of raters" do
            @ratable.raters.count.should == 2
          end

          it "averages their numeric ratings" do
            @ratable.average_rating.should == 3
          end
        end

        it "changes #rated_by? to true for rater" do
          expect {
            @ratable.rate( 3, "Dis my review check it", @rater )
            @ratable.reload
          }.to change { @ratable.rated_by?( @rater ) }.to true
        end

        it "returns the correct rating given a rater" do
          @rating = @ratable.rate( 2, "foo", @rater )
          @ratable.rating_for( @rater ).should == @rating
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

          it "can identify its rater" do
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