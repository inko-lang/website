(function() {
    "use strict";

    document.addEventListener('DOMContentLoaded', function() {
        document
            .querySelector('.expand-menu a')
            .addEventListener('click', function() {
                document
                    .querySelector('.main-menu')
                    .classList
                    .toggle('visible');
            });

        let select_example = document.querySelector('.code-examples select');

        select_example.addEventListener('click', function() {
            let value = select_example.value;

            document
                .querySelector('.code-examples .example.visible')
                .classList
                .remove('visible');

            document
                .querySelector(`.code-examples .example[data-example="${value}"]`)
                .classList
                .add('visible');
        });
    });
})();
