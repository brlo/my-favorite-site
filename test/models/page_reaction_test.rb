require 'test_helper'

class PageReactionTest < ActiveSupport::TestCase
  test 'дайджест IP стабилен и не раскрывает адрес' do
    digest = PageReaction.digest_ip('10.0.6.1')

    assert_equal digest, PageReaction.digest_ip('10.0.6.1')
    assert_not_equal digest, PageReaction.digest_ip('10.0.6.2')
    assert_not_includes digest, '10.0.6.1'
    assert_equal 64, digest.length
  end

  test 'счётчики, виды и отметки собираются по статьям и IP' do
    one = create_page
    two = create_page
    PageReaction.create!(page: one, kind: 'like', ip_digest: PageReaction.digest_ip('10.0.6.1'))
    PageReaction.create!(page: one, kind: 'useful', ip_digest: PageReaction.digest_ip('10.0.6.2'))
    PageReaction.create!(page: two, kind: 'thanks', ip_digest: PageReaction.digest_ip('10.0.6.1'))

    assert_equal({'like' => 1, 'useful' => 1, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0},
                 PageReaction.counts_by_kind(one.id))
    assert_equal(
      {
        one.id => {'like' => 1, 'useful' => 1, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0},
        two.id => {'like' => 0, 'useful' => 0, 'thanks' => 1, 'interesting' => 0, 'hundred' => 0},
      },
      PageReaction.counts_for([one.id, two.id]),
    )
    assert_equal({one.id => 'like', two.id => 'thanks'}, PageReaction.kinds_for('10.0.6.1', [one.id, two.id]))
    assert_equal 'like', PageReaction.kind_for(one.id, '10.0.6.1')
    assert_nil PageReaction.kind_for(one.id, '10.0.6.3')
  end

  test 'у одной статьи и одного IP может быть только одна реакция' do
    page = create_page
    digest = PageReaction.digest_ip('10.0.6.1')
    PageReaction.create!(page: page, kind: 'like', ip_digest: digest)

    assert_raises(ActiveRecord::RecordInvalid) do
      PageReaction.create!(page: page, kind: 'useful', ip_digest: digest)
    end
  end
end
