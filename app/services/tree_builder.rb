class TreeBuilder
  class << self
    # Вернёт полноценное дерево из объектов, в таком виде:
    #
    # TreeBuilder.build_tree_from_objects(array)
    # => [ {obj: _, childs: []}, ... ]
    def build_tree_from_objects(orig_array, field_id: :id, field_parent_id: :parent_id)
      array = orig_array.dup
      indexed_array = array.index_by { |i| i[field_id] }

      # Создаем пустой хеш для хранения дерева
      tree = []
      # Проходим по всем элементам массива
      array.each do |item|
        # Если элемент имеет parent_id, то он является потомком какого-то узла
        if item[field_parent_id].present?
          # Находим родительский узел по parent_id
          parent = indexed_array[item[field_parent_id]]
          # Если родительский узел существует
          if parent
            # Если у родительского узла еще нет поля childs, то создаем его как пустой массив
            parent[:childs] ||= []
            # Добавляем текущий элемент в массив childs родительского узла
            parent[:childs] << item
          end
        else
          # Если элемент не имеет parent_id, то он является корневым узлом
          # Добавляем его в хеш дерева по его id
          tree.push(item)
        end
      end

      # TODO: ПЕРЕПИСАТЬ НОРМАЛЬНО!
      #
      # Такая вот пока что кривая сортировка. Потом напишу нормально
      # Сейчас пока три уровня вглубину сортируем.
      array.each do |item|
        next if item[:childs].nil?
        item[:childs] = item[:childs].sort { |c| c[:priority].to_i }
        item[:childs].each do |i2|
          next if i2[:childs].nil?
          i2[:childs] = i2[:childs].sort { |c| c[:priority].to_i }
          i2[:childs].each do |i3|
            next if i3[:childs].nil?
            i3[:childs] = i3[:childs].sort { |c| c[:priority].to_i }
            i3[:childs]
          end
        end
      end

      # Возвращаем хеш дерева
      tree



      # # [id, parent_id]
      # ids_pairs = objects.map do |o|
      #   [o[field_id],
      #    o[field_parent_id]]
      # end
      # # {2=>{1=>nil, 3=>{4=>nil}}}
      # ids_tree = tree_by_parent_id(ids_pairs)

      # id__object = objects.index_by { |o| o[field_id] }
      # objects_tree = tree_ids_to_objects(ids_tree, id__object)
    end

    # Вернёт полноценное дерево из объектов, в таком виде:
    # [ {obj: _, childs: []}, ... ]
    def tree_ids_to_objects(ids_tree, id__object)
      return unless ids_tree.present?

      ids_tree.map do |p_id, child_ids|
        {
          obj: id__object[p_id],
          childs: tree_ids_to_objects(child_ids, id__object) || []
        }
      end
    end

    # --------------------------------------------------------------------

    # Строит иерархическое дерево по parent_id
    #
    # TreeBuilder.tree_by_parent_id([[1, 2], [3, 2], [2, nil], [4, 3]])
    # => {2=>{1=>nil, 3=>{4=>nil}}}
    #
    # TreeBuilder.tree_by_parent_id([[1, 2], [3, 2], [4, 3]])
    # => {1=>nil, 3=>{4=>nil}}
    def tree_by_parent_id pairs_from_id_and_parent_id
      id__parent_id = pairs_from_id_and_parent_id.to_h

      ids_by_parent_id = Hash.new([].freeze)
      id__parent_id.each do |id,parent_id|
        # если родителя нам так и не передали, то дерево мы не построим,
        # если будем ссылать на него, поэтому берём nil
        # (тогда все потеряшки будут принадлежать одной корневой группе - nil)
        p_id = id__parent_id.has_key?(parent_id) ? parent_id : nil
        ids_by_parent_id[p_id] += [id]
      end
      ids_by_parent_id.default = nil

      childs_tree(nil, ids_by_parent_id)
    end

    # Построение отсортированного линейного списка с указанием глубины вложенности
    #
    # Метод удобен для построения выпадающих списков в интерфейсах,
    # где все элементы отдаются на одном уровне вложенности подряд, но с
    # какой-либо индикацией глубины вложенности элемента
    #
    # TreeBuilder.sort_with_depth([[1, 2], [3, 2], [2, nil], [4, 3]])
    # => [{:id=>2, :depth=>0}, {:id=>1, :depth=>1}, {:id=>3, :depth=>1}, {:id=>4, :depth=>2}]
    #
    # TreeBuilder.sort_with_depth([[1, 2], [3, 2], [4, 3]])
    # => [{:id=>1, :depth=>0}, {:id=>3, :depth=>0}, {:id=>4, :depth=>1}]
    def sort_with_depth pairs_from_id_and_parent_id
      tree = tree_by_parent_id(pairs_from_id_and_parent_id)

      childs_with_depth(tree)
    end

    private

    # Выстраивает дерево элементов меню.
    # вначале сюда передаётся parent_id:nil, и таким образом ищутся дети без родителя (корневые элементы)
    # ну а потом эта же функция вызывает себя с parent_id реальным и так выстраивается всё дерево.
    def childs_tree parent_id, ids_by_parent_id
      # этого варианта не должно быть никогда, иначе заходим в endless loop
      return if ids_by_parent_id == {nil=>[nil]}

      childs = ids_by_parent_id[parent_id]

      return unless childs

      result = {}
      childs.sort.each do |id|
        result[id] = childs_tree(id, ids_by_parent_id)
      end

      result
    end

    # всё дерево потомков, начиная с depth
    def childs_with_depth sub_tree, depth: 0
      return [] if sub_tree.blank?

      result = []
      sub_tree.each do |id, s_tree|
        result += [
          { id: id, depth: depth },
          *childs_with_depth(s_tree, depth: depth+1)
        ]
      end

      result
    end
  end
end



