module OnboardingHelper
  # Two-step progress indicator.
  def onboarding_steps(active:)
    steps = { upload: "Upload CV", review: "Review & complete" }
    content_tag :ol, class: "steps" do
      safe_join(steps.each_with_index.map do |(key, label), index|
        css = key == active ? "is-active" : ""
        content_tag :li, class: css do
          content_tag(:span, index + 1, class: "step-num") + label
        end
      end)
    end
  end

  # Small status badge next to a field label:
  #   * "Extracted from CV" for values prefilled by the parser (please check)
  #   * "Missing" for required fields that are still empty
  def profile_field_badge(profile, attribute, required: false)
    if profile.extracted?(attribute)
      content_tag :span, "Extracted from CV", class: "badge badge--extracted",
        title: "Prefilled from your CV — please check it"
    elsif required && profile.respond_to?(attribute) && profile.public_send(attribute).blank?
      content_tag :span, "Missing", class: "badge badge--missing"
    end
  end

  def option_label(collection, value)
    return if value.blank?

    Onboarding::Options.label(collection, value)
  end

  # [label, value] pairs for a select/checkbox group.
  def option_choices(collection)
    Onboarding::Options.select(collection)
  end

  # Renders a checkbox group backed by a JSON-array attribute on the profile.
  # A leading blank hidden field lets the candidate clear every option.
  # `input_data` is merged onto each checkbox (used to wire Stimulus targets).
  def multiselect_checkboxes(profile, attribute, collection, input_data: {})
    selected = Array(profile.public_send(attribute)).map(&:to_s)
    field_name = "candidate_profile[#{attribute}][]"

    content_tag :div, class: "check-grid" do
      boxes = option_choices(collection).map do |label, value|
        content_tag :label, class: "check" do
          check_box_tag(field_name, value, selected.include?(value),
            id: "#{attribute}_#{value}", data: input_data) + label
        end
      end
      safe_join([ hidden_field_tag(field_name, "", id: nil) ] + boxes)
    end
  end
end
