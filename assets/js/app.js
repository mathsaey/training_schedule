// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import WorkoutDragAndDropHooks from "./workout-drag-drop"

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

Hooks.WorkoutDragAndDrop = {
  findDropableParent(el) {
    while (!el.attributes.dropable) {
      el = el.parentElement
    }
    return el
   },

  mounted() {
    const dropClasses = ["border-sky-500", "dark:border-sky-500"]
    const loadingClass = "opacity-50"

    this.el.addEventListener("dragstart", (e) => {
      let workoutId = e.target.id
      let source = this.findDropableParent(e.target)
      let data = JSON.stringify({'workout': workoutId, 'source': source.id})
      e.dataTransfer.setData("text/plain", data)
      e.dataTransfer.effectAllowed = "copyMove"
    })

    this.el.addEventListener("dragenter", e => {
      e.preventDefault()
      this.findDropableParent(e.target).classList.add(...dropClasses)
    })

    this.el.addEventListener("dragleave", e => {
      e.preventDefault()
      this.findDropableParent(e.target).classList.remove(...dropClasses)
    })

    this.el.addEventListener("drop", e => {
      e.preventDefault()
      let data = JSON.parse(e.dataTransfer.getData("text/plain"))
      let dest = this.findDropableParent(e.target)
      if (dest.id == data.source) { return }

      let workout = e.view.document.getElementById(data.workout)
      this.pushEvent("workout_dragged", {
        "action": e.dataTransfer.dropEffect,
        "workout": data.workout,
        "target": dest.id,
      })

      dest.classList.remove(...dropClasses)

      if (e.dataTransfer.dropEffect == "move") {
        workout.classList.add(loadingClass)
        dest.appendChild(workout)
      } else {
        let copy = workout.cloneNode(true)
        copy.id = `${copy.id}_copy_${dest.id}`
        copy.classList.add(loadingClass)
        dest.appendChild(copy)
      }
    })
  }
}
