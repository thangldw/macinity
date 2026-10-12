(function () {
  "use strict";

  var root = document.documentElement;

  function preferredTheme() {
    try {
      var saved = localStorage.getItem("theme");
      if (saved === "dark" || saved === "light") return saved;
    } catch {
      // Use the default light theme when storage is unavailable.
    }
    return "light";
  }

  function syncThemeButton(button) {
    if (!button) return;
    var dark = root.dataset.theme === "dark";
    var labels = {
      en: ["Switch to dark theme", "Switch to light theme"],
      vi: ["Chuyển sang giao diện tối", "Chuyển sang giao diện sáng"],
      ja: ["ダークテーマに切り替える", "ライトテーマに切り替える"],
      zh: ["切换深色主题", "切换浅色主题"]
    };
    var language = root.lang.split("-")[0];
    var copy = labels[language] || labels.en;
    button.setAttribute("aria-label", copy[dark ? 1 : 0]);
    var icon = button.querySelector("i");
    if (icon) icon.className = dark ? "fa-solid fa-sun" : "fa-solid fa-moon";
  }

  function setTheme(theme, button) {
    root.dataset.theme = theme;
    try {
      localStorage.setItem("theme", theme);
    } catch {
      // Theme selection remains active for the current page.
    }
    syncThemeButton(button);
    document.dispatchEvent(new CustomEvent("themechange", { detail: { theme: theme } }));
  }

  function bindThemeControl() {
    var button = document.getElementById("themeToggle");
    if (!button) return;
    syncThemeButton(button);
    if (button.dataset.siteShellBound === "true") return;
    button.dataset.siteShellBound = "true";
    button.addEventListener("click", function () {
      setTheme(root.dataset.theme === "dark" ? "light" : "dark", button);
    });
  }

  function observeThemeControl() {
    if (!document.body || typeof MutationObserver === "undefined") return;
    new MutationObserver(bindThemeControl).observe(root, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["lang"]
    });
  }

  function initializeThemeControl() {
    bindThemeControl();
    observeThemeControl();
  }

  root.dataset.theme = root.dataset.theme === "dark" || root.dataset.theme === "light"
    ? root.dataset.theme
    : preferredTheme();

  if (document.body) initializeThemeControl();
  else document.addEventListener("DOMContentLoaded", initializeThemeControl);
})();
