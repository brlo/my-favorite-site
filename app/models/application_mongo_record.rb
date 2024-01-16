class ApplicationMongoRecord
  def updated_at_word
    time = self.updated_at
    diff_sec = Time.now - time

    if diff_sec < 3.minute.to_i
      'Сейчас'
    elsif diff_sec < 60.minutes.to_i
      min = (diff_sec / (60)).to_i
      "#{min} мин. назад"
    elsif diff_sec < 24.hours.to_i
      h = (diff_sec / (60*60)).to_i
      "#{h} ч. назад"
    elsif diff_sec < 30.days.to_i
      d = (diff_sec / (60*60*24)).to_i
      "#{d} д. назад"
    else
      time.strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  # Атрибуты объекта с полными именами (attributes возвращает с сокращёнными именами)
  def attributes_full_names
    # Получаем хэш с алиасами для класса Person
    alias__key = self.aliased_fields
    # {
    #   "id"            => "_id",
    #   "page_type"     => "pt",
    #   "is_published"  => "is_pub",
    #   "title_sub"     => "ts",
    #   "meta_desc"     => "meta",
    #   "parent_id"     => "p_id",
    #   "redirect_from" => "r_from",
    #   "audio"         => "au",
    #   "lang"          => "lg",
    #   "group_lang_id" => "gli",
    #   "body"          => "bd",
    #   "verses"        => "vrs",
    #   "references"    => "rfs",
    #   "priority"      => "prior",
    #   "created_at"    => "c_at",
    #   "updated_at"    => "u_at"
    # }
    key__alias = alias__key.invert

    # => {"first_name"=>"fn", "last_name"=>"ln"}
    # Создаем новый хэш с полными именами ключей
    full_names = {}
    # Перебираем все пары ключ-значение в атрибутах объекта
    self.attributes.each do |key, value|
      # Если ключ есть в алиасах, то используем алиас вместо ключа
      if key__alias.has_key?(key)
        # Находим алиас по значению
        _alias = key__alias[key]
        # Добавляем пару алиас-значение в новый хэш
        full_names[_alias] = value
      else
        # Иначе используем ключ без изменений
        full_names[key] = value
      end
    end

    # full_names
    # => {"_id"=>BSON::ObjectId('60a4d0b9f0f9f7c5b7f9f7c6'), "first_name"=>"Alice", "last_name"=>"Smith"}
    full_names
  end

  private

  def sanitizer
    @sanitizer ||= ::Rails::Html::SafeListSanitizer.new
  end
end
