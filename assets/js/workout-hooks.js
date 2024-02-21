/* TrainingSchedule.ex
 * Copyright (c) 2023 - 2024, Mathijs Saey
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
  updated() { highlightCurrentDay() },
  mounted() {
    highlightCurrentDay()
    // Add drag and drop event listeners only if component is editable
    if (this.el.hasAttribute("editable")) {
      this.el.addEventListener("dragstart", dragstart)
      this.el.addEventListener("dragenter", dragenter)
      this.el.addEventListener("dragleave", dragleave)
      this.el.addEventListener("drop", (e) => {drop(e, this)})
    }
  }
}

// Date Highlight
// --------------

var currentDayCell = null;
const currentDayClasses = ["bg-gray-200", "dark:bg-gray-600"]
const secondsInDay = 24 * 60 * 60;

function highlightCurrentDay() {
  let now = new Date();
  let month = (now.getMonth() + 1).toString().padStart(2, '0');
  let id = `cell_${now.getFullYear()}-${month}-${now.getDate()}`;
  let cell = document.getElementById(id);

  if (cell != currentDayCell && currentDayCell != null) {
    currentDayCell.classList.remove(...currentDayClasses);
  }

  currentDayCell = cell;
  cell.classList.add(...currentDayClasses);

  // Schedule this function to run again when the day changes
  let hoursOfDayElapsed = 60 * 60 * now.getHours()
  let minutesOfDayElapsed = hoursOfDayElapsed + 60 * now.getMinutes()
  let secondsOfDayElapsed = minutesOfDayElapsed + now.getSeconds();
  let wait_time = 60 - now.getSeconds();

  setTimeout(highlightCurrentDay, 1000 * wait_time);
}

// Drag and Drop
// -------------

const dropClasses = ["border-sky-500", "dark:border-sky-500"]
const loadingClass = "opacity-50"

function findDropableParent(el) {
  while (!el.attributes.dropable) {
    el = el.parentElement
  }
  return el
}

function dragstart(e) {
  let workoutId = e.target.id
  let source = findDropableParent(e.target)
  let data = JSON.stringify({'workout': workoutId, 'source': source.id})
  e.dataTransfer.setData("text/plain", data)
  e.dataTransfer.effectAllowed = "copyMove"
}

function dragenter(e) {
  e.preventDefault()
  findDropableParent(e.target).classList.add(...dropClasses)
}

function dragleave(e) {
  e.preventDefault()
  findDropableParent(e.target).classList.remove(...dropClasses)
}

function drop(e, liveView) {
  e.preventDefault()
  let data = JSON.parse(e.dataTransfer.getData("text/plain"))
  let dest = findDropableParent(e.target)
  let action = e.dataTransfer.dropEffect
  if (dest.id == data.source && action == "move") { return }

  let workout = e.view.document.getElementById(data.workout)
  liveView.pushEvent("workout_dragged", {
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
}
