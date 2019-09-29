export default function checkboxMenu(options = {}) {
    // Uncheck the checkbox when a click is registered on the element
    document.addEventListener("click", function (e) {
        if (e.target && e.target.matches("[data-checkbox-menu-close]")) {
            const checkbox = document.querySelector(e.target.dataset.checkboxMenuClose);
            if (checkbox && checkbox.checked) {
                checkbox.checked = false;
            }
        }
    });
}