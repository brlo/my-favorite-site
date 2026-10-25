require "test_helper"

class MybibleImporterTest < ActiveSupport::TestCase
  test "removes footnotes and service numbers, keeps italics and the words of Christ" do
    orig = '<pb/>अब्राहम <f>[1†]</f> की सन्तान, दाऊद की सन्तान <f>[2†]</f> , <J>यीशु</J> <i>मसीह</i>।'
    assert_equal 'अब्राहम की सन्तान, दाऊद की सन्तान, <j>यीशु</j> <i>मसीह</i>।', MybibleImporter.clean(orig)
  end

  test "drops poetry line markers and verse numbers inside psalms" do
    orig = '<pb/><e>दाऊद का भजन</e> <pb/><t> <n>[1]</n> यहोवा मेरा चरवाहा है, मुझे कुछ </t><t>घटी न होगी। </t>'
    assert_equal 'दाऊद का भजन यहोवा मेरा चरवाहा है, मुझे कुछ घटी न होगी।', MybibleImporter.clean(orig)
  end

  test "does not insert spaces between Chinese words when removing name marks" do
    assert_equal '亚巴郎之子，达味之子耶稣基督的族谱：', MybibleImporter.clean('<e>亚巴郎</e>之子，<e>达味</e>之子<e>耶稣基督</e>的族谱：')
  end

  test "removes Korean inline note marks and the notes at the end of the verse" do
    orig = '그리고 거기에 노아나 ㄱ) 다넬이나 욥 같은 사람이 있다고 하자. (ㄱ. 혹은 다니엘)'
    assert_equal '그리고 거기에 노아나 다넬이나 욥 같은 사람이 있다고 하자.', MybibleImporter.clean(orig)
  end

  test "removes a Korean heading whose opening tag is lost and note marks after quotes" do
    orig = '광야에 나타난 요한;막1:1-8]</n> 그 무렵에 "ㄱ) 내가 내 아들을 불러 내었다"고 하신 말씀'
    assert_equal '그 무렵에 "내가 내 아들을 불러 내었다"고 하신 말씀', MybibleImporter.clean(orig)
  end
end
