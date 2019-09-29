import css from "../css/app.scss";
import "phoenix_html";

// Connect to the live socket for most pages
import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";
const liveSocket = new LiveSocket("/live", Socket);
liveSocket.connect();

// Initialize the scroll detection
import detectScroll from "./scroll_detector";
detectScroll();

// Initialize support for checkbox menus
import checkboxMenu from "./checkbox_menu";
checkboxMenu();

console.log("app.js loaded", css);
