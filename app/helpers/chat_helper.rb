module ChatHelper
  AVATAR_COLORS = %w[#b56576 #6d597a #355070 #2a9d8f #e76f51 #8a5a44 #4f772d #3d5a80].freeze

  def chat_avatar(member, size: :s)
    if member.avatar.present?
      url = size ? member.avatar.public_send(size).url : member.avatar.url
      image_tag(url, class: "chat-avatar#{' chat-avatar--large' unless size}", alt: '', loading: 'lazy')
    else
      color = AVATAR_COLORS[member.id % AVATAR_COLORS.size]
      content_tag(:span, member.nickname.to_s[0].to_s.upcase,
                  class: "chat-avatar chat-avatar--letter#{' chat-avatar--large' unless size}",
                  style: "background:#{color}")
    end
  end

  # Флажок по языку интерфейса + код языка (эмодзи-флаги не отображаются в Windows)
  def chat_flag(member)
    content_tag(:span, class: 'chat-flag', title: page_lang_string_full(member.ui_lang)) do
      safe_join([content_tag(:span, member.flag, class: 'chat-flag__emoji'),
                 content_tag(:span, member.ui_lang, class: 'chat-flag__code')])
    end
  end

  # Дата без I18n-форматов (time.formats есть не во всех локалях сайта)
  def chat_time(time, with_time: true)
    return '' if time.nil?

    content_tag(:time, time.strftime(with_time ? '%d.%m.%Y %H:%M' : '%d.%m.%Y'), datetime: time.iso8601)
  end

  # with_label: подпись сразу на сервере (для обычных страниц);
  # без неё подпись ставит JS (в сообщениях, которые рассылаются всем одинаковыми)
  def chat_role_badge(member, with_label: false)
    return unless member.staff? || member.bot?

    key = member.bot? ? 'bot' : (member.admin? ? 'admin' : 'moderator')
    content_tag(:span, with_label ? t("chat.js.role_#{key}") : '',
                class: "chat-badge chat-badge--#{key}", data: { i18n: "role_#{key}" })
  end

  # Словарь для JS: подписи в сообщениях подставляются на клиенте,
  # т.к. HTML сообщения рассылается всем одинаковым (без учёта языка зрителя)
  def chat_js_i18n
    keys = %w[reply edit delete approve translate show_original react pending direct deleted_message
              role_admin role_moderator role_bot edited confirm_delete wait send save cancel
              replying_to editing load_more translating reply_private_hint open_chat close_chat]
    keys.index_with { |k| t("chat.js.#{k}") }
  end
end
