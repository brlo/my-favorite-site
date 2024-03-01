class DiffService
  # не удалось применить diffs к page, отличаются данные в строках, подлежащих удалению
  class DiffApplyError < StandardError; end
  # Ошибка, которая указывает, что нельзя сделать merge, т.к. diff остал и нужно сделать rebase
  class NeedRebaseError < StandardError; end

  attr_reader :page, :mr

  def initialize merge_request, page
    @mr = merge_request
    @page = page
  end

  # При создании запроса, заполняем автоматически параметры сущности
  def fill_fields_on_new_merge_request page_params
    # запись новая должна быть, то есть в БД ещё не сохранена
    raise('MergeRequest is already persist') if mr.persisted?

    mr.page_id = page.id
    # исходная версия страницы
    mr.src_ver = page.merge_ver

    # новые параметры страницы из rails-контроллера
    new_attrs = page_params.stringify_keys
    # старые параметры страницы
    old_attrs = page.attributes_full_names()
    # изменённые параметры страницы
    changed_attrs = {}

    # названия полей, в которых желаем отслеживать изменения
    field_list = %w(
      page_type title title_sub path parent_id lang group_lang_id
      meta_desc redirect_from audio priority is_published edit_mode
    )

    # итак, какие поля изменились?
    field_list.each do |f|
      if new_attrs[f].to_s != old_attrs[f].to_s
        changed_attrs[f] = {
          # old будем записывать в момент применения патча: тот который будет.
          # конфликты в этих простых полях не будем решать.
          # 'old' => old_attrs[f],
          'new' => new_attrs[f],
        }
      end
    end

    # если изменившиеся поля есть, то сохраняем новые значения
    if changed_attrs.any?
      mr.attrs_diff = changed_attrs
    end

    # здесь будем хранить diffs каких-либо больших текстовых полей
    diffs = {}

    # body или references изменились? если да, то сохраняем только diffs
    %w(body references).each do |field_name|
      val_old = old_attrs[field_name]
      val_new = new_attrs[field_name]

      if val_old != val_new
        diffs[field_name] = build_diffs(
          text_old: val_old,
          text_new: val_new,
        )
      end
    end

    mr.diffs = diffs.compact

    mr.m_i = mr.diffs.sum { |f,data| data['m_i'].to_i }
    mr.p_i = mr.diffs.sum { |f,data| data['p_i'].to_i }

    mr
  end

  # =============================== MERGE =================================
  def merge
    raise('MR is closed') if mr.is_merged.to_i != 2
    raise('no page for merge') unless page

    if mr.src_ver != page.merge_ver
      raise NeedRebaseError.new('Сначала нужно сделать "Обновление" правок')
    end

    # применяем новые значения к изменившимся полям
    mr.attrs_diff&.each do |k,v|
      v['old'] = page.read_attribute(k)
      page.write_attribute(k, v['new'])
    end

    # --------- применяем diffs к тексту статьи -----------

    mr.diffs&.each do |field_name, diff_info|
      # патч
      # next if !diff_info.is_a?(Hash)
      diffs = diff_info&.fetch('diffs', nil)
      next if diffs.blank?

      # текст до патча
      init_text_as_arr = page.read_attribute(field_name)

      # применяем патч
      patched_text = apply_diffs_patch(init_text_as_arr, diffs)

      # сохраняем текст в page
      if patched_text
        page.write_attribute(field_name, patched_text.join)
      end
    end

    page.merge_ver = ::DateTime.now.utc.round

    # сохраняем page
    page.save!

    # указываем итоговую версию page
    mr.dst_ver = page.merge_ver
    mr.is_merged = 1
    mr.action_at = ::DateTime.now.utc.round
    mr.save!
  end

  # =============================== REBASE =================================
  # Задача: итеративно исправить текущий mr.diffs, поправив номера строк,
  # последовательно опираясь на все промежуточные diffs между этим и актуальной статьёй.
  def rebase
    raise('MR is closed') if mr.is_merged.to_i != 2
    raise('no page for rebase') unless page
    return if mr.src_ver == page.merge_ver

    mrs = ::MergeRequest.where(
      page_id: page.id,
      is_merged: 1,
      :dst_ver.gt => mr.src_ver,
    ).to_a

    mrs_index = mrs.index_by { |mr| mr.src_ver }

    # Выстраиваем чёткую цепочку от src_ver к dst_ver между всеми mrs,
    # начиная с текущего запроса src_ver, через добытую цепочку mrs, к page.merge_ver:
    # mr.src_ver -> mrs.dst_ver -> page.merge_ver
    mrs_chain = []

    # Итеративно обновляем diffs, поднимаемся к версии текста статьи.
    i = 0
    loop do
      # нашли next_mr (с нужным src_ver), который позволит нам
      # поднять наш mr до следующей версии текста (dst_ver)
      next_mr = mrs_index[mr.src_ver]

      if next_mr.nil?
        raise('Нет следующей версии патча, а до текущей версии статьи так и не добрались')
      end

      # применяем diffs, если есть,
      # а attrs_diffs мы не храним (там просто записываем что отправил пользователь)
      %w(body references).each do |field_name|
        old_diff_info = mr.diffs&.dig(field_name, 'diffs')
        next_diff_info = next_mr.diffs&.dig(field_name, 'diffs')
        lines_count_was = next_mr.diffs&.dig(field_name, 'lines_count_was')

        diffs_rebased = apply_rebase(
          diffs_old: old_diff_info,
          diffs_next: next_diff_info,
          lines_count_was: lines_count_was
        )

        if diffs_rebased.present?
          mr.diffs[field_name]['diffs'] = diffs_rebased
          # А эти параметры рядом с diffs, надо ли поправить?
          # lines_count_was
          # m_i
          # p_i
        end
      end

      # ок, мы поднялись на одну итерацию
      mr.src_ver = next_mr.dst_ver

      # и так пока не придём к версии статьи
      i += 1
      break if mr.src_ver == page.merge_ver
      raise('слишком много итераций (> 100) в процессе rebase') if i == 100
    end

    # Ура, теперь мы обновили наш mr.diffs и получили такой diffs,
    # который можно применить к текущему тексту статьи.
  end

  private

  # ПРИМЕНЕНИЕ СВЕЖЕГО DIFFS К АКТУАЛЬНОЙ СТАТЬЕ
  # Если mr.src_ver != page.merge_ver, то сначала требуем сделать rebase.
  #
  # Алгоритм diff-lsc устроен так, что сначала должны быть применены все минусы
  # не нарушая нумерации строк:
  # то есть при удалении одной строки, нумерация других строк не должна меняться.
  # И только потом мы применяем новую нумерацию и начинаем обрабатывать "плюсы",
  # то есть добавлять строки.
  def apply_diffs_patch init_text, diffs
    # диффсы, которые нужно применить
    return if diffs.blank?

    # текст в виде массива для применения патча: ['line1', 'line2', ...]
    init_text = ::Page.html_to_arr(init_text) || []

    # сюда будем складывать номера строк для удаления и добавления
    minuses = []
    pluses = []
    diffs.each do |group|
      group.each do |action, line_num, val|
        minuses << [line_num, val] if action == '-'
        pluses  << [line_num, val] if action == '+'
      end
    end

    # Сначала применяем все "минусы"
    minuses.each do |string_num, val|
      next if string_num == '?'
      if init_text[string_num] == val
        # строки для удаления (не удаляем сразу, а пока только зануляем, чтобы не нарушить нумерацию строк)
        init_text[string_num] = nil
      else
        raise(DiffApplyError.new('cant delete string, because its value is different'))
      end
    end

    # Только теперь можем выбросить все nil
    init_text = init_text.compact

    # применяем все "плюсы"
    pluses.each do |string_num, val|
      next if string_num == '?'
      init_text.insert(string_num, val)
    end

    # новый текст (патч применён)
    init_text
  end

  # Массив, в котором хранятся новые номера новых позиций старых строк (после применения патча)
  # искать так: arr[старый_номер_строки] => новый номер строки. Если будет nil, значит строка удалена.
  #
  # Или другими словами:
  # Нумерацию строк высчитываем для применения следующих патчей.
  #
  # Как по этому массиву определить где теперь находится старая строка?
  # Отправляем старый номер строки, получаем новый:
  # line_nums[old_num] => new_num
  # Вернётся либо новый номер этой строки, либо nil, что значит — исходная строка удалена.
  def calc_new_line_nums init_lines_count, diffs
    # текущий текст статьи
    raise if init_lines_count.blank?
    # диффсы, которые нужно применить
    raise if diffs.blank?

    # сюда будем складывать номера строк для удаления и добавления
    minuses = []
    pluses = []

    # Ради следующих патчей отслеживаем смещение нумерации строк.
    # для этого просто храним массив с номерами строк и применяем к этому массиву
    # все операции, которые применяем в тексту:
    # - если из текста удаляется строка — удаляем из массива строк этот же номер,
    # - если добавляется в текст — добавляем nil в ту же позицию в массиве строк
    # В итоге, у нас будет массив с оставшимися нетронутыми номерами строк,
    # и взяв индекс нужной нам строки мы сможем найти номер этой же строки в новом тексте.
    diffs.each do |group|
      group.each do |action, line_num, val|
        minuses << [line_num, val] if action == '-'
        pluses  << [line_num, val] if action == '+'
      end
    end

    # текущая нумерация строк: [1, 2, 3, ...]
    line_nums = (0..init_lines_count).to_a

    # Сначала применяем все "минусы"
    minuses.each do |string_num, val|
      # строки для удаления (не удаляем сразу, а пока только зануляем, чтобы не нарушить нумерацию строк)
      line_nums[string_num] = nil
    end

    # Только теперь можем выбросить все nil
    line_nums = line_nums.compact

    # применяем все "плюсы"
    pluses.each do |string_num, val|
      line_nums.insert(string_num, nil)
    end

    # новые номера старых строк
    line_nums
  end

  def build_diffs(text_old:, text_new:)
    result = {}

    old_t = ::Page.html_to_arr(text_old)
    new_t = ::Page.html_to_arr(text_new)
    diffs = ::Diff::LCS.diff(old_t, new_t)

    # считаем сколько строк удалили и добавили
    m_i = 0
    p_i = 0
    diffs.each do |group|
      group.each do |action,_,_|
        m_i += 1 if action == '-'
        p_i += 1 if action == '+'
      end
    end
    result['m_i'] = m_i
    result['p_i'] = p_i

    # в diffs лежат группы с изменениями, которые совершены близко друг к другу
    # [[группа-1], [гурппа-2], [гурппа-3]]
    # Мы их так группами и сохраняем, хотя можно было бы и отказаться.
    # Будем и показывать модератору группами. Так удобнее.
    result['diffs'] = diffs.map { |diff_group| diff_group.map(&:to_a) }

    # кол-во строк в старом тексте
    # (чтобы смогли потом на это кол-во как бы наложить патч и посчитать новые строки)
    result['lines_count_was'] = old_t.count

    result
  end

  def apply_rebase diffs_old:, diffs_next:, lines_count_was:
    return if diffs_old.blank?
    return if diffs_next.blank?
    return if lines_count_was.nil?
    # lines_count_was - новые номера строк

    # обращаясь по номеру элемента (индекса) получаем новый номер строки, куда вставлять +
    # например: нам надо было вставить строку на позицию 3, а она теперь после:
    # - вставки одной строки ДО, уехала на 4 место,
    # - удаления одной строки ДО, уехала на 2 место
    # - если меняли что-то ПОСЛЕ, то значения для этого действия не имеет.
    #
    # Поэтому мы ищем новое место для вставки строк в ту же (ОТНОСИТЕЛЬНО) позицию
    new_line_nums_for_plus_arr = calc_new_line_nums(lines_count_was, diffs_next)
    # а тут просто переворачиваем массив для плюсов, так как нам уже надо
    # искать наоборот: не по индексу, а по значению, то есть надо найти под
    # каким номером теперь находится старая строка
    new_line_nums_for_minus_hash = new_line_nums_for_plus_arr.map.with_index { |k,i| [k,i] }.to_h

    # САМОЕ ГЛАВНОЕ МЕСТО!
    # апдейтим номера строк в нашем mr
    diffs_rebased =
    diffs_old.map do |group|
      group.map do |action, line_num, val|
        # action - действие: +, -, ?
        # line_num - номер строки
        # val - данные, над которыми пользователь совершил операцию (строка)
        #
        # Так обозначаются потерявшиеся в процессе rebase строки.
        # Храним их, так как это текст какого-то автора. Вдруг он для него ценен.
        next if line_num == '?'
        # новая позиция старой строки
        new_num = new_line_nums_for_minus_hash[line_num]

        # ЕСЛИ новое место старой строки не нашли, то:
        # - действие "минус": игнор с небольшой пометкой
        # - действие "плюс": попытка засунуть в ближайшую после line_num строку
        if new_num.nil?
          # соответствующей строки нет — значит её тоже удалили в этом коммите, как и мы в своём коммите,
          # а значит игнорируем
          if action == '-'
            # добавим пометку для этой строки, чтобы если будет попытка что-то сюда вставить
            # то мы понимали, что это была попытка зменить одну строку на другую (исправить)
            new_line_nums_for_minus_hash[line_num] = 'CANCEL-'
            # делать ничего не надо с этой строкой, так как её уже удалили
            next

          # соответствующей строки нет - добавляем в ближайшую известную строку
          elsif action == '+'
            neares_next_line_num = nil
            new_line_nums_for_minus_hash.keys.each do |i|
              # TODO: ТУТ ЕЩЁ СТОИТ КОНКРЕТНО ВСЮ ЛОГИКУ ПРОВЕРИТЬ, ВСЁ ПРОДУМАТЬ. Ещё иногда возникают проблемы: падения при обновлении.
              #
              # i встречаются иногда nil, как я понимаю сейчас, это значит что этой строки пока нет
              # в оригинальном документе, мы её собираемся добавить. Такие строки будут здесь видны как nil,
              # их просто пропускаем.
              next if i.nil?

              # номер строки (i) больше того, который мы не смогли найти в этом хэше (line_num)
              # и значение является номером строки (а не CANCEL-)
              if i > line_num && (nl = new_line_nums_for_minus_hash[i]).is_a?(Integer)
                neares_next_line_num = nl
                break
              end
            end

            new_num = neares_next_line_num

            # если ближайшая строка по какой-то причине так и не была найдена, то вставим в конец
            # правда нужно помнить, что каждый раз последняя строка будет удаляться на 1, а поэтому
            # надо править массив со строками
            if new_num.nil?
              # новые строки-плюсы помечены в этом массиве как nil, поэтому
              # так как мы хотим добавить строку в конец, то в конце и вставляем nil
              new_line_nums_for_plus_arr << nil
              # а потом берём общее число строк -- то есть номер последней строки.
              # Каждый раз попытка добавить строку в конец файла, будем добавлять её сначала,
              # допустим, в строку номер 100, а в следующий раз, это будет уже номер 101, 102 и тд
              new_num = new_line_nums_for_plus_arr.count
            end

            new_num
          end

        # пропускаем, т.к. эта строка удалялась в группе ранее, а это мы сейчас в плюс попали.
        # для этого мы и ставили эту метку, чтобы потом пропустить плюс
        elsif new_num == 'CANCEL-'
          new_line_nums_for_minus_hash.delete(line_num)
          new_num = '?'
        end

        [action, new_num, val]
      end.compact
    end.select(&:presence)

    diffs_rebased
  end
end
