(() => {
  const root = document.documentElement;
  const button = document.querySelector(".theme-toggle");
  const storedTheme = localStorage.getItem("cloudmason-theme");
  const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;

  function setTheme(theme) {
    root.dataset.theme = theme;
    if (button) {
      button.textContent = `theme: ${theme}`;
    }
    localStorage.setItem("cloudmason-theme", theme);
  }

  setTheme(storedTheme || (prefersDark ? "dark" : "light"));

  if (button) {
    button.addEventListener("click", () => {
      setTheme(root.dataset.theme === "dark" ? "light" : "dark");
    });
  }
})();
