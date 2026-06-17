# UserTruncateService.new(User.last.id).truncate!
class UserTruncateService
  def initialize user_id
    @user = User.find(user_id)
  end

  def truncate!
    puts "Удаление данных пользователя #{@user.name} (#{@user.username})"
    puts
    # puts '=== Блокируем пользователя'
    # @user.update!(is_blocked: true)
    # p ' => Готово!'

    puts
    puts '=== Удаляем переводы пользователя'
    @user.translations.destroy_all
    p ' => Готово!'

    puts
    puts '=== Удаляем реакции пользователя'
    @user.translation_reactions.destroy_all
    p ' => Готово!'

    puts "Работа выполнена."
  end
end
