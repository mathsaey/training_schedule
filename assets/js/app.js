// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.delayedShow(200))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

window.getDropTarget = function (e) {
  var target = e.target
  while (!target.attributes.dropable) {
    target = target.parentElement
  }
}

Hooks.WorkoutDragAndDrop = {
  target(e) {
    var target = e.target
    while (!target.attributes.dropable) {
      target = target.parentElement
    }
    return target
   },

  mounted() {
    const dropClasses = ["border-sky-500", "dark:border-sky-500"]

    this.el.addEventListener("dragstart", (e) => {
      e.dataTransfer.dropEffect = "move"
      e.dataTransfer.setData("text/plain", e.target.id)
    })

    this.el.addEventListener("dragenter", e => {
      e.preventDefault()
      this.target(e).classList.add(...dropClasses)
    })

    this.el.addEventListener("dragleave", e => {
      e.preventDefault()
      this.target(e).classList.remove(...dropClasses)
    })

    this.el.addEventListener("drop", e => {
      e.preventDefault()
      let target = this.target(e)
      let id = e.dataTransfer.getData("text/plain")

      target.classList.remove(...dropClasses)
      target.appendChild(e.view.document.getElementById(id))
      // TODO: add pending indicator
      this.pushEvent("workout_moved", {"workout": id, "target": target.id})
    })
  }
}
