ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Генерация превью-картинок (RMagick) пишет файлы в public/ — в тестах она не нужна
ImgTextWrap.singleton_class.prepend(Module.new { def page_generate_img(_page) = nil })

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Пользователь с подтверждённой почтой; overrides перекрывают значения по умолчанию
  def create_user(overrides = {})
    @user_seq = (@user_seq || 0) + 1
    attrs = {
      name: "Test User #{@user_seq}", username: "test_user_#{@user_seq}_#{SecureRandom.hex(3)}",
      email: "user#{@user_seq}_#{SecureRandom.hex(3)}@example.com",
      password: 'secret123', password_confirmation: 'secret123',
    }.merge(overrides)
    user = User.create!(attrs)
    user.update_columns(activation_state: 'active') unless overrides.key?(:activation_state)
    user
  end

  # Страница; overrides перекрывают значения по умолчанию
  def create_page(overrides = {})
    @page_seq = (@page_seq || 0) + 1
    Page.create!({
      title: "Страница #{@page_seq}", lang: 'ru', path: "page_#{@page_seq}_#{SecureRandom.hex(3)}", page_type: 1,
    }.merge(overrides))
  end
end
