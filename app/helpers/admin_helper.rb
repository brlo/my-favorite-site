module AdminHelper
  # Для древних языков нет локали интерфейса — открываем статью с близкой локалью
  LOCALE_FOR_ANCIENT_LANG = {
    'la' => 'it', 'grc' => 'el', 'frm' => 'fr', 'fro' => 'fr', 'cop' => 'en', 'cu' => 'ru', 'xcl' => 'ru',
  }.freeze

  PAGE_TYPE_OPTIONS = [
    ['Статья', 1],
    ['Список', 4],
    ['Комментарий к библ. стиху', 3],
    ['Книга с разбивкой на стихи', 5],
  ].freeze

  PAGE_TYPE_HINTS = {
    1 => 'Просто статья. Обычно это разбор какого-то понятия или одной темы.',
    3 => 'Апологетический разбор стиха Библии. В заголовке укажите только адрес стиха: Быт. 1:5 — тогда статья привяжется к стиху на сайте.',
    4 => 'Статья, к которой можно добавить меню из ссылок на другие статьи. Меню появится после сохранения статьи.',
    5 => 'Режим публикации небольших книг (например, древних писателей). Книга автоматически разобьётся на стихи.',
  }.freeze

  EDIT_MODE_OPTIONS = [
    ['Админы', 1],
    ['Модераторы', 2],
    ['Автор и редакторы', 3],
  ].freeze

  # адрес статьи на сайте
  def admin_public_page_path(page)
    lang = page.lang.to_s
    locale = I18n.available_locales.map(&:to_s).include?(lang) ? lang : LOCALE_FOR_ANCIENT_LANG.fetch(lang, 'ru')
    "/#{locale}/#{lang}/w/#{page.path}"
  end

  # Поле с подсказками (combobox_controller.js).
  # С label: в поле видно название (label), а в форму уходит value — скрытым полем (например, id родителя).
  # Без label: в поле само значение (например, path), подсказки только помогают его найти.
  def admin_combobox(name, value, url:, key:, label: nil, placeholder: nil, note: nil, min_length: 2, id: nil, form: nil)
    by_label = !label.nil?
    tag.div(class: 'combobox', data: { controller: 'combobox', combobox_url_value: url,
                                       combobox_key_value: key, combobox_min_length_value: min_length }) do
      safe_join([
        tag.input(type: 'text', id:, name: (name unless by_label), value: (by_label ? label : value), form:,
                  placeholder:, autocomplete: 'off', role: 'combobox',
                  data: { combobox_target: 'input',
                          action: 'input->combobox#search keydown->combobox#keydown blur->combobox#blur' }),
        (hidden_field_tag(name, value, id: nil, form:, data: { combobox_target: 'value' }) if by_label),
        (tag.button('×', type: 'button', class: 'combobox-clear', title: 'Очистить', data: { action: 'combobox#clear' }) if by_label),
        tag.ul(class: 'combobox-list', role: 'listbox', hidden: true, data: { combobox_target: 'list' }),
        (tag.div(note, class: 'hint', data: { combobox_target: 'note' }) if by_label),
      ].compact)
    end
  end

  def admin_page_picker(name, value, key: 'path', **opts)
    admin_combobox(name, value, url: admin_autocomplete_pages_path, key:,
                   placeholder: opts.delete(:placeholder) || 'Начните вводить название статьи', **opts)
  end

  # подпись для текущего родителя статьи
  def admin_parent_label(page)
    parent = page.parent_id.present? && ::Page.select(:id, :title, :path, :lang).find_by(id: page.parent_id)
    return ['', nil] unless parent

    ["#{flag_by_lang(parent.lang)} #{parent.title}", "#{parent.path} · ##{parent.id}"]
  end

  # подпись для группы переводов: другие статьи этой группы
  def admin_group_label(page)
    return ['', nil] if page.group_lang_id.blank?

    others = ::Page.where(group_lang_id: page.group_lang_id).where.not(id: page.id).limit(5).pluck(:lang, :title)
    label = others.any? ? others.map { |lang, title| "#{flag_by_lang(lang)} #{title}" }.join(', ') : 'Других переводов пока нет'
    [label, "ID группы: #{page.group_lang_id}"]
  end

  def admin_lang_options
    ::PAGE_LANGS.keys.map { [page_lang_string_full(_1, is_translate: true), _1] }
  end

  def admin_dict_options
    ::DictWord::DICTS.map { |code, d| [d['name'], code] }
  end

  def admin_page_badges(page)
    safe_join([
      (tag.i('удалена', class: 'badge red') if page.is_deleted),
      (tag.i('скрыта', class: 'badge') unless page.is_published),
    ].compact, ' ')
  end

  def admin_user_badges(user)
    safe_join([
      (tag.i('админ', class: 'badge blue') if user.is_admin),
      (tag.i('заблокирован', class: 'badge red') if user.is_blocked),
      (tag.i('вход заморожен', class: 'badge red') if user.lock_expires_at.present?),
      admin_activation_badge(user),
    ].compact, ' ')
  end

  def admin_activation_badge(user)
    return if user.email.blank?

    if user.activated?
      tag.i('почта ✓', class: 'badge green')
    else
      tag.i('почта не подтверждена', class: 'badge yellow')
    end
  end

  def admin_time(time)
    time ? l(time.in_time_zone, format: '%Y-%m-%d %H:%M') : '—'
  end
end
