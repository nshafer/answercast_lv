export default function detectScroll(options = {}) {
    options.offset    = options.offset    || "0";
    options.debug     = options.debug     || false;
    options.className = options.className || "is-scrolled";

    if (!window.IntersectionObserver) {
        console.error("Can not detect scroll without IntersectionObserver support in the browser.");
        return false;
    }
    if (!document.body.classList && !document.body.classList.add && !document.body.classList.remove) {
        console.error("Can not detect scroll without Element.classList support in the browser.");
        return false;
    }

    function handleIntersection(entries) {
        if (entries.length > 0) {
            const scrolled = entries[0].boundingClientRect.y < 0;
            if (scrolled) {
                document.body.classList.add(options.className);
            } else {
                document.body.classList.remove(options.className);
            }
        }
    }

    const detection_pixel = document.createElement('div');
    detection_pixel.style.position = "absolute";
    detection_pixel.style.top = options.offset;
    detection_pixel.style.right = "0";
    if (options.debug) {
        detection_pixel.style.background = "lime";
        detection_pixel.style.zIndex = "9999";
        detection_pixel.style.width = "100%";
        detection_pixel.style.height = "1px";
    } else {
        detection_pixel.style.opacity = "0";
        detection_pixel.style.width = "1px";
        detection_pixel.style.height = "1px";
    }

    document.body.appendChild(detection_pixel);

    const observer = new IntersectionObserver(handleIntersection);

    observer.observe(detection_pixel);
}
