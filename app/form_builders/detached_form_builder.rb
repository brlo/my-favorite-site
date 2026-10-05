# Поля формы, стоящие вне тега <form>: каждому полю проставляется атрибут form="<id формы>".
# Нужен, когда между частями одной формы стоят другие формы (их нельзя вкладывать друг в друга).
#
#   <%= fields model: page, builder: DetachedFormBuilder, form_id: 'page-form' do |f| %>
class DetachedFormBuilder < ActionView::Helpers::FormBuilder
  %i[text_field text_area number_field email_field hidden_field].each do |helper|
    define_method(helper) do |method, options = {}|
      super(method, with_form(options))
    end
  end

  def check_box(method, options = {}, checked_value = '1', unchecked_value = '0')
    super(method, with_form(options), checked_value, unchecked_value)
  end

  def select(method, choices = nil, options = {}, html_options = {}, &)
    super(method, choices, options, with_form(html_options), &)
  end

  def submit(value = nil, options = {})
    super(value, with_form(options))
  end

  def form_id = @options[:form_id]

  private

  def with_form(options)
    { form: form_id }.merge(options)
  end
end
