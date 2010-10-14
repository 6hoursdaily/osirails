require File.dirname(__FILE__) + '/../rh_test'

class FamilySituationTest < ActiveSupport::TestCase
  should_journalize :identifier_method => :name

  def setup
    @family_situation = family_situations(:single)
  end
  
  def test_presence_of_name
    assert_no_difference 'FamilySituation.count' do
      family_situation = FamilySituation.create
      assert_not_nil family_situation.errors.on(:name), "A FamilySituation should have a name"
    end
  end
  
  def test_uniqness_of_name
    assert_no_difference 'FamilySituation.count' do
      family_situation = FamilySituation.create(:name => @family_situation.name)
      assert_not_nil family_situation.errors.on(:name), "A FamilySituation should have an uniq name"
    end
  end
end
