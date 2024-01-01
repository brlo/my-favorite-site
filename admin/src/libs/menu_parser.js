import {_} from 'vue-underscore';

// Функция, которая преобразует массив в дерево
// [ {id: 1, parent_id: null}, {id: 2, parent_id: 1}]
// => [ {id: 1, parent_id: null, childs: [ {id: 2, parent_id: 1} ]} ]
function arrayToTree(originArray) {
  const field_id = 'id'
  const field_parent_id = 'parent_id'

  // clone
  // let array = [...originArray]
  let array = [];
  for (let item of originArray) { array.push(item) };

  // Создаем пустой объект для хранения дерева
  let tree = [];
  // Проходим по всем элементам массива
  for (let item of array) {
    // Если элемент имеет parent_id, то он является потомком какого-то узла
    if (item[field_parent_id]) {
      // Находим родительский узел по parent_id
      let parent = array.find((x) => x[field_id] === item[field_parent_id]);
      // Если родительский узел существует
      if (parent) {
        // Если у родительского узла еще нет поля childs, то создаем его как пустой массив
        if (!parent.childs) {
          parent.childs = [];
        }
        // Добавляем текущий элемент в массив childs родительского узла
        parent.childs.push(item);
      }
    } else {
      // Если элемент не имеет parent_id, то он является корневым узлом
      // Добавляем его в объект дерева по его id
      tree.push(item);
    }
  }
  // Возвращаем объект дерева
  return tree;
}

// линейный список элементов для select (с чёрточками для отображения глубины)
// [ {id: 1, parent_id: null, childs: [ {id: 2, parent_id: 1} ]} ]
// => [ {name: 'root el', code: id }, {name: '- child el', code: id} ]
function treeMenuToLineMenu(treeMenu, depth = 0) {
  if (treeMenu == null) return []

  let l_menu = []

  _.each(
    treeMenu,
    function (item) {
      l_menu.push({
        name: '-'.repeat(depth) + ' ' + item.title,
        code: item.id,
      })

      if (item.childs) {
        l_menu = _.union(
          l_menu,
          treeMenuToLineMenu(item.childs, depth+1)
        )
      }
    }
  )
  return l_menu
}

export { arrayToTree, treeMenuToLineMenu }
