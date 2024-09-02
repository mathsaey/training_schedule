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

export { copyWorkout, moveWorkout };

const loadingClass = "opacity-50"

function addTemporary(workout, destination) {
  workout.classList.add(loadingClass)
  destination.appendChild(workout)
}

function pushEvent(lv, ev, workoutId, destDateId) {
  lv.pushEvent(ev, {"workout": workoutId, "target": destDateId})
}

function moveWorkout(lv, workout, destination) {
  addTemporary(workout, destination)
  pushEvent(lv, "move", workout.id, destination.id)
}

function copyWorkout(lv, workout, destination) {
    let copy = workout.cloneNode(true)
    copy.id = `${copy.id}_copy_${destination.id}`
    copy.setAttribute("draggable", false)
    addTemporary(copy, destination)
    pushEvent(lv, "copy", workout.id, destination.id)
}
