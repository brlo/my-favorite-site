require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test 'slug транслитерируется из русского имени' do
    assert_equal 'tainstvo-very', Tag.slug_from('Таинство веры')
    assert_equal 'vera', Tag.slug_from('ВЕРА')
    # из бессмысленного имени получается хоть какой-то адрес
    assert_equal 'tag', Tag.slug_from('!!!')
  end

  test 'при коллизии slug получает суффикс' do
    Tag.create!(name: 'Вера')
    other = Tag.create!(name: 'Vera')
    assert_equal 'vera-2', other.slug
  end

  test 'slug не меняется при переименовании тега' do
    tag = Tag.create!(name: 'Вера')
    tag.update!(name: 'Вера и надежда')
    assert_equal 'vera', tag.reload.slug
  end

  test 'name_for отдаёт перевод, иначе каноническое имя' do
    tag = Tag.create!(name: 'Вера', names: { 'en' => 'Faith', 'zh-Hans' => '' })
    assert_equal 'Faith', tag.name_for('en')
    # пустой перевод = фолбэк на каноническое имя
    assert_equal 'Вера', tag.name_for('zh-Hans')
    assert_equal 'Вера', tag.name_for('ja')
  end

  test 'find_or_create_by_name! нормализует имя и переиспользует существующий тег' do
    Tag.create!(name: 'Вера')
    found = Tag.find_or_create_by_name!("  Вера \n  ")
    assert_equal 1, Tag.count
    assert_equal found, Tag.find_by(name: 'Вера')

    Tag.find_or_create_by_name!('  Молитва ')
    assert_equal 'Молитва', Tag.find_by!(name: 'Молитва').name
  end
end
