require 'spec_helper'

describe FirstRate::Ratable do
  before {
    @ratable = FactoryGirl.create( :ratable )
  }
  
  context "when rating a 4 as the first rating" do
    it "increases the number of ratings from 0 to 1" do
      expect {
        @ratable.rate!( 4 )
        @ratable.reload
      }.to change { @ratable.ratings }.from( 0 ).to 1
    end      
    
    it "sets the average rating from nil to first rating" do
      expect {
        @ratable.rate!( 4 )
        @ratable.reload
      }.to change { @ratable.average_rating }.from( nil ).to( 4.0 )
    end    
    
    context "then a 2 as the second rating" do
      before {
        @ratable.rate!( 4 )        
      }
      
      it "changes the average rating from 4 to 3" do
        expect {
          @ratable.rate!( 2 )
        }.to change { @ratable.average_rating }.from( 4.0 ).to 3.0
      end
    end
  end  
  
  context "when rating non-anonymously" do
    before {
      @rater = FactoryGirl.create( :rater )
    }

    context "when rater is not a FirstRate::Rater" do
      before { 
        @rater = FactoryGirl.create( :bad_rater )
      }
      
      it "throws an ArgumentError" do
        expect {
          @ratable.rate!( 2, @rater )
        }.to raise_error ArgumentError
      end      
    end

    context "for the second time" do
      before {
        @ratable.rate!( 2, @rater )
      }

      context "uniquely" do
        it "doesn't increase the number of ratings" do
          expect {
            @ratable.rate!( 4, @rater )
            @ratable.reload
          }.not_to change { @ratable.ratings }
        end

        it "changes the average rating to 4" do
          expect {
            @ratable.rate!( 4, @rater )
            @ratable.reload
          }.to change { @ratable.average_rating }.from( 2 ).to 4
        end
      end

      context "non-uniquely" do
        it "doesn't increase the number of ratings to 2" do
          expect {
            @ratable.rate!( 4, @rater, unique: false )
            @ratable.reload
          }.not_to change { @ratable.ratings }
        end

        it "changes the average rating to 3" do
          expect {
            @ratable.rate!( 4, @rater, unique: false )
            @ratable.reload
          }.to change { @ratable.average_rating }.from( 2 ).to 3
        end
      end
    end

    describe "the list of raters" do
      context "for this item" do
        it "adds the new rater" do
          expect {
            @ratable.rate!( 2, @rater )
            @ratable.reload
          }.to change { @ratable.rated_by.first }.from( nil ).to @rater
        end

        context "for this specific rater model class" do
          it "adds the new rater" do
            expect {
              @ratable.rate!( 2, @rater )
              @ratable.reload
            }.to change { @ratable.rated_by( @rater.class ).first }.from( nil ).to @rater
          end
        end

        context "for another model class" do
          it "doesn't add the rater" do
            expect {
              @ratable.rate!( 2, @rater )
              @ratable.reload
            }.not_to change { @ratable.rated_by( Admin ).first }
          end
        end
      end

      context "for another item" do
        before {
          @another_item = FactoryGirl.create( :ratable )
        }

        it "doesn't add the rater" do
          expect {
            @ratable.rate!( 2, @rater )
            @ratable.reload
          }.not_to change { @another_item.rated_by.first }
        end
      end
    end

    describe "the list of items rated" do
      context "for this rater" do
        it "changes #has_rated? to true" do
          expect {
            @ratable.rate!( 2, @rater )
            @rater.reload
          }.to change { @rater.has_rated?( @ratable ) }.to true
        end

        it "adds the item" do
          expect {
            @ratable.rate!( 2, @rater )
            @rater.reload
          }.to change { @rater.items_rated.first}.from( nil ).to @ratable
        end

        context "for this specific model class" do
          it "adds the item" do
            expect {
              @ratable.rate!( 2, @rater )
              @rater.reload
            }.to change { @rater.items_rated( @ratable.class ).first}.from( nil ).to @ratable
          end
        end

        context "for another model class" do
          it "doesn't add the item" do
            expect {
              @ratable.rate!( 2, @rater )
              @rater.reload
            }.not_to change { @rater.items_rated( AnotherRatableThing ).first }
          end
        end
      end

      context "for another rater" do
        before {
          @another_rater = FactoryGirl.create( :rater )
        }

        it "doesn't change #has_rated?" do
          expect {
            @ratable.rate!( 2, @rater )
            @rater.reload
          }.not_to change { @another_rater.has_rated?( @ratable ) }
        end
      end
    end
  end
end