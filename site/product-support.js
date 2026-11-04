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
        '<header class="support-dialog-heading"><h2 id="supportDialogTitle">Found this useful? Fuel my next build.</h2>' +
          '<p id="supportDialogIntro">Help cover AI credits and hosting so I can keep improving these free apps.</p></header>' +
        '<div class="support-options">' +
          '<section class="support-international" aria-label="International support options">' +
            '<article class="support-kofi">' +
              '<h3>Global</h3><figure><span class="support-qr-crop"><img src="/assets/support-kofi.png" width="820" height="820" alt="QR code to support Thang Luu on Ko-fi"></span></figure>' +
            '</article>' +
          '</section>' +
          '<article class="support-option support-bank">' +
            '<h3>Vietnam</h3>' +
            '<figure><img src="/assets/support-shopeepay.jpg" width="1096" height="1096" alt="ShopeePay QR for voluntary support"></figure>' +
          '</article>' +
        '</div></div></dialog>';
  }

  function initializeSupport() {
    var customTriggers = document.body.hasAttribute("data-support-shared") ? Array.from(document.querySelectorAll("[data-support-open]")) : [];
    if (!shouldShowSupport() || document.getElementById("supportDialog") || document.querySelector(".support-work") || (document.querySelector("[data-support-open]") && !customTriggers.length)) return;

    var trigger = document.createElement("button");
    trigger.type = "button";
    trigger.className = "support-floating-trigger";
    trigger.setAttribute("aria-haspopup", "dialog");
    trigger.setAttribute("aria-controls", "supportDialog");
    trigger.innerHTML = '<span>Fuel my next build</span>';

    var slot = document.getElementById('supportSlot');
    document.body.insertAdjacentHTML("beforeend", dialogMarkup());
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
    var closeButton = document.getElementById("supportClose");
    if (!dialog || typeof dialog.showModal !== "function") return;

    function openSupport() {
      dialog.showModal();
      document.body.classList.add('support-dialog-open');
    }
    (customTriggers.length ? customTriggers : [trigger]).forEach(function (button) {
      button.addEventListener("click", function () {
        openSupport();
      });
    });
    if (customTriggers.length && window.location.hash === "#support") {
      openSupport();
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
