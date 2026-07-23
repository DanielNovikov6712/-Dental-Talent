import { Controller } from "@hotwired/stimulus"

// Shows/hides profile fields based on the selected job function and employment
// types (PRD §4). Groups declare when they are visible via data attributes:
//   data-visible-functions="general_dentist dental_hygienist specialist"
//   data-visible-employment="employed temporary"
// Skill blocks declare their group via data-skill-group and are matched to the
// function through the skillMap value.
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
    if (functions.length) visible = functions.includes(fn)
    if (employmentTypes.length) visible = employment.some((e) => employmentTypes.includes(e))

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
