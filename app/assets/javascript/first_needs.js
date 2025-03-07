function firstNeeds() {
  // Проверка и включение ночного режима
  if (document.cookie.includes('isNightMode=1')) {
    document.body.classList.toggle('night-mode', true);
  }

  // Проверка и изменение размера текста
  const articleEl = document.querySelector('article');
  if (articleEl) {
    if (document.cookie.includes('textSize=1')) {
      articleEl.classList.add('text-small');
    } else if (document.cookie.includes('textSize=2')) {
      articleEl.classList.add('text-medium');
    } else if (document.cookie.includes('textSize=3')) {
      articleEl.classList.add('text-large');
    }
  };
};
firstNeeds();
