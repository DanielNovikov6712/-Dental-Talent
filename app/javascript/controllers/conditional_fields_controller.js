import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["functionSelect", "employment", "group", "skillGroup", "skillPrompt", "bigStatus"]
  static values = { skillMap: Object }

  connect() {
    this.update()
  }

  update() {
    const fn = this.hasFunctionSelectTarget ? this.functionSelectTarget.value : ""
    const employment = this.employmentTargets.filter((el) => el.checked).map((el) => el.value)
    const bigStatus = this.hasBigStatusTarget ? this.bigStatusTarget.value : ""

    this.groupTargets.forEach((group) => this.toggleGroup(group, fn, employment, bigStatus))
    this.toggleSkillGroups(fn)
  }

  toggleGroup(group, fn, employment, bigStatus) {
    const functions = this.list(group.dataset.visibleFunctions)
    const employmentTypes = this.list(group.dataset.visibleEmployment)
    const bigStatuses = this.list(group.dataset.visibleBigStatus)

    let visible = true
    if (functions.length) visible = visible && functions.includes(fn)
    if (employmentTypes.length) visible = visible && employment.some((e) => employmentTypes.includes(e))
    if (bigStatuses.length) visible = visible && bigStatuses.includes(bigStatus)

    group.hidden = !visible
  }

  toggleSkillGroups(fn) {
    const targetGroup = this.skillMapValue[fn]
    this.skillGroupTargets.forEach((block) => {
      block.hidden = !(targetGroup && block.dataset.skillGroup === targetGroup)
    })
    if (this.hasSkillPromptTarget) this.skillPromptTarget.hidden = Boolean(targetGroup)
  }

  list(value) {
    return (value || "").split(" ").filter(Boolean)
  }
}
