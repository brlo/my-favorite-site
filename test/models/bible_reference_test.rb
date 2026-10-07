require "test_helper"

class BibleReferenceTest < ActiveSupport::TestCase
  test "digest_for ignores case, punctuation and spacing" do
    assert_equal BibleReference.digest_for('Бог — есть любовь!'), BibleReference.digest_for('бог есть  любовь')
    assert_not_equal BibleReference.digest_for('один'), BibleReference.digest_for('другой')
  end

  test "heat is 0 when there is no spread and stays within 0..1" do
    assert_equal 0.0, BibleReference.heat(3, 3, 3)
    assert_equal 0.0, BibleReference.heat(1, 1, 1)
    assert_equal 0.0, BibleReference.heat(1, 1, 10)
    hot = BibleReference.heat(10, 1, 10)
    assert_operator hot, :>, 0.9
    assert_operator hot, :<=, 1.0
  end

  test "heat grows with the number of mentions" do
    assert_operator BibleReference.heat(4, 1, 8), :>, BibleReference.heat(2, 1, 8)
  end

  test "uniq_by_digest keeps one record per snippet" do
    a = BibleReference.new(digest: 'x')
    b = BibleReference.new(digest: 'x')
    c = BibleReference.new(digest: 'y')
    assert_equal [a, c], BibleReference.uniq_by_digest([a, b, c])
  end
end
