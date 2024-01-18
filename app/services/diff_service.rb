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

    # исходная версия страницы
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
      meta_desc redirect_from audio priority is_published
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

    # а body изменился? если да, то сохраняем только diffs
    if new_attrs['body'] != old_attrs['body']
      body_old = ::Page.html_to_arr(old_attrs['body'])
      body_new = ::Page.html_to_arr(new_attrs['body'])
      diffs = ::Diff::LCS.diff(body_old, body_new)
      # считаем сколько строк удалили и добавили
      _minus_i = 0
      _plus_i = 0
      diffs.each do |group|
        group.each do |action,_,_|
          _minus_i += 1 if action == '-'
          _plus_i += 1 if action == '+'
        end
      end
      mr.minus_i = _minus_i
      mr.plus_i = _plus_i

      # в diffs лежат группы с изменениями, которые совершены близко друг к другу
      # [[группа-1], [гурппа-2], [гурппа-3]]
      # Мы их так группами и сохраняем, хотя можно было бы и отказаться.
      # Будем и показывать модератору группами. Так удобнее.
      mr.text_diffs = diffs.map { |diff_group| diff_group.map(&:to_a) }

      # кол-во строк в старом тексте
      # (чтобы смогли потом на это кол-во как бы наложить патч и посчитать новые строки)
      mr.lines_count = body_old.count
    end
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

    # текст в виде массива для применения патча: ['line1', 'line2', ...]
    init_text_as_arr = page.body_as_arr()

    # применяем diffs к тексту статьи
    patched_text = apply_diffs_patch(init_text_as_arr, mr.text_diffs)
    if patched_text
      page.body = patched_text.join
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
  # Задача: итеративно исправить текущий mr.text_diffs, поправив номера строк,
  # последовательно опираясь на все промежуточные text_diffs между этим и актуальной статьёй.
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

      # применяем diffs, если есть, а attrs_diffs мы не храним (там просто записываем что отправил пользователь)
      if next_mr.text_diffs.present?
        # новые номера строк
        max_lines_count = mr.lines_count
        line_nums_arr = calc_new_line_nums(max_lines_count, next_mr.text_diffs)

        # САМОЕ ГЛАВНОЕ МЕСТО!
        # апдейтим номера строк в нашем mr
        mr.text_diffs =
        mr.text_diffs.map do |group|

          group.map do |action, line_num, val|
            # Так обозначаются потерявшиеся в процессе rebase строки.
            # Храним их, так как это текст какого-то автора. Вдруг он для него ценен.
            next if line_num == '?'
            # новая позиция старой строки
            new_num = line_nums_arr[line_num]
            # ЕСЛИ новое место старой строки не нашли, то:
            # - действие "минус"
            # - действие "плюс"
            if new_num.nil?
              # соответствующей строки нет — поэтому ничего не удаляем. Нельзя удалять что попало.
              if action == '-'
                # но тогда удалённую линию нужно вернуть в массив с номерами строк,
                # так как выходит, что мы её не удалили
                line_nums_arr.insert(line_num, 'CANCEL-')
                # возможно произошла замена неизвестной строки, а значит мы пропускаем и МИНУС и ПЛЮС (далее)
                new_num = '?'
              # соответствующей строки нет - поведение ветвится:
              # - пропускаем, если эта строка уже удалялась в группе ранее;
              # - добавляем в ближайшую известную строку, если это новая строка, а не замена.
              elsif action == '+'
                line_num
                # начинаем со следующего элемента, т.к. line_num уже проверили
                first = line_num + 1
                last = line_nums_arr.count - 1
                neares_line_num = (first..last).find { |i| line_nums_arr[i].present? }
                new_num = neares_line_num || last
              end
            elsif new_num == 'CANCEL-'
              line_nums_arr.delete_at(line_num)
              new_num = '?'
            end

            [action, new_num, val]
          end.compact
        end.select(&:presence)
      end

      # ок, мы поднялись на одну итерацию
      mr.src_ver = next_mr.dst_ver

      # и так пока не придём к верси статьи
      i += 1
      break if mr.src_ver == page.merge_ver
      raise('слишком много итераций (> 100) в процессе rebase') if i == 100
    end

    # Ура, теперь мы обновили наш mr.text_diffs и получили такой diffs,
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
    # текущий текст статьи
    return if init_text.blank?
    # диффсы, которые нужно применить
    return if diffs.blank?

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
    # для этого просто храним массив с нумерами строк и применяем к этому массиву
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
end
