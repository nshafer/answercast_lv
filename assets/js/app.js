import css from "../css/app.scss";
import "phoenix_html";

// Connect to the live socket for most pages
import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";
const liveSocket = new LiveSocket("/live", Socket);
liveSocket.connect();

// Initialize the scroll detection
import detectScroll from "./scroll-detector";
detectScroll();

console.log("app.js loaded", css);
