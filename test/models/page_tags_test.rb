require 'test_helper'

class PageTagsTest < ActiveSupport::TestCase
  test 'sync_tag_list! создаёт теги и применяет их ко всей группе переводов' do
    ru = create_page(path: 'gruppa_ru')
    en = create_page(path: 'gruppa_en', lang: 'en', group_lang_id: ru.group_lang_id)

    ru.sync_tag_list!(['Молитва', 'Вера'])

    assert_equal ['Вера', 'Молитва'], ru.reload.tag_list
    assert_equal ['Вера', 'Молитва'], en.reload.tag_list
    assert_equal 2, Tag.count
  end

  test 'sync_tag_list! заменяет набор: снятые теги пропадают со всех переводов' do
    ru = create_page(path: 'gruppa2_ru')
    en = create_page(path: 'gruppa2_en', lang: 'en', group_lang_id: ru.group_lang_id)
    ru.sync_tag_list!(['Молитва', 'Вера'])

    ru.sync_tag_list!(['Вера'])

    assert_equal ['Вера'], ru.reload.tag_list
    assert_equal ['Вера'], en.reload.tag_list
    # сам тег остаётся в справочнике (управляется в админке тегов)
    assert Tag.exists?(name: 'Молитва')
  end

  test 'sync_tag_list! страницы без группы переводов трогает только её' do
    a = create_page(path: 'odinochkaya')
    b = create_page(path: 'odinochkaya2')

    a.sync_tag_list!(['Тег'])

    assert_equal ['Тег'], a.reload.tag_list
    assert_equal [], b.reload.tag_list
  end

  test 'sync_tag_list! чистит имена: повторы и пустые строки' do
    page = create_page(path: 'chistka')

    page.sync_tag_list!(['Молитва', ' Молитва ', '', '  '])

    assert_equal ['Молитва'], page.reload.tag_list
  end
end
