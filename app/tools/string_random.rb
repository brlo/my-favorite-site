module StringRandom
  # ::StringRandom.get(16)

  CHARS = [*('a'..'z'),*('A'..'Z'),*('0'..'9')].freeze
  CHARS_COUNT = CHARS.size

  def self.get size = 16
    # # для уникальности имён в пределах кластера используется индекс-номер ноды
    # # пока заглуша - 01
    # NODE_ID.to_s + CHARS.shuffle[0,size].join # было раньше, но здесь символы не повторяются, что уменьшает число комбинаций
    s = ''; size.times{ s << CHARS[ rand(CHARS_COUNT) ] }; s
  end
end
