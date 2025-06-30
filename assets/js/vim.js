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

// This module provides vim-like keybindings for the workout table editor.

import * as schedule from './schedule.js';

function isSafari() {
  return /^((?!chrome|android).)*safari/i.test(navigator.userAgent)
}

export default {
  onMount(liveView) {
    // Don't support safari for now.
    if (isSafari()) { return }
    initState(liveView)
    updateGrid(liveView)
  },
  onUpdate(_liveView) {
    if (isSafari()) { return }
    updateGrid(liveView)
  }
}

// Constants
// ---------

const clearCellMarkerAfter = 5 * 1000;
const markerCellClasses = [
  "border-dashed", "border-4", "border-green-600", "dark:border-green-600"
]

const moveKeys = new Set([
  "h", "j", "k", "l",
  "w", "e", "b", "t"
])


// State
// -----

// Workout interaction
let liveView
let editable

// Cell marker
let cellMarkerTimeout

// Grid and selection
let bottom
let grid
let pos
let cur

// LiveView interaction
// --------------------

function initState(lv) {
  liveView = lv;
  editable = lv.el.hasAttribute("editable");
  cur = schedule.getCurrentDayCell();

  document.body.addEventListener("keydown", processKey);
  document.body.addEventListener("click", processClick);
}

function updateGrid(lv) {
  grid = lv.el.childNodes.values()
    .filter(e => e.id)
    .toArray()
    .entries()
    .map(([idx, cell]) => ({
      idx: idx,
      cell: cell,
      workouts: cell.querySelectorAll("[id^='workout_']")
    }))
    .toArray()

  bottom = Math.trunc(grid.length / 7) - 1

  // Select the first cell if the schedule does not contain the current day
  if (!cur) { cur = grid[0].cell }
  setPosToCurrent();
}

// Current cell & Position
// -----------------------

function isCell(div) { return div.id.startsWith('cell_') }
function isWorkout(div) { return div.id.startsWith('workout_') }

function findParentCell(div) {
  let current = div;
  while (current) {
    if (isCell(current)) { return current }
    current = current.parentElement;
  }
}

function setPosToCurrent() {
  let currentCell = isWorkout(cur) ? cur : findParentCell(cur);

  for (const [idx, obj] of grid.entries()) {
    if (currentCell === obj.cell) {
      pos = idx
      break;
    }
  }
}

// Current cell marker
// -------------------

function showMarker() {
  clearTimeout(cellMarkerTimeout)
  cellMarkerTimeout = setTimeout(clearMarker, clearCellMarkerAfter)
  cur.classList.add(...markerCellClasses)
}

function clearMarker() { cur.classList.remove(...markerCellClasses) }

// Motions
// -------

function posToidxPair(pos) {return [Math.trunc(pos / 7), pos % 7]}
function idxPairToPos([i, j]) { return i * 7 + j }

function resFromIdxPair(pair) {
  let res = idxPairToPos(pair);
  return [res, grid[res].cell];
}

function idxPairMotion(updateIdx) {
  return function(pos, _) {
    let [i, j] = posToidxPair(pos)
    let [ni, nj] = updateIdx(i, j);
    let res = (ni < 0 || nj < 0 || ni > bottom || nj > 6) ? [i, j] : [ni, nj];
    return resFromIdxPair(res);
  }
}

function workoutWiseMotion(getSlice, select, selectInCurrent) {
  return function(pos, idx) {
    for (const obj of getSlice(pos)) {
      if (obj.idx == pos && obj.workouts.length > 0) {
        let selected = selectInCurrent(obj);
        if (selected) { return [obj.idx, selected] }
      } else if (obj.workouts.length > 0) {
        let selected = select(obj);
        return [obj.idx, selected];
      }
    }
    return [pos, cur]
  }
}

