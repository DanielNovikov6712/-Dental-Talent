import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["functionSelect", "employment", "group", "skillGroup", "skillPrompt"]
  static values = { skillMap: Object }

  connect() {
    this.update()
  }

  update() {
    const fn = this.hasFunctionSelectTarget ? this.functionSelectTarget.value : ""
    const employment = this.employmentTargets.filter((el) => el.checked).map((el) => el.value)

    this.groupTargets.forEach((group) => this.toggleGroup(group, fn, employment))
    this.toggleSkillGroups(fn)
  }

  toggleGroup(group, fn, employment) {
    const functions = this.list(group.dataset.visibleFunctions)
    const employmentTypes = this.list(group.dataset.visibleEmployment)

    let visible = true
    if (functions.length) visible = visible && functions.includes(fn)
    if (employmentTypes.length) visible = visible && employment.some((e) => employmentTypes.includes(e))

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
