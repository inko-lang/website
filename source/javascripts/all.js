(function() {
    "use strict";

    let show_example = function(select) {
        let value = select.value;

        document
            .querySelector('.code-examples .example.visible')
            .classList
            .remove('visible');

        document
            .querySelector(`.code-examples .example[data-example="${value}"]`)
            .classList
            .add('visible');
    };

    let show_random_example = function(select) {
        let options = select.querySelectorAll('option');
        let index = Math.floor(Math.random() * options.length);

        options[index].selected = true

        show_example(select);
    };

    let bind_expander = function(button_expr, expand_expr) {
        let button = document.querySelector(button_expr);

        if ( !button ) {
            return;
        }

        button.addEventListener('click', function(event) {
            event.preventDefault();

            document.querySelector(expand_expr).classList.toggle('visible');
        });
    }

    document.addEventListener('DOMContentLoaded', function() {
        bind_expander('.expand-menu a', '.main-menu');
        bind_expander('.expand-sidebar a', '.sidebar');

        let select_example = document.querySelector('.code-examples select');

        if ( select_example ) {
            select_example.addEventListener('change', function(event) {
                show_example(event.target);
            });

            show_random_example(select_example);
        }
    });
})();
