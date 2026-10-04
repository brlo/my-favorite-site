require "test_helper"

class Chat::RichTextTest < ActiveSupport::TestCase
  def doc(*content) = { 'type' => 'doc', 'content' => content }
  def para(*inline) = { 'type' => 'paragraph', 'content' => inline }
  def text(t, *marks) = { 'type' => 'text', 'text' => t, 'marks' => marks }

  test "escapes html and keeps allowed marks" do
    r = Chat::RichText.new(doc(para(text('<b>x</b>', { 'type' => 'bold' }, { 'type' => 'italic' }))), allow_links: false).call
    assert_equal '<p><strong>&lt;b&gt;x&lt;/b&gt;</strong></p>', r.html
  end

  test "links only when allowed and only http(s)" do
    link = ->(href) { doc(para(text('a', { 'type' => 'link', 'attrs' => { 'href' => href } }))) }
    refute_includes Chat::RichText.new(link.('https://x.org'), allow_links: false).call.html, '<a'
    assert_includes Chat::RichText.new(link.('https://x.org'), allow_links: true).call.html, 'href="https://x.org"'
    refute_includes Chat::RichText.new(link.('javascript:alert(1)'), allow_links: true).call.html, '<a'
  end

  test "flattens nested quotes and unknown nodes" do
    nested = { 'type' => 'blockquote', 'content' => [{ 'type' => 'blockquote', 'content' => [para(text('q'))] }] }
    heading = { 'type' => 'heading', 'content' => [text('h')] }
    r = Chat::RichText.new(doc(nested, heading), allow_links: false).call
    assert_equal '<blockquote><p>q</p></blockquote><p>h</p>', r.html
  end

  test "rejects empty and too long" do
    assert_raises(Chat::RichText::Invalid) { Chat::RichText.new(doc(para), allow_links: false).call }
    long = doc(para(text('x' * (Chat::MAX_TEXT_LENGTH + 1))))
    assert_raises(Chat::RichText::Invalid) { Chat::RichText.new(long, allow_links: false).call }
  end
end
