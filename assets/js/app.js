import css from "../css/app.scss"
import "phoenix_html"
import { Socket } from "phoenix"
import LiveSocket from "phoenix_live_view"

const liveSocket = new LiveSocket("/live", Socket);
liveSocket.connect();

console.log("app.js loaded", css);
