require "test_helper"

class AddressConverterTest < ActiveSupport::TestCase
  test "addr_to_link converts internal address to url" do
    assert_equal '/zah/1/#L1', AddressConverter.addr_to_link('zah:1:1')
  end

  test "human_to_link handles verses, ranges and chapter only" do
    assert_equal '/in/3/#L16', AddressConverter.human_to_link('Ин. 3:16')
    assert_equal '/in/3/#L16,18-19', AddressConverter.human_to_link('Ин 3:16,18–19')
    assert_equal '/in/3/', AddressConverter.human_to_link('Ин. 3')
  end

  test "human_to_link returns nil for garbage and unknown books" do
    assert_nil AddressConverter.human_to_link('')
    assert_nil AddressConverter.human_to_link(nil)
    assert_nil AddressConverter.human_to_link('привет')
    assert_nil AddressConverter.human_to_link('Нет. 3:16')
  end

  test "book_bibleox_to_azbyka maps known codes only" do
    assert_equal 'Ex', AddressConverter.book_bibleox_to_azbyka('ish')
    assert_equal '1Cor', AddressConverter.book_bibleox_to_azbyka('1kor')
    assert_nil AddressConverter.book_bibleox_to_azbyka('unknown')
  end

  test "search_text_to_link accepts spaces instead of a colon and long dashes" do
    assert_equal '/gen/1/#L1', AddressConverter.search_text_to_link('Быт 1 1')
    assert_equal '/gen/1/#L1-3', AddressConverter.search_text_to_link('Быт. 1:1–3')
    assert_equal '/gen/1/#L1,3', AddressConverter.search_text_to_link('быт 1 1,3')
  end

  test "search_text_to_link returns nil for ordinary words" do
    assert_nil AddressConverter.search_text_to_link('любовь')
    assert_nil AddressConverter.search_text_to_link(nil)
  end
end
