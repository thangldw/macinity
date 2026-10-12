(function () {
  "use strict";

  function normalizedPath() {
    var path = window.location.pathname.replace(/index\.html$/, "");
    return path.endsWith("/") ? path : path + "/";
  }

  function shouldShowSupport() {
    return true;
  }

  function dialogMarkup() {
    return '<dialog class="support-dialog" id="supportDialog" aria-labelledby="supportDialogTitle" aria-describedby="supportDialogIntro">' +
      '<div class="support-dialog-shell">' +
        '<button class="support-dialog-close" id="supportClose" type="button" aria-label="Close support options">&times;</button>' +
        '<header class="support-dialog-heading">' +
          '<p class="support-kicker">Support</p>' +
          '<h2 id="supportDialogTitle">Support my work</h2>' +
          '<p id="supportDialogIntro">If these projects have been useful to you, your support helps me maintain them and build new learning tools. Support is always optional.</p>' +
        '</header>' +
        '<div class="support-options">' +
          '<section class="support-international" aria-label="International support options">' +
            '<article class="support-github">' +
              '<p class="support-option-label">International</p>' +
              '<h3>GitHub Sponsors</h3>' +
              '<p>Choose a contribution type and enter an amount in USD.</p>' +
              '<form class="sponsor-form" action="https://github.com/sponsors/thangldw/sponsorships" method="get" target="_blank">' +
                '<fieldset class="sponsor-frequency">' +
                  '<legend class="sr-only">Contribution type</legend>' +
                  '<input class="sponsor-frequency-input" type="radio" name="frequency" id="sharedSponsorMonthly" value="recurring" checked>' +
                  '<label for="sharedSponsorMonthly">Monthly</label>' +
                  '<input class="sponsor-frequency-input" type="radio" name="frequency" id="sharedSponsorOneTime" value="one-time">' +
                  '<label for="sharedSponsorOneTime">One-time</label>' +
                '</fieldset>' +
                '<label class="sponsor-amount-label" for="sharedSponsorAmount">Amount <span>USD</span></label>' +
                '<div class="sponsor-amount-control"><span aria-hidden="true">$</span>' +
                  '<input id="sharedSponsorAmount" name="amount" type="number" min="1" max="12000" step="1" inputmode="numeric" placeholder="5" aria-describedby="sharedSponsorAmountHelp" required>' +
                '</div>' +
                '<button class="support-primary" type="submit">Continue on GitHub <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M4 12h16m-6-6 6 6-6 6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></button>' +
                '<p class="sponsor-help" id="sharedSponsorAmountHelp">GitHub will open to review and confirm your sponsorship.</p>' +
              '</form>' +
            '</article>' +
            '<article class="support-kofi">' +
              '<p class="support-option-label">International</p>' +
              '<h3>Ko-fi</h3>' +
              '<p class="support-kofi-copy">Leave a one-time tip securely through Ko-fi.</p>' +
              '<a class="support-kofi-button" href="https://ko-fi.com/F4N224DDUV" target="_blank" rel="noopener noreferrer" aria-label="Buy me a coffee on Ko-fi">' +
                '<img src="https://storage.ko-fi.com/cdn/kofi6.png?v=6" height="28" alt="Buy Me a Coffee at ko-fi.com">' +
              '</a>' +
            '</article>' +
          '</section>' +
          '<article class="support-option support-bank">' +
            '<div class="support-bank-heading"><div><p class="support-option-label">Vietnam</p><h3>Bank transfer</h3></div><span>MB Bank</span></div>' +
            '<figure><img src="/assets/support-vietqr-mb.jpg" width="845" height="1151" alt="VietQR for an MB Bank transfer to Luu Duc Thang">' +
              '<figcaption>Scan with a Vietnamese banking app.</figcaption></figure>' +
          '</article>' +
        '</div>' +
      '</div>' +
    '</dialog>';
  }

  function initializeSupport() {
    var customTriggers = document.body.hasAttribute("data-support-shared") ? Array.from(document.querySelectorAll("[data-support-open]")) : [];
    if (!shouldShowSupport() || document.getElementById("supportDialog") || document.querySelector(".support-work") || (document.querySelector("[data-support-open]") && !customTriggers.length)) return;

    var trigger = document.createElement("button");
    trigger.type = "button";
    trigger.className = "support-floating-trigger";
    trigger.setAttribute("aria-haspopup", "dialog");
    trigger.setAttribute("aria-controls", "supportDialog");
    trigger.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path fill="currentColor" d="M4 4h15v3H5a1 1 0 0 0 0 2h15a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Zm12 9v4h6v-4h-6Zm2 1a1 1 0 1 1 0 2 1 1 0 0 1 0-2Z"/></svg><span>Support my work</span>';

    document.body.insertAdjacentHTML("beforeend", dialogMarkup());
    var slot = document.getElementById('supportSlot');
    if (customTriggers.length) {
      customTriggers.forEach(function (button) { button.setAttribute("aria-haspopup", "dialog"); button.setAttribute("aria-controls", "supportDialog"); });
    } else if (slot) {
      trigger.classList.add('support-inline-trigger');
      slot.appendChild(trigger);
      var hostSelector = slot.getAttribute('data-support-host');
      if (hostSelector) {
        function placeSupport() {
          var host = document.querySelector(hostSelector);
          slot.hidden = !host;
          if (host && slot.parentElement !== host) host.appendChild(slot);
        }
        placeSupport();
        new MutationObserver(placeSupport).observe(document.body, { childList: true, subtree: true });
      }

    } else {
      document.body.appendChild(trigger);
    }

    var dialog = document.getElementById("supportDialog");
    // Restricted study pages use links instead of third-party forms or images.
    if (document.getElementById('supportSlot') && document.querySelector('meta[http-equiv="Content-Security-Policy"]')) {
      var form = dialog.querySelector('.sponsor-form');
      if (form) {
        var sponsor = document.createElement('a');
        sponsor.className = 'support-primary'; sponsor.href = 'https://github.com/sponsors/thangldw';
        sponsor.target = '_blank'; sponsor.rel = 'noopener noreferrer'; sponsor.textContent = 'Continue on GitHub';
        form.replaceWith(sponsor);
      }
      var kofi = dialog.querySelector('.support-kofi-button');
      if (kofi) kofi.textContent = 'Support on Ko-fi';
    }

    var closeButton = document.getElementById("supportClose");
    if (!dialog || typeof dialog.showModal !== "function") return;

    (customTriggers.length ? customTriggers : [trigger]).forEach(function (button) {
      button.addEventListener("click", function () {
        dialog.showModal();
        document.body.classList.add("support-dialog-open");
      });
    });
    if (customTriggers.length && window.location.hash === "#support") {
      dialog.showModal();
      document.body.classList.add("support-dialog-open");
    }
    closeButton.addEventListener("click", function () {
      dialog.close();
    });
    dialog.addEventListener("click", function (event) {
      if (event.target === dialog) dialog.close();
    });
    dialog.addEventListener("close", function () {
      document.body.classList.remove("support-dialog-open");
    });
  }

  if (document.body) initializeSupport();
  else document.addEventListener("DOMContentLoaded", initializeSupport);
})();
