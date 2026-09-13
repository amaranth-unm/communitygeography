// Keep native UNM disclosures usable with Escape and dismiss on outside click.
(function () {
  'use strict';
  document.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape') return;
    document.querySelectorAll('.unm-header details[open]').forEach(function (details) {
      const containsFocus = details.contains(document.activeElement);
      details.open = false;
      if (containsFocus) details.querySelector('summary').focus();
    });
  });
  document.addEventListener('click', function (event) {
    document.querySelectorAll('.unm-header details[open]').forEach(function (details) {
      if (!details.contains(event.target)) details.open = false;
    });
  });
})();
