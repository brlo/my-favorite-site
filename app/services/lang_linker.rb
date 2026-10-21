# Связывает уже существующие страницы на разных языках (переключение языка, как в Википедии):
# страница вступает в языковую группу целевой страницы вместе со всей своей группой, кроме страниц на языке цели.
#
#   LangLinker.call({ 'en-path' => 'ru-path' }) -> [сообщения]
#
# Если в группе цели уже есть страница на том же языке и её не переносят этим же списком - пару пропускаем.
class LangLinker
  def self.call(pairs, is_dry_run: false) = new(pairs, is_dry_run:).perform

  def initialize(pairs, is_dry_run: false)
    @pairs = pairs
    @is_dry_run = is_dry_run
  end

  def perform
    log = []
    moves = {} # id страницы -> новый group_lang_id
    src_paths = @pairs.keys.map { _1.to_s.downcase }

    @pairs.each do |src_path, dst_path|
      src = ::Page.find_by(path_low: src_path.to_s.downcase)
      dst = ::Page.find_by(path_low: dst_path.to_s.downcase)
      next log << "нет страницы: #{src ? dst_path : src_path}" unless src && dst
      next log << "уже связаны: #{src_path}" if src.group_lang_id == dst.group_lang_id

      members = ::Page.where(group_lang_id: src.group_lang_id).where.not(lang: dst.lang).to_a
      busy = ::Page.where(group_lang_id: dst.group_lang_id, lang: members.map(&:lang)).to_a
                   .reject { src_paths.include?(_1.path_low) }
      next log << "пропуск #{src_path}: в группе #{dst_path} уже есть #{busy.map { "#{_1.lang}:#{_1.path}" }.join(', ')}" if busy.any?

      members.each { moves[_1.id] = dst.group_lang_id }
      log << "#{members.map { "#{_1.lang}:#{_1.path}" }.join(', ')} -> группа #{dst.lang}:#{dst_path}"
    end

    apply(moves) unless @is_dry_run
    log
  end

  private

  def apply(moves)
    ::Page.transaction do
      moves.each { |id, group| ::Page.where(id: id).update_all(group_lang_id: group, updated_at: ::Time.current) }
    end
  end
end
