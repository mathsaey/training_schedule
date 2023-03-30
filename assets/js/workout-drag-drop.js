export default {
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
      let action = e.dataTransfer.dropEffect
      if (dest.id == data.source && action == "move") { return }

      let workout = e.view.document.getElementById(data.workout)
      this.pushEvent("workout_dragged", {
        "action": action,
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
        copy.setAttribute("draggable", false)
        copy.classList.add(loadingClass)
        dest.appendChild(copy)
      }
    })
  }
}
