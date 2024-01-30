(function() {
  "use strict";

  let show = function(select) {
    let value = select.value;
    let visible = document.querySelector('.code-examples .example.visible');

    if (visible) {
      visible.classList.remove('visible');
    }

    document
      .querySelector(`.code-examples .example[data-example="${value}"]`)
      .classList
      .add('visible');
  };

  let show_random = function(select) {
    let options = select.querySelectorAll('option');
    let index = Math.floor(Math.random() * options.length);

    options[index].selected = true
    show(select);
  };

  document.addEventListener('DOMContentLoaded', function() {
    let select = document.querySelector('.code-examples select');

    if (select) {
      select.addEventListener('change', function(e) { show(e.target); });
      show_random(select);
    }

    document.querySelectorAll('.expand-menus a').forEach(function(button) {
      button.addEventListener('click', function(event) {
        event.preventDefault();

        let query = button.dataset.toggle;
        let new_text = button.dataset.toggleText;
        let old_text = button.innerText;

        button.dataset.toggleText = old_text;
        button.innerText = new_text;
        document.querySelector(query).classList.toggle('visible');
      });
    });

    let timer = null;

    document.querySelectorAll('.install-package').forEach(function(a) {
      a.addEventListener('click', function(e) {
        e.preventDefault();
        navigator.clipboard.writeText(a.dataset.copy).then(function() {
          if (timer) {
            clearTimeout(timer);
            timer = null;
          }

          let notice = document.querySelector('.copy-notice');

          notice.classList.add('visible');
          timer = setTimeout(function() {
            notice.classList.remove('visible')
          }, 5000);
        });
      });
    });
  });
})();
