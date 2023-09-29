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

const formatOpts = {weekday: 'short', day: 'numeric', month:'short'}
const formatter = new Intl.DateTimeFormat(undefined, formatOpts)

export default {
  mounted() {
    let dt = new Date(this.el.textContent.trim());
    this.el.textContent = formatter.format(dt);
    this.el.classList.remove("invisible");
  },
  updated() { this.mounted() }
}
