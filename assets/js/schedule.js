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

const loadingClass = "opacity-50"

function addTemporary(workout, destination) {
  workout.setAttribute("draggable", false)
  workout.classList.add(loadingClass)
  destination.appendChild(workout)
}

function workoutPayload(workout) { return parseInt(workout.id.slice(8)) }
function destinationPayload(destination) { return destination.id.slice(5) }

export function moveWorkout(lv, workout, destination) {
  addTemporary(workout, destination)
  lv.pushEvent("move", {
      "workout": workoutPayload(workout),
      "target": destinationPayload(destination)
  })
}

export function deleteWorkouts(lv, workouts) {
  let payload = workouts.map((workout) => {
    workout.remove();
    return workoutPayload(workout);
  })

  lv.pushEvent("delete", payload);
}

export function copyWorkouts(lv, workouts, destinations) {
  let payload = workouts.map((workout, idx) => {
    let dest = destinations[idx];
    let copy = workout.cloneNode(true);
    copy.id = null;

    addTemporary(copy, dest);

    return {
      "destination": destinationPayload(dest),
      "template": workout.dataset.template
    }
  })

  lv.pushEvent("create", payload);
}

export function getCurrentDayCell() {
  let now = new Date();
  let month = (now.getMonth() + 1).toString().padStart(2, '0');
  let day = now.getDate().toString().padStart(2, '0');
  let id = `cell_${now.getFullYear()}-${month}-${day}`;
  return document.getElementById(id);
}
