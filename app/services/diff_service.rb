class DiffService
  def initialize(text1, text2)
    @text1 = text1.to_s
    @text2 = text2.to_s
  end

  def diff
    t1 = @text1.split("\n").map.with_index { |l,i| [i, l] }.to_h
    t2 = @text2.split("\n").map.with_index { |l,i| [i, l] }.to_h
    t1_in_t2 = {}

    # чем тексты похожи
    t1.each do |i, line|
      matched_line_index, _ = @text2.find {|i,l| l == line }
      matched_line_index ||= -2
      # номер строки в text1 — совпал с номером строки в text2
      t1_in_t2[i, matched_line_index]
      # здесь нужно как-то сразу искать последовательности (совпавшие номера строк) и фиксировать их
    end

    split_to_seq(t1_in_t2.values)
  end

  private

  # Нахождение последовательностей
  # Пример:
  #
  # split_to_seq([100,1,2,3,4,80,81,82,20,16,1])
  # => [[100], [1, 2, 3, 4], [80, 81, 82], [20], [16], [1]]
  #
  def split_to_seq(orig_array)
    # если в массиве нет элеменов то возвращаем его обратно
    return orig_array if orig_array.empty?

    # метод работает только для отсортированных массивов
    # array = array.sort
    array = orig_array.dup

    # первым элементом первой последовательности будет первый элемент массива
    arr = [[array.shift]]

    # последняя последовательность
    seq = arr.last

    array.each do |e|
      # если последний элемент в последней последовательности меньше на 1 текущего
      if seq.last + 1 == e
        # то добавляем его в конец последней последовательности
        seq << e
      else
        # иначе создаем новую последовательность с текущим элементом
        seq = [e]
        # и добавляем новую последовательность в массив
        arr.push(seq)
      end
    end

    arr
  end
end
