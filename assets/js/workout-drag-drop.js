/* TrainingSchedule.ex
 * Copyright (c) 2023, Mathijs Saey
 *
 * TrainingSchedule.ex is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * TrainingSchedule.ex is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
