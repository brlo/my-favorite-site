import notifications from "services/notifications_service"

export const shareLink = (url = window.location.href) => {
  const decodedUrl = decodeURIComponent(url)
  copyText(decodedUrl)
  notifications.add(`<t>Ссылка скопирована:</t> ${decodedUrl}`)
}

export const strip = (str) => {
  return ( str || '' ).replace( /^\s+|\s+$/g, '' );
}

export const stripDots = (str) => {
      return ( str || '' ).replace( /^[\s\.\,\?\!\;]+|[\s\.\,\;]+$/g, '' );
    }

export const copyText = (text) => {
  var dummy = document.createElement('input');

  document.body.appendChild(dummy);
  dummy.value = text;

  // clear selection
  if (window.getSelection) {
    if (window.getSelection().empty) {  // Chrome
      window.getSelection().empty();
    } else if (window.getSelection().removeAllRanges) {  // Firefox
      window.getSelection().removeAllRanges();
    }
  };

  dummy.select();
  document.execCommand('copy');
  document.body.removeChild(dummy);
}

export const copyTextLink = (textBefore, LinkText, TextAfter, href) => {
  const html = textBefore + '<a href="' + href + '">' + LinkText + '</a>' + TextAfter;
  const dummy = document.createElement('div');

  // clear selection
  if (window.getSelection) {
    if (window.getSelection().empty) {  // Chrome
      window.getSelection().empty();
    } else if (window.getSelection().removeAllRanges) {  // Firefox
      window.getSelection().removeAllRanges();
    }
  };

  document.body.appendChild(dummy);
  dummy.innerHTML = html;
  const range = document.createRange();
  range.selectNode(dummy);
  window.getSelection().addRange(range);

  document.execCommand('copy');
  document.body.removeChild(dummy);
}

export const en2ruTranslit = (text) => {
  const tr_en_ru_dict = {"q":"й","w":"ц","e":"у","r":"к","t":"е","y":"н","u":"г","i":"ш","o":"щ","p":"з","[":"х","]":"ъ","a":"ф","s":"ы","d":"в","f":"а","g":"п","h":"р","j":"о","k":"л","l":"д",";":"ж","'":"Э"," z":" я","x":"ч","c":"с","v":"м","b":"и","n":"т","m":"ь",",":"б",".":"ю","/":".","Q":"Й","W":"Ц","E":"У","R":"К","T":"Е","Y":"Н","U":"Г","I":"Ш","O":"Щ","P":"З","{":"Х","}":"Ъ","A":"Ф","S":"Ы","D":"В","F":"А","G":"П","H":"Р","J":"О","K":"Л","L":"Д",":":"Ж","|":"/","Z":"Я","X":"Ч","C":"С","V":"М","B":"И","N":"Т","M":"Ь","<":"Б",">":"Ю","?":",","@":"'","#":"№","$":";","^":":","&":"?"};
  return text.replace(/./g, m => (tr_en_ru_dict[m] || m) );
}

export const isMobileDevice = () => {
  return (( window.innerWidth <= 400 ) && ( window.innerHeight >= 400 ));
}

// найти параметр в query (обращаться как к хэшу: params.my_param_name)
export const params = new Proxy(new URLSearchParams(window.location.search), {
  get: (searchParams, prop) => searchParams.get(prop),
});

// ===========================
// ARRAY FUNCTIONS
// ===========================
export const sortArrayInt = (a, b) => {
  if(a === Infinity) {
    return 1;
  } else if(isNaN(a)) {
    return -1;
  } else {
    return a - b;
  }
}

// Переводим массив в последовательности:
// Пример: [1,2,3,10] -> [[1,2,3], [10]]
export const arrayToSeqs = (arr) => {
  // сортируем
  sorted = arr.sort(sortArrayInt);

  // первым элементом первой последовательности будет первый элемент массива
  seqs = [[sorted.shift()]];

  // последняя последовательность
  seq = seqs[seqs.length - 1];

  // проходим по [1,2,3,10]
  sorted.forEach(e => {
    // последний элемент в первой последовательности
    let lastNum = seq[seq.length - 1];
    // если последний элемент в последней последовательности меньше на 1 текущего элемента
    if ((lastNum + 1) == e) {
      // то добавляем его в конец последней последовательности
      seq.push(e);
    } else {
      // иначе создаем новую последовательность с текущим элементом
      seq = [e];
      // и добавляем новую последовательность в массив
      seqs.push(seq);
    };
  });

  return(seqs);
};

export const convertToRuby = (text) => {
  if (!text) return text

  // - Иероглифы (один или более)
  // - НЕ захватываем запятые, точки и другие знаки препинания
  // - Затем [хирагана/катакана]
  return text.replace(
    /([\u4e00-\u9fff\u3400-\u4dbf]+)\[([\u3040-\u309f\u30a0-\u30ff]+)\]/g,
    (match, kanji, furigana) => {
      return `<ruby><rb>${kanji}</rb><rt>${furigana}</rt></ruby>`
    }
  )
}
