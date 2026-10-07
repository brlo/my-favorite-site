# Кто может редактировать страницу
module Page::Permissions
  extend ActiveSupport::Concern

  # у статьи есть автор и редакторы
  # тут добавляем редактора
  def add_editor(_user)
    return self.editors.to_a if _user.id == self.user_id
    # добавляем user_id к текущему списку, если его там ещё нет,
    # а потом убираем от туда автора статьи (вдруг случайно попал)
    self.editors = (self.editors.to_a | [_user.id]) - [self.user_id]
  end

  # Хозяин страницы (users.pages_owner) может всё с ней и с её дочерними страницами
  def owned_by?(user)
    user.present? && (user.pages_owner.to_a & [id, parent_id].compact).any?
  end

  # Может ли пользователь редактировать статью (режим edit_mode)
  def editable_by?(user)
    return false if user.nil? || user.is_blocked
    return true if owned_by?(user)

    case edit_mode.to_i
    when Page::EDIT_MODES['admins']     then user.is_admin?
    when Page::EDIT_MODES['moderators'] then user.ability?('pages_update')
    else false # «автор и редакторы» пока никому не открыт
    end
  end
end