function braceMotion(getNext, getMax) {
  return function(pos, idx) {
    let [i, j] = posToidxPair(pos)
    let max = getMax()

    for (let r = i, n = getNext(r) ; r != max; r = n, n = getNext(n)) {
      let slice = grid.slice(r * 7, r * 7 + 7);
      let nSlice = grid.slice(n * 7, n * 7 + 7);

      if (
        !slice.every(obj => obj.workouts.length == 0) &&
        nSlice.every(obj => obj.workouts.length == 0)
      ) { return resFromIdxPair([n, j]); }
    }

    return resFromIdxPair([max, j]);
  }
}

const motionH = idxPairMotion((i, j) => [i, j - 1])
const motionJ = idxPairMotion((i, j) => [i + 1, j])
const motionK = idxPairMotion((i, j) => [i - 1, j])
const motionL = idxPairMotion((i, j) => [i, j + 1])
const motion0 = idxPairMotion((i, j) => [i, 0])
const motion$ = idxPairMotion((i, j) => [i, 6])

const motionLBrace = braceMotion((i) => i - 1, () => 0);
const motionRBrace = braceMotion((i) => i + 1, () => bottom);

const motionW = workoutWiseMotion(
  (pos) => grid.slice(pos),
  (obj) => obj.workouts[0],
  (obj) => {
    for (const [idx, workout] of obj.workouts.entries()) {
      if (workout == cur && idx < obj.workouts.length) {
        return obj.workouts[idx + 1]
      }
    }
    return false
  }
);

const motionE = workoutWiseMotion(
  (pos) => grid.slice(pos),
  (obj) => obj.workouts[obj.workouts.length - 1],
  (obj) => {
    if (obj.workouts[obj.workouts.length - 1] == cur) { return false }
    else { return obj.workouts[obj.workouts.length - 1]}
  }
)

const motionB = workoutWiseMotion(
  (pos) => grid.slice(0, pos + 1).reverse(),
  (obj) => obj.workouts[obj.workouts.length - 1],
  (obj) => {
    for (const [idx, workout] of obj.workouts.entries()) {
      if (workout == cur && idx > 0) { return obj.workouts[idx - 1] }
    }
    return false
  }
)

function motionCaret(pos, cur) {
  let [i, j] = posToidxPair(pos)

  for (obj of grid.slice(i * 7, i * 7 + 7)) {
    if (obj.workouts.length > 0) { return [pos, obj.workouts[0]] }
  }

  return [pos, cur]
}

function doMotion(motion) {
  let [nextPos, nextCur] = motion(pos, cur)

  clearMarker()
  cur = nextCur
  pos = nextPos
  showMarker()

  cur.scrollIntoView({block: "center"})
}

// Actions
// -------

function insert() { grid[pos].cell.querySelector("a").click() }

function remove() {
  let workouts = grid[pos].cell.querySelectorAll("[id^='workout_']");
  schedule.deleteWorkouts(liveView, Array.from(workouts));
}

function processKey(e) {
  if (!editable && !moveKeys.has(e.key)) { return }
  if (document.getElementById("schedule_workout_popup")) { return }
  // console.log(e);

  switch (e.key) {
    // Movement
    case 'ArrowDown':
    case 'j':
      doMotion(motionJ)
      break;
    case 'ArrowUp':
    case 'k':
      doMotion(motionK)
      break;
    case 'ArrowLeft':
    case 'h':
      doMotion(motionH)
      break;
    case 'ArrowRight':
    case 'l':
      doMotion(motionL)
      break;
    case '$':
      doMotion(motion$)
      break;
    case '0':
      doMotion(motion0)
      break;
    case '^':
      doMotion(motionCaret)
      break;
    case 'w':
      doMotion(motionW)
      break;
    case 'e':
      doMotion(motionE)
      break;
    case 'b':
      doMotion(motionB)
      break;
    case '{':
      doMotion(motionLBrace)
      break;
    case '}':
      doMotion(motionRBrace)
      break;
    // Editing
    case 'i':
      insert()
      break;
    case 'x':
      remove()
      break;
  }
}

function processClick(e) {
  let target = e.target;

  while (target) {
    if (isCell(target) || isWorkout(target)) {
      clearMarker();
      cur = target;
      setPosToCurrent();
      showMarker();
      return;
    } else {
      target = target.parentElement;
    }
  }
}

